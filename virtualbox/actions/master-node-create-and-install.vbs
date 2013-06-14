' This script creates a master node for the product, launches its installation,
' and waits for its completion

' Include the handy functions to operate VMs and track ISO installation progress
Sub Import(strFile)
	Set objFs = CreateObject("Scripting.FileSystemObject")
	Set objFile = objFs.OpenTextFile(strFile)
	strCode = objFile.ReadAll
	objFile.Close
	ExecuteGlobal strCode
End Sub
Import ".\functions\vm.vbs"
Import ".\functions\product.vbs"
Import "config.vbs"


' Create master node for the product
dim name
name = vm_name_prefix + "master"
if is_vm_present(name) then
	delete_vm name
end if
create_vm name, host_nic_name(0), vm_master_cpu_cores, vm_master_memory_mb, vm_master_disk_mb
add_nic_to_vm name, 2, host_nic_name(1)
mount_iso_to_vm name, iso_path

' Start virtual machine with the master node
start_vm name

' Wait until the machine gets installed and Puppet completes its run
' TODO there is no expect in bare Windows, so have to figure out something else...
wscript.echo vm_master_ip+ " " + vm_master_username+ " " + vm_master_password
wait_for_product_vm_to_install vm_master_ip, vm_master_username, vm_master_password

' Report success
wscript.echo "Master node has been installed."
