' This script creates host-only interfaces for Fuel Web
' it does nothing if interface exists already
Sub Import(strFile)
	Set objFs = CreateObject("Scripting.FileSystemObject")
	Set objFile = objFs.OpenTextFile(strFile)
	strCode = objFile.ReadAll
	objFile.Close
	ExecuteGlobal strCode
End Sub
Import ".\functions\vm.vbs"
Import ".\functions\network.vbs"
Import "config.vbs"


for idx = 0 to 2
	create_hostonly_interface host_nic_name(idx), host_nic_ip(idx), host_nic_mask(idx)
	wscript.echo "'" & host_nic_name(idx) & "' created"
	'wscript.echo "config.vbs, host_nic_name\(" & idx & "\)\s*=\s*.+$ , host_nic_name(" & idx & ")=""" & host_nic_name(idx) & """"
	Find_And_Replace "config.vbs", "host_nic_name\(" & idx & "\)\s*=\s*.+$", "host_nic_name(" & idx & ")=""" & host_nic_name(idx) & """"
next
