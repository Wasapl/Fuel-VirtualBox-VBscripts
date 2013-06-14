' This script creates slaves node for the product, launches its installation,
' and waits for its completion

' Include the handy functions to operate VMs
Sub Import(strFile)
	Set objFs = CreateObject("Scripting.FileSystemObject")
	Set objFile = objFs.OpenTextFile(strFile)
	strCode = objFile.ReadAll
	objFile.Close
	ExecuteGlobal strCode
End Sub
Import ".\functions\vm.vbs"
Import "config.vbs"

' Create and start slave nodes
for idx = 1 to cluster_size-1
	name=vm_name_prefix + "slave-" & idx
	if is_vm_present(name) then
		delete_vm name
	end if
	vm_ram = vm_slave_memory_default
	on error resume next
		vm_ram = vm_slave_memory_mb(idx)
	On Error GoTo 0

	create_vm name, host_nic_name(0), vm_slave_cpu_cores, vm_ram, vm_slave_disk_mb

    ' Add additional NICs to VM
    
    add_nic_to_vm name, 2, host_nic_name(1)
    add_nic_to_vm name, 3, host_nic_name(2)

    ' Add additional disks to VM
    add_disk_to_vm name, 1, vm_slave_second_disk_mb
    add_disk_to_vm name, 2, vm_slave_third_disk_mb

	enable_network_boot_for_vm name 
	start_vm name
next




' Report success
wscript.echo "Slave nodes have been created. They will boot over PXE and get discovered by the master node."
wscript.echo "To access master node, please point your browser to:"
wscript.echo "	http://" + vm_master_ip + ":8000/"
