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

' Prepare the host system
Import ".\actions\prepare-environment.vbs"

' Create and launch master node
Import ".\actions\master-node-create-and-install.vbs"

' Create and launch slave nodes
Import ".\actions\slave-nodes-create-and-boot.vbs"

