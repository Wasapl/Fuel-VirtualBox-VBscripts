' This file contains the functions to connect to the product VM and see if it became operational
Dim objShell
Set objShell = WScript.CreateObject( "WScript.Shell" )

function is_product_vm_operational(ip, username, password)
	' Log in into the VM, see if Puppet has completed its run
	' Looks a bit ugly, but 'end of expect' has to be in the very beginning of the line 
	dim oExec
	dim arr(2), cmd
	arr(1) = ""
	arr(2) = ""
	is_product_vm_operational = False
	cmd =  "plink.exe -batch " + username + "@" + ip + " -pw " + password + " ""grep -o 'Finished catalog run' /var/log/puppet/bootstrap_admin_node.log"""
	' wscript.echo cmd
	Set oExec = objShell.Exec(cmd)

	' in case if plink ask for store key fingerprint
	oExec.StdIn.Write "n" + VbCrLf
	' reading stdout and stderr till plink terminate
	Do While oExec.Status = 0
		If Not oExec.StdOut.AtEndOfStream Then
			arr(1) = arr(1) & oExec.StdOut.ReadAll
		End If

		If Not oExec.StdErr.AtEndOfStream Then
			arr(2) = arr(2) & oExec.StdErr.ReadAll
		End If
		WScript.Sleep 100
	Loop
	arr(0) = oExec.ExitCode

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
	wscript.echo "Waiting for product VM to install. Please do NOT abort the script..."

	' Loop until master node gets successfully installed
	do until is_product_vm_operational (ip, username, password)
		WScript.sleep 5
	loop
end Function
'wait_for_product_vm_to_install "10.20.0.2", "root", "r00tme"