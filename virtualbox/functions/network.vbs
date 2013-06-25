Option Explicit
' This file contains the functions to manage host-only interfaces in the system

function get_hostonly_interfaces() 
	get_hostonly_interfaces = get_vbox_value ("list hostonlyifs", "Name")
	'echo -e `VBoxManage list hostonlyifs | grep '^Name' | sed 's/^Name\:[ \t]*//' | uniq` 
end function

function is_hostonly_interface_present(name) 
	dim list
	list = get_hostonly_interfaces()
	
	' Check that the list of interfaces contains the given interface
	is_hostonly_interface_present = instr(list, name) > 0 
end function

function create_hostonly_interface(byref name, ip, mask) 
	wscript.echo "Creating host-only interface (name ip netmask): " & name  & " " & ip & " " & mask
	' Exit if the interface already exists (deleting it here is not safe, as VirtualBox creates hostonly adapters sequentially)
	if is_hostonly_interface_present (name) then
		wscript.echo "Fatal error. Interface " + name + " cannot be created because it already exists."
		exit Function
	end if

	dim ret, rxp, m
	Set rxp = New RegExp : rxp.Global = True : rxp.Multiline = True
	rxp.Pattern = "Interface '([^']+)' was successfully created"

	' Create the interface
	ret = call_VBoxManage ("hostonlyif create")
	set m = rxp.Execute(ret(1)) 
	if m.count > 0 then
		name = m(0).SubMatches(0)
	end if

	' If it does not exist after creation, let's abort
	if not is_hostonly_interface_present (name) then
		wscript.echo "Fatal error. Interface " + name + " does not exist after creation."
		exit Function
	end if

	' Disable DHCP
	wscript.echo "Disabling DHCP server on interface: " + name + "..."
	'VBoxManage dhcpserver remove --ifname $name 2>/dev/null
	call_VBoxManage "dhcpserver remove --ifname """ + name  + """"

	' Set up IP address and network mask
	wscript.echo "Configuring IP address " + ip + " and network mask " + mask + " on interface: " + name + "..."
	call_VBoxManage "hostonlyif ipconfig """ + name + """ --ip " + ip + " --netmask " + mask
end function

Function delete_hostonly_interface(name)
		wscript.echo "Deleting host-only interface: " + name + "..."
		call_VBoxManage "hostonlyif remove """ + host_nic_name(idx) + """"
end Function

function delete_all_hostonly_interfaces() 
	dim list, interface
	list=split(get_hostonly_interfaces(), vbcrlf)

	' Delete every single hostonly interface in the system
	for each interface in list 
		delete_hostonly_interface(interface)
	next
end function


