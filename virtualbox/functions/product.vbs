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
	' we cannot use -batch parameter since plink do not establish connection if server's fingerprint does not match stored ones.
	cmd =  "plink.exe " + username + "@" + ip + " -pw " + password + " ""grep -o 'Finished catalog run' /var/log/puppet/bootstrap_admin_node.log"""
	' wscript.echo cmd
	Set objExec = objShell.Exec(cmd)

	' reading stdout and stderr till plink terminate
	dim strFromProc
	Do While objExec.Status = 0
		' We have trouble here becouse ReadLine() and ReadAll() waits for CR LF as ending of last line of plink error massage.
		' That is why we write N or Y in stdin right after first line of message came.
		Do While Not ObjExec.Stderr.atEndOfStream
			strFromProc = ObjExec.Stderr.ReadLine()
			arr(2) = arr(2) & strFromProc
			WScript.Echo "ERR " & strFromProc 
			if instr(strFromProc,"The server's host key is not cached") > 0 then
				objExec.StdIn.Write "n" + VbCrLf
				wscript.echo "writing N"
			end if
			if instr(strFromProc,"WARNING - POTENTIAL SECURITY BREACH") > 0 then
				objExec.StdIn.Write "y" + VbCrLf
				wscript.echo "writing Y"
			end if
		Loop
		wscript.echo "!ERR fin!"
		' Here we have another trouble due to plink do not open stdout until its needed. And if stdout is not open atEndOfStream() hangs itself.
		' That is why we check stderr first.
		Do While Not ObjExec.Stdout.atEndOfStream
			strFromProc = ObjExec.Stdout.ReadLine()
			arr(1) = arr(1) & strFromProc
			WScript.Echo "OUT " & strFromProc 
		Loop
		wscript.echo "!OUT fin!"
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
wscript.echo is_product_vm_operational ("10.20.0.2", "root", "r00tme")


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