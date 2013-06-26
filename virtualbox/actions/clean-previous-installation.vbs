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
	if is_hostonly_interface_present(host_nic_name(idx)) then
		delete_hostonly_interface(host_nic_name(idx))
	end if
next

' check for interfaces with IP addresses as in config.vbs
hostonly_interfaces_ips = get_vbox_value ("list hostonlyifs", "IPAddress")
for idx = 0 to 2
	if instr(hostonly_interfaces_ips,host_nic_ip(idx))>0 then
		wscript.echo "Fatal error. There is already host-only interface with IP address " + host_nic_ip(idx) 
		wscript.echo "Remove that interface or change value host_nic_ip(" & idx & ") in config.vbs."
		wscript.quit
	end If 
next

wscript.echo call_VBoxManage("list hostonlyifs")(1)