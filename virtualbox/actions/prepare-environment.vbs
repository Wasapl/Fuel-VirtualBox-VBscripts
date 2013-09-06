'    Copyright 2013 Mirantis, Inc.
'
'    Licensed under the Apache License, Version 2.0 (the "License"); you may
'    not use this file except in compliance with the License. You may obtain
'    a copy of the License at
'
'         http://www.apache.org/licenses/LICENSE-2.0
'
'    Unless required by applicable law or agreed to in writing, software
'    distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
'    WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
'    License for the specific language governing permissions and limitations
'    under the License.

' This script performs initial check and configuration of the host system. It:
'   - verifies that all available command-line tools are present on the host system


' Check for VirtualBox
wscript.echo "Checking for 'VBoxManage'... "
VBoxManagePath = ""
Set lstVBPaths = CreateObject( "System.Collections.ArrayList" )
lstVBPaths.Add """C:\Program Files (x86)\Oracle\VirtualBox\VBoxManage.exe"""
lstVBPaths.Add """C:\Program Files (x86)\VirtualBox\VBoxManage.exe"""
lstVBPaths.Add """C:\Program Files\VirtualBox\VBoxManage.exe"""
lstVBPaths.Add """C:\Program Files\Oracle\VirtualBox\VBoxManage.exe"""
lstVBPaths.Add "VBoxManage.exe"

' reading Vbox install dir from Windows registry
Const HKEY_LOCAL_MACHINE  = &H80000002
' Connect to registry provider on target machine with current user
Set oReg = GetObject("winmgmts:{impersonationLevel=impersonate}!\\.\root\default:StdRegProv")
oReg.GetStringValue HKEY_LOCAL_MACHINE, "SOFTWARE\Oracle\VirtualBox", "InstallDir", strInstallDir
Set oReg = Nothing
lstVBPaths.Add """" + strInstallDir + "VBoxManage.exe"""

for each vbPath in lstVBPaths
	if objFSO.fileExists (strip_quotes(vbPath)) then
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
if not objFSO.fileExists (iso_path) then
	wscript.echo "Fuel Web image is not found. Please download it and put under 'iso' directory."
	Wscript.Quit
end if
wscript.echo "OK"

