Option Explicit
'This file contains the functions to manage VMs through VirtualBox CLI


Dim objFSO, objShell, VBoxManagePath
dim ret
Set objFSO = CreateObject("Scripting.FileSystemObject")
Set objShell = WScript.CreateObject("WScript.Shell")
' use this VBoxManagePath initialization for debuging vm.vbs only
' VBoxManagePath = """C:\Program Files\Oracle\VirtualBox\VBoxManage.exe"""


function get_vbox_value (command, parameter)
' Parse output of given command and returns value of given parameter. If there is several values its separated by CR LF.
' Inputs: command - VBoxManage.exe command
'		parameter - name of parameter exactly from start of line to colon.
' Returns: string separated by CR LF.
	Dim objExec, objMatches, objRXP, strLine, strValue

	Set objRXP = New RegExp : objRXP.Global = True : objRXP.Multiline = False
	objRXP.Pattern = "^" + parameter + ":?\s*(.+)$"

	Set objExec = objShell.Exec(VBoxManagePath + " " + command)

	Do
		strLine = objExec.StdOut.ReadLine()
		set objMatches = objRXP.Execute(strLine) 
		if objMatches.count > 0 then
			if isempty(strValue) then
				strValue = objMatches(0).SubMatches(objMatches(0).SubMatches.count-1)
			else
				strValue = strValue + vbCrLf + objMatches(0).SubMatches(objMatches(0).SubMatches.count-1)
			end if
		end if
	Loop While Not objExec.Stdout.atEndOfStream

	get_vbox_value = strValue
	Set objExec = Nothing
end Function 
' WScript.Echo "Value is " + get_vbox_value ("list systemproperties", "Default machine folder")
' WScript.Echo "Value is " + get_vbox_value ("list hostonlyifs", "Name")


function get_vm_base_path ()
' Returns name of folder there VMs are stored. 
' Example: "D:\VirtualBox VMs" (without qoutes)
	get_vm_base_path = get_vbox_value ("list systemproperties", "Default machine folder")
end Function


