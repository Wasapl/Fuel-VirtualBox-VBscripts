Option Explicit
'    Copyright 2013 Mirantis, Inc.
'
'    Licensed under the Apache License, Version 2.0 (the "License"); you may
'    not use this file except in compliance with the License. You may obtain
'    a copy of the License at
'
'         http://www.apache.org/licenses/LICENSE-2.0
'
'    Unless required by applicable law or agreed to in writing, software
'    distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
'    WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
'    License for the specific language governing permissions and limitations
'    under the License.

' This file contains the functions for connecting to Fuel VM, checking if the installation process completed
' and Fuel became operational, and also enabling outbound network/internet access for this VM through the
' host system


Dim objShell
Set objShell = WScript.CreateObject( "WScript.Shell" )


function is_product_vm_operational(ip, username, password)
' Log in into the VM, see if Puppet has completed its run
' Returns: boolean
	dim objExec
	dim arr(2), cmd
	arr(1) = ""
	arr(2) = ""
	is_product_vm_operational = False
	' we cannot use -batch parameter since plink do not establish connection if server's fingerprint does not match stored ones.
	cmd =  "plink.exe " + username + "@" + ip + " -pw " + password + " ""grep -o 'Finished catalog run' /var/log/puppet/bootstrap_admin_node.log"""
	Set objExec = objShell.Exec(cmd)

	' reading stdout and stderr till plink terminate
	dim strFromProc
	Do While objExec.Status = 0
		' We have trouble here becouse ReadLine() and ReadAll() waits for CR LF as ending of last line of plink error massage.
		' That is why we write N or Y in stdin right after first line of message came.
		Do While Not ObjExec.Stderr.atEndOfStream
			strFromProc = ObjExec.Stderr.ReadLine()
			arr(2) = arr(2) & strFromProc
			if instr(strFromProc,"The server's host key is not cached") > 0 then
				objExec.StdIn.Write "n" + VbCrLf
			end if
			if instr(strFromProc,"WARNING - POTENTIAL SECURITY BREACH") > 0 then
				objExec.StdIn.Write "y" + VbCrLf
			end if
		Loop
		' Here we have another trouble due to plink do not open stdout until its needed. And if stdout is not open atEndOfStream() hangs itself.
		' That is why we check stderr first.
		Do While Not ObjExec.Stdout.atEndOfStream
			strFromProc = ObjExec.Stdout.ReadLine()
			arr(1) = arr(1) & strFromProc
		Loop
		WScript.Sleep 100
	Loop
	arr(0) = objExec.ExitCode

	if arr(0) = 0 then
		if instr(arr(1),"Finished catalog run") then
			is_product_vm_operational = True
		else
			wscript.echo "Not finished catalog run"
			wscript.echo "stdout:" + vbCrLf + arr(1)
		end if
	else 
		WScript.Echo "Error occured in command: ExitCode=" & arr(0) & vbCrLf & cmd
		WScript.Echo "stderr:" + vbCrLf + arr(2)
		WScript.Echo "stdout:" + vbCrLf + arr(1)
	end if
end Function 
'wscript.echo is_product_vm_operational ("10.20.0.2", "root", "r00tme")


function wait_for_product_vm_to_install(ip, username, password)
' In a loop check if Puppet has completed its run
' Returns: nothing
	wscript.echo "Waiting for product VM to install. Please do NOT abort the script..."

	' Loop until master node gets successfully installed
	do until is_product_vm_operational (ip, username, password)
		WScript.sleep 5 * 1000
	loop
end Function
'wait_for_product_vm_to_install "10.20.0.2", "root", "r00tme"


