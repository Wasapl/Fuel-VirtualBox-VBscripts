' This script check that there is no previous installation of Fuel Web (if there is one, the script deletes it)

' Include the script with handy functions to operate VMs and VirtualBox networking
Sub Import(strFile)
	Set objFs = CreateObject("Scripting.FileSystemObject")
	Set objFile = objFs.OpenTextFile(strFile)
	strCode = objFile.ReadAll
	objFile.Close
	ExecuteGlobal strCode
End Sub
Import ".\functions\vm.vbs"
Import ".\functions\network.vbs"
Import ".\functions\utils.vbs"
Import "config.vbs"

' Delete all VMs from the previous Fuel Web installation
delete_vms_multiple vm_name_prefix

' Delete all host-only interfaces
'delete_all_hostonly_interfaces

for idx = 0 to 2
	wscript.echo "Deleting host-only interface: " + host_nic_name(idx) + "..."
	call_VBoxManage "hostonlyif remove " + host_nic_name(idx)
next

' TODO instead delete_all_hostonly_interfaces: 
' 1.seek for interfaces with host_nic_ip(0), host_nic_ip(1), host_nic_ip(2)
' 2. exit with error if found any
