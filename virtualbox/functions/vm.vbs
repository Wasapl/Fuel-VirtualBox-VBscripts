Option Explicit

'This file contains the functions to manage VMs in through VirtualBox CLI

Dim fso, objShell, VBoxManagePath
dim ret
Set fso = CreateObject("Scripting.FileSystemObject")
Set objShell = WScript.CreateObject("WScript.Shell")
' use this VBoxManagePath initialization for debuging vm.vbs only
' VBoxManagePath = """C:\Program Files\Oracle\VirtualBox\VBoxManage.exe"""


function get_vbox_value (command, parameter)
	Dim objExec, m, rxp, line, value

	Set rxp = New RegExp : rxp.Global = True : rxp.Multiline = False
	rxp.Pattern = "^" + parameter + ":?\s*(.+)$"

	Set objExec = objShell.Exec(VBoxManagePath + " " + command)

	Do
		line = objExec.StdOut.ReadLine()
		set m = rxp.Execute(line) 
		if m.count > 0 then
			if isempty(value) then
				value = m(0).SubMatches(0)
			else
				value = value + vbCrLf + m(0).SubMatches(0)
			end if
		end if
	Loop While Not objExec.Stdout.atEndOfStream

	get_vbox_value = value
	Set objExec = Nothing
end Function 
' WScript.Echo "Value is " + get_vbox_value ("list systemproperties", "Default machine folder")
' WScript.Echo "Value is " + get_vbox_value ("list hostonlyifs", "Name")

function get_vm_base_path ()
	get_vm_base_path = get_vbox_value ("list systemproperties", "Default machine folder")
end Function


