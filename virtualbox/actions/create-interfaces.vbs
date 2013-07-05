' This script creates host-only interfaces for Fuel Web
' it does nothing if interface exists already


for idx = 0 to 2
	create_hostonly_interface host_nic_name(idx), host_nic_ip(idx), host_nic_mask(idx)
	wscript.echo "'" & host_nic_name(idx) & "' created"
	'wscript.echo "config.vbs, host_nic_name\(" & idx & "\)\s*=\s*.+$ , host_nic_name(" & idx & ")=""" & host_nic_name(idx) & """"
	Find_And_Replace "config.vbs", "host_nic_name\(" & idx & "\)\s*=\s*.+$", "host_nic_name(" & idx & ")=""" & host_nic_name(idx) & """"
next

' Sometimes VBoxManage can't properly configure IP at hostonlyif. 
' Have to log all interfaces to provide user propper information.
wscript.echo call_VBoxManage("list hostonlyifs")(1)