function enable_outbound_network_for_product_vm(ip, username, password, interface_id, gateway_ip)
	' Subtract one to get ethX index (0-based) from the VirtualBox inde1x (from 1 to 4)
	interface_id = interface_id - 1

	dim cmd, objExec, ret, strLine, nameserver, DnsServer, objRXP

	' Check for internet access on the host system
	wscript.echo "Checking for internet connectivity on the host system... "
	dim websites(1), website
	websites(0) = "google.com"
	websites(1) = "wikipedia.com"
	for each website in websites
		cmd = "ping -n 5 " + website
		set objExec = objShell.Exec(cmd)
		Do While objExec.Status = 0
			' strLine = objExec.StdOut.ReadLine()
			' wscript.echo strLine
			WScript.Sleep 10
		Loop
		ret = objExec.ExitCode
		if ret = 0 then
			exit for
		end if
	next

	if ret = 0 then
		wscript.echo "OK"
	else
		wscript.echo "FAIL"
		print_no_internet_connectivity_banner
		enable_outbound_network_for_product_vm = false
		exit function
	end if

	' Check host nameserver configuration
	wscript.echo "Checking local DNS configuration... "
	cmd = "netsh interface ip show dns"
	Set objRXP = New RegExp : objRXP.Global = True : objRXP.Multiline = False
	objRXP.Pattern = "[0-9\.]+"
	set objExec = objShell.Exec(cmd)
	nameserver = ""
	Do While objExec.Status = 0
		Do While Not objExec.StdOut.atEndOfStream
			strLine = objExec.StdOut.ReadLine()
			if instr(strLine,"DNS") > 0 then
				DnsServer = trim(right(strLine,len(strLine)-instr(strLine,":")))
				if objRXP.Execute(DnsServer).count > 0 then
					nameserver = nameserver + "nameserver " + DnsServer + vbCrLf
				end if
			end if
		Loop
		WScript.Sleep 10
	Loop
	wscript.echo nameserver

	' Enable internet access on inside the VMs
	wscript.echo "Enabling outbound network/internet access for the product VM... "

	cmd = "file=/etc/sysconfig/network-scripts/ifcfg-eth" & interface_id & ";" & _
	"hwaddr=$(grep HWADDR $file);" & _
	"uuid=$(grep UUID $file); " & _
	"echo -e \""$hwaddr\n$uuid\nDEVICE=eth" & interface_id & "\nTYPE=Ethernet\nONBOOT=yes\nNM_CONTROLLED=no\nBOOTPROTO=dhcp\nPEERDNS=no\"" > $file;" & _
	"sed \""s/GATEWAY=.*/GATEWAY=" & gateway_ip & "/g\"" -i /etc/sysconfig/network;" & _
	"echo -e \""" + nameserver + "\"" >/etc/dnsmasq.upstream;" & _
	"service network restart >/dev/null 2>&1;" & _
	"service dnsmasq restart >/dev/null 2>&1;" & _
	"for i in 1 2 3 4 5; do ping -c 2 google.com || ping -c 2 wikipedia.com || sleep 2; done"

	' we cannot use -batch parameter since plink do not establish connection if server's fingerprint does not match stored ones.
	cmd =  "plink.exe " + username + "@" + ip + " -pw " + password + " """ + cmd + """"
	Set objExec = objShell.Exec(cmd)

	' reading stdout and stderr till plink terminate
	dim isOk
	isOk = false
	Do While objExec.Status = 0
		Do While Not objExec.StdOut.atEndOfStream
			strLine = objExec.StdOut.ReadLine()
			if instr(strLine,"icmp_seq=") > 0 then
				isOk = true
			end if
		Loop
		WScript.Sleep 10
	Loop

	if isOk then
		wscript.echo "OK"
		enable_outbound_network_for_product_vm = true
	else
		wscript.echo "FAIL"
		print_no_internet_connectivity_banner
		enable_outbound_network_for_product_vm = false
	end if
end function
' enable_outbound_network_for_product_vm "10.20.0.2", "root", "r00tme", 3, "192.168.200.2"


function print_no_internet_connectivity_banner()

	wscript.echo "############################################################"
	wscript.echo "# WARNING: some of the Fuel features will not be supported #"
	wscript.echo "#          (e.g. RHOS/RHEL integration) because there is   #"
	wscript.echo "#          no Internet connectivity                        #"
	wscript.echo "############################################################"

end Function

