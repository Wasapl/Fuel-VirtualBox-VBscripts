' This script performs initial check and configuration of the host system. It:
'   - verifies that all available command-line tools are present on the host system
'   - check that there is no previous installation of Fuel Web (if there is one, the script deletes it)
'   - creates host-only network interfaces
'
' We are avoiding using 'which' because of http://stackoverflow.com/questions/592620/check-if-a-program-exists-from-a-bash-script 

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


' Check for expect
' wscript.echo -n "Checking for 'expect'... "
' expect -v >/dev/null 2>&1 || { wscript.echo >&2 "'expect' is not available in the path, but it's required. Aborting."; exit 1; }
' wscript.echo "OK"

' Check for VirtualBox
' TODO it can be in several places : 
' in registry 
wscript.echo "Checking for 'VBoxManage'... "
VBoxManagePath = ""
Set lstVBPaths = CreateObject( "System.Collections.ArrayList" )
lstVBPaths.Add """C:\Program Files (x86)\Oracle\VirtualBox\VBoxManage.exe"""
lstVBPaths.Add """C:\Program Files (x86)\VirtualBox\VBoxManage.exe"""
lstVBPaths.Add """C:\Program Files\VirtualBox\VBoxManage.exe"""
lstVBPaths.Add """C:\Program Files\Oracle\VirtualBox\VBoxManage.exe"""
lstVBPaths.Add "VBoxManage.exe"

' reading Vbox install dir form registry
Const HKEY_LOCAL_MACHINE  = &H80000002
' Connect to registry provider on target machine with current user
Set oReg = GetObject("winmgmts:{impersonationLevel=impersonate}!\\.\root\default:StdRegProv")
oReg.GetStringValue HKEY_LOCAL_MACHINE, "SOFTWARE\Oracle\VirtualBox", "InstallDir", strInstallDir
Set oReg = Nothing
lstVBPaths.Add """" + strInstallDir + "VBoxManage.exe"""

for each vbPath in lstVBPaths
	wscript.echo "checking " + vbPath
	if fso.fileExists (strip_quotes(vbPath)) then
		wscript.echo "Found VBoxManage.exe at " + vbPath + "...."
		VBoxManagePath = vbPath
	end if
next
if VBoxManagePath = "" then 
	wscript.echo "'VBoxManage' is not available in the path, but it's required. Likely, VirtualBox is not installed. Aborting."
	Wscript.Quit
else
	wscript.echo "Ok"
end If 

' Check for ISO image to be available
wscript.echo "Checking for Fuel Web ISO image... "
if not fso.fileExists (iso_path) then
	wscript.echo "Fuel Web image is not found. Please download it and put under 'iso' directory."
	Wscript.Quit
end if
wscript.echo "OK"

' Delete all VMs from the previous Fuel Web installation
delete_vms_multiple vm_name_prefix

' Delete all host-only interfaces
'delete_all_hostonly_interfaces

' Create the required host-only interface
create_hostonly_interface hostonly_interface_name, hostonly_interface_ip, hostonly_interface_mask
wscript.echo "'" + hostonly_interface_name + "' created"
wscript.echo "config.vbs, hostonly_interface_name=.+$, hostonly_interface_name=""" + hostonly_interface_name + """"
Find_And_Replace "config.vbs", "hostonly_interface_name=.+$", "hostonly_interface_name=""" + hostonly_interface_name + """"

' Report success
wscript.echo "Setup is done."