function get_vms_list (command)
	Dim objExec, x,  line, lstProgID, m , match, rxp

	' get_vms_list = Nothing

	Set rxp = New RegExp : rxp.Global = True : rxp.Multiline = True
	rxp.Pattern = """([^""]+)""\s+({[^}]+})"
	Set lstProgID = CreateObject( "System.Collections.ArrayList" )
	
	Set objExec = objShell.Exec(VBoxManagePath + " " + command)

	line = ""
	Do
		line = line + vbCrLf + objExec.StdOut.ReadLine()
	Loop While Not objExec.Stdout.atEndOfStream
	set m = rxp.Execute(line) 
	if m.count > 0 then
		for each match in m
	 		lstProgID.Add match.SubMatches
		next
		get_vms_list = lstProgID.ToArray
	end if
	
	Set objExec = Nothing
end Function 
' dim list, str, l
' list = get_vms_list ("list vms")
' str=""
' if isEmpty(list) then
' 	WScript.Echo "No vms"
' else
' 	for each l in list
' 		str= str + l(0) + "___" + l(1) + vbCrLf
' 	next 
' 	WScript.Echo "vms: " + str
' end if

function get_vms_present()
	get_vms_present = get_vms_list ("list vms")
end Function

Function get_vms_running()
	get_vms_running = get_vms_list ("list runningvms")
end Function

function is_vm_present(name) 
	dim list , isPresent , l
	
	isPresent = False

	list = get_vms_present()
	if not isEmpty(list) then
		for each l in list
			if name = l(0) then 
				isPresent = true
			end if
		next 
	end if

	is_vm_present = isPresent
end Function

function is_vm_running(name) 
	dim list , isRunning , l
	
	isRunning = False

	list = get_vms_running()
	if not isEmpty(list) then
		for each l in list
			if name = l(0) then 
				isRunning = true
			end if
		next 
	end if

	is_vm_running = isRunning
end Function
' if is_vm_running("fuel2-pm")= True then
' 	WScript.Echo "is_vm_running(fuel2-pm)= True"
' end if

Function call_VBoxManage (command)
	dim oExec
	dim arr(2)
	Set oExec = objShell.Exec(VBoxManagePath + " " + command)
	arr(1) = ""
	arr(2) = ""

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

	if oExec.ExitCode <> 0 then
		WScript.Echo "Error occured in command:" + vbCrLf + "VBoxManage " + command
		WScript.Echo "stderr:" + vbCrLf + arr(2)
		WScript.Echo "stdout:" + vbCrLf + arr(1)
	end if
	call_VBoxManage = arr
End Function
' ret = call_VBoxManage ("list systemproperties")
' wscript.echo ret(1)

Function create_vm (name, nic, cpu_cores, memory_mb, disk_mb)
	dim objExec, ret, cmd

	' Create virtual machine with the right name and type (assuming CentOS) 
	'VBoxManage createvm --name $name --ostype RedHat_64 --register
	cmd = " createvm --name """ + name + """ --ostype RedHat_64 --register"
	call_VBoxManage cmd
	' Set the real-time clock (RTC) operate in UTC time
	'VBoxManage modifyvm $name --rtcuseutc on --memory $memory_mb --cpus $cpu_cores
	cmd = " modifyvm """ + name + """ --rtcuseutc on --memory " & memory_mb & " --cpus " & cpu_cores
	call_VBoxManage cmd
	
	' Configure main network interface
	add_nic_to_vm name, 1, nic
	
	' Configure storage controllers
	'VBoxManage storagectl $name --name 'IDE' --add ide
	cmd = " storagectl """ + name + """ --name ""IDE"" --add ide"
	call_VBoxManage cmd
	'VBoxManage storagectl $name --name 'SATA' --add sata
	cmd = " storagectl """ + name + """ --name ""SATA"" --add sata"
	call_VBoxManage cmd
	
	' Create and attach the main hard drive
	add_disk_to_vm name, 0, disk_mb
end Function
' ret = create_vm("foo", "VirtualBox Host-Only Ethernet Adapter #8" ,1 , 512, 8192)

Function add_nic_to_vm(name, id, nic) 
	WScript.echo "Adding NIC to """ + name + """ and bridging with host NIC " + nic + "..."
	dim cmd
	' Configure network interfaces
	'VBoxManage modifyvm $name --nic${id} hostonly --hostonlyadapter${id} $nic --nictype${id} Am79C973 --cableconnected${id} on --macaddress${id} auto
	cmd = " modifyvm """ + name + """ --nic" & id & " hostonly --hostonlyadapter" & id & " """ & nic & """ --nictype" & id & " Am79C973 --cableconnected" & id & " on --macaddress" & id & " auto"
	call_VBoxManage cmd
	'VBoxManage controlvm $name setlinkstate${id} on
	cmd = " controlvm """ + name + """ setlinkstate" & id & " on"
	call_VBoxManage cmd
end Function


function add_disk_to_vm(vm_name, port, disk_mb) 
	dim vm_base_path, vm_disk_path, disk_name, disk_filename
	vm_base_path = get_vm_base_path()
	vm_disk_path = fso.BuildPath(vm_base_path, vm_name) 
	disk_name = vm_name & "_" & port
	disk_filename = disk_name & ".vdi"
	
	wscript.echo "Adding disk to """ + vm_name + """, with size " & disk_mb & " Mb..."
	dim cmd
	'VBoxManage createhd --filename "$vm_disk_path/$disk_name" --size $disk_mb --format VDI
	cmd = " createhd --filename """ + fso.BuildPath(vm_disk_path,disk_name) + """ --size " & disk_mb & " --format VDI"
	WScript.echo cmd
	call_VBoxManage cmd
	'VBoxManage storageattach $vm_name --storagectl 'SATA' --port $port --device 0 --type hdd --medium "$vm_disk_path/$disk_filename"
	cmd = " storageattach """ + vm_name + """ --storagectl ""SATA"" --port " & port & " --device 0 --type hdd --medium """ + fso.BuildPath(vm_disk_path,disk_filename) + """ "
	WScript.echo cmd
	call_VBoxManage cmd
end function

Function delete_vm (name)
	dim vm_base_path, vm_path
	vm_base_path = get_vm_base_path()
	vm_path = fso.BuildPath(vm_base_path, name) 

	dim cmd

	' Power off VM, if it's running
	if is_vm_running(name) then
		cmd = "controlvm " + name + " poweroff"
		call_VBoxManage cmd
	end if

	' Virtualbox does not fully delete VM file structure, so we need to delete the corresponding directory with files as well 

	wscript.echo "Deleting existing virtual machine " + name + "..."
	cmd = "unregistervm " + name + " --delete"
	call_VBoxManage cmd
	if fso.FolderExists(vm_path) then
		on error resume next
		fso.DeleteFolder vm_path, True
		On Error GoTo 0
	end if
End Function

Function delete_vms_multiple(name_prefix)
	dim list, prefix_len, vm
	list = get_vms_present()
	if not isEmpty(list) then
		prefix_len=len(name_prefix)
		
		' Loop over the list of VMs and delete them, if its name matches the given refix 
		for each vm in list 
			dim l
			l = left(vm(0), prefix_len)
			if l = name_prefix then
				wscript.echo "Found existing VM: " + vm(0) + ". Deleting it..."
				delete_vm vm(0)
			end if
		next
	end if
End Function
'delete_vms_multiple "foo"

Function start_vm (name)
	' Just start it
	'call_VBoxManage "startvm """ + name + """ --type headless"
	call_VBoxManage "startvm """ + name + """"
End Function


Function mount_iso_to_vm(name, iso_path)
	' Mount ISO to the VM
	call_VBoxManage "storageattach """ + name + """ --storagectl ""IDE"" --port 0 --device 0 --type dvddrive --medium """ + iso_path + """"
End Function
' mount_iso_to_vm "foo", "D:\distr\iso\Ubuntu-x86_64-mini.iso"

Function enable_network_boot_for_vm(name)
	' Set the right boot priority
	call_VBoxManage "modifyvm """ + name + """ --boot1 disk --boot2 net --boot3 none --boot4 none --nicbootprio1 1"
End Function
' enable_network_boot_for_vm "foo"
' start_vm "foo"
' delete_vms_multiple "foo"