function get_vms_list (command)
' Reads list of VMs
' Inputs: command should be one of strings: "list vms", "list runningvms"
' Returns: an array of pairs (VM_name, VM_UUID)
	Dim objExec, strLine, lstProgID, objMatches , match, objRXP

	' get_vms_list = Nothing

	Set objRXP = New RegExp : objRXP.Global = True : objRXP.MultiLine = True
	objRXP.Pattern = """([^""]+)""\s+({[^}]+})"
	Set lstProgID = CreateObject( "System.Collections.ArrayList" )
	
	Set objExec = objShell.Exec(VBoxManagePath + " " + command)

	strLine = ""
	Do
		strLine = strLine + vbCrLf + objExec.StdOut.Readline()
	Loop While Not objExec.Stdout.atEndOfStream
	set objMatches = objRXP.Execute(strLine) 
	if objMatches.count > 0 then
		for each match in objMatches
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
' Returns list of existing VMs
' Returns: an array of pairs (VM_name, VM_UUID)
	get_vms_present = get_vms_list ("list vms")
end Function


Function get_vms_running()
' Returns list of running VMs
' Returns: an array of pairs (VM_name, VM_UUID)
	get_vms_running = get_vms_list ("list runningvms")
end Function


function is_vm_present(name)
' Returns: boolean True if VM exists, False if VM not exists
	dim arrVMs , isPresent , vm
	
	isPresent = False

	arrVMs = get_vms_present()
	if not isEmpty(arrVMs) then
		for each vm in arrVMs
			if name = vm(0) then 
				isPresent = true
			end if
		next 
	end if

	is_vm_present = isPresent
end Function


function is_vm_running(name)
' Returns: boolean True if VM is running, False if VM is not running
	dim arrVMs , isRunning , vm
	
	isRunning = False

	arrVMs = get_vms_running()
	if not isEmpty(arrVMs) then
		for each vm in arrVMs
			if name = vm(0) then 
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
' executes VBoxManage.exe with given command.
' Returns: array, where arr(0) is VBoxManage ExitCode
' 			arr(1) - VBoxManage StdOut
' 			arr(2) - VBoxManage StdErr
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
' creates VM with given parameters
' Inputs: name - string
'			nic - string, name of network interface to connect to VM
'			cpu_cores - integer number of cores for VM
'			memory_mb - integer amount of memory in MB
'			disk_mb - integer disk size in MB
' Returns: nothing
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
' add host-only network interface to VM with given name.
' Inputs: name - VM name 
' 		id - NIC number in VM. Possible values from 1 to 4
'		nic - host-only network name
' Returns: nothing
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
' Creates disk with size disk_mb and attaches it to VM
' Inputs: vm_name - VM name
'		port - VM's SATA port number to connect disk to
'		disk_mb - disk size in MB
' Returns: nothing
	dim vm_base_path, vm_disk_path, disk_name, disk_filename
	vm_base_path = get_vm_base_path()
	vm_disk_path = objFSO.BuildPath(vm_base_path, vm_name) 
	disk_name = vm_name & "_" & port
	disk_filename = disk_name & ".vdi"
	
	wscript.echo "Adding disk to """ + vm_name + """, with size " & disk_mb & " Mb..."
	dim cmd
	'VBoxManage createhd --filename "$vm_disk_path/$disk_name" --size $disk_mb --format VDI
	cmd = " createhd --filename """ + objFSO.BuildPath(vm_disk_path,disk_name) + """ --size " & disk_mb & " --format VDI"
	WScript.echo cmd
	call_VBoxManage cmd
	'VBoxManage storageattach $vm_name --storagectl 'SATA' --port $port --device 0 --type hdd --medium "$vm_disk_path/$disk_filename"
	cmd = " storageattach """ + vm_name + """ --storagectl ""SATA"" --port " & port & " --device 0 --type hdd --medium """ + objFSO.BuildPath(vm_disk_path,disk_filename) + """ "
	WScript.echo cmd
	call_VBoxManage cmd
end function


Function delete_vm (name)
' Powers off and deletes VM
' Returns: nothing
	dim vm_base_path, vm_path
	vm_base_path = get_vm_base_path()
	vm_path = objFSO.BuildPath(vm_base_path, name) 

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
	if objFSO.FolderExists(vm_path) then
		on error resume next
		objFSO.DeleteFolder vm_path, True
		On Error GoTo 0
	end if
End Function


Function delete_vms_multiple(name_prefix)
' powers of and deletes all VM with given name prefix
' Returns: nothing
	dim arrVMs, intPrefixLen, arrVM
	arrVMs = get_vms_present()
	if not isEmpty(arrVMs) then
		intPrefixLen=len(name_prefix)
		
		' Loop over the array arrVMs and delete them, if its name matches the given refix 
		for each arrVM in arrVMs 
			dim strLeft
			strLeft = left(arrVM(0), intPrefixLen)
			if strLeft = name_prefix then
				wscript.echo "Found existing VM: " + arrVM(0) + ". Deleting it..."
				delete_vm arrVM(0)
			end if
		next
	end if
End Function
'delete_vms_multiple "foo"


Function start_vm (name)
' Just start VM
' Returns: nothing
	'call_VBoxManage "startvm """ + name + """ --type headless"
	call_VBoxManage "startvm """ + name + """"
End Function


Function mount_iso_to_vm(name, iso_path)
' Mount ISO to the VM
' Returns: nothing
	call_VBoxManage "storageattach """ + name + """ --storagectl ""IDE"" --port 0 --device 0 --type dvddrive --medium """ + iso_path + """"
End Function
' mount_iso_to_vm "foo", "D:\distr\iso\Ubuntu-x86_64-mini.iso"


Function enable_network_boot_for_vm(name)
' Set the right boot priority
' Returns: nothing
	call_VBoxManage "modifyvm """ + name + """ --boot1 disk --boot2 net --boot3 none --boot4 none --nicbootprio1 1"
End Function
' enable_network_boot_for_vm "foo"
' start_vm "foo"
' delete_vms_multiple "foo"
