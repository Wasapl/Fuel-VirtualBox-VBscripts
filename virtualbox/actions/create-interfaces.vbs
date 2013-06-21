

' Create the required host-only interface
for idx = 0 to 2
	create_hostonly_interface host_nic_name(idx), host_nic_ip(idx), host_nic_mask(idx)
	wscript.echo "'" & host_nic_name(idx) & "' created"
	wscript.echo "config.vbs, host_nic_name\(" & idx & "\)\s*=\s*.+$ , host_nic_name(" & idx & ")=""" & host_nic_name(idx) & """"
	Find_And_Replace "config.vbs", "host_nic_name\(" & idx & "\)\s*=\s*.+$", "host_nic_name(" & idx & ")=""" & host_nic_name(idx) & """"
next
