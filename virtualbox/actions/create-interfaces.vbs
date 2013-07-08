' This script creates host-only interfaces for Fuel Web
' it does nothing if interface exists already


for idx = 0 to 2
	if not surely_create_hostonly_interface(host_nic_name(idx), host_nic_ip(idx), host_nic_mask(idx)) then
		wscript.echo "Creation of " & host_nic_name(idx) & " failed several times. "
		wscript.echo "This may be due to " & host_nic_ip(idx) & " assigned to other interface or its incorrect IP."
		wscript.echo "Please check interfaces and edit config.vbs."
		wscript.Quit
	end if
	' create_hostonly_interface host_nic_name(idx), host_nic_ip(idx), host_nic_mask(idx)
	wscript.echo "'" & host_nic_name(idx) & "' created"
	'wscript.echo "config.vbs, host_nic_name\(" & idx & "\)\s*=\s*.+$ , host_nic_name(" & idx & ")=""" & host_nic_name(idx) & """"
	Find_And_Replace "config.vbs", "host_nic_name\(" & idx & "\)\s*=\s*.+$", "host_nic_name(" & idx & ")=""" & host_nic_name(idx) & """"
next

' Sometimes VBoxManage can't properly configure IP at hostonlyif. 
' Have to log all interfaces to provide user propper information.
wscript.echo call_VBoxManage("list hostonlyifs")(1)