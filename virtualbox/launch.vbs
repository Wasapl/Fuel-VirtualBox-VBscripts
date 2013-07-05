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
Import ".\functions\product.vbs"
Import "config.vbs"

' check for files and prepare varables
Import ".\actions\prepare-environment.vbs"

' clean previous installation if exists
Import ".\actions\clean-previous-installation.vbs"

' clean previous installation if exists
Import ".\actions\create-interfaces.vbs"

' Environment preparation is done
wscript.echo "Setup is done."

' Create and launch master node
Import ".\actions\master-node-create-and-install.vbs"

' Create and launch slave nodes
Import ".\actions\slave-nodes-create-and-boot.vbs"

