Option Explicit
' This file contains the functions to connect to the product VM and see if it became operational


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
	cmd =  "plink.exe -batch " + username + "@" + ip + " -pw " + password + " ""grep -o 'Finished catalog run' /var/log/puppet/bootstrap_admin_node.log"""
	' wscript.echo cmd
	Set objExec = objShell.Exec(cmd)

	' in case if plink ask for store key fingerprint
	objExec.StdIn.Write "n" + VbCrLf
	' reading stdout and stderr till plink terminate
	Do While objExec.Status = 0
		If Not objExec.StdOut.AtEndOfStream Then
			arr(1) = arr(1) & objExec.StdOut.ReadAll
		End If

		If Not objExec.StdErr.AtEndOfStream Then
			arr(2) = arr(2) & objExec.StdErr.ReadAll
		End If
		WScript.Sleep 100
	Loop
	arr(0) = objExec.ExitCode

	if arr(0) = 0 then
		if instr(arr(1),"Finished catalog run") then
			is_product_vm_operational = True
			' wscript.echo "ok"
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
' is_product_vm_operational "10.20.0.2", "root", "r00tme"


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