Option Explicit
' This file contains additional functions


Function strip_quotes (str)
' Removes leading and/or trailing qoute if any
' Inputs: string
' Returns: string without qoutes
	if left(str,1) = """" then 
		str = right(str, len(str)-1)
	end if
	if right(str,1) = """" then 
		str = left(str, len(str)-1)
	end if
	strip_quotes = str
End Function
'wscript.echo strip_quotes ("""12345""")


function Find_And_Replace(strFilename, strFind, strReplace)
' Open strFilename, search for strFind and relace it with strReplace
' Returns: nothing
	dim objInputFile, strInputFile, objOutputFile, objRXP

	Set objInputFile = CreateObject("Scripting.FileSystemObject").OpenTextFile(strFilename, 1)
	strInputFile = objInputFile.ReadAll
	objInputFile.Close
	Set objInputFile = Nothing

	Set objOutputFile = CreateObject("Scripting.FileSystemObject").OpenTextFile(strFilename, 2, true)

	Set objRXP = New RegExp : objRXP.Global = True : objRXP.Multiline = True
	objRXP.Pattern = strFind

	objOutputFile.Write objRXP.Replace(strInputFile,  strReplace)
	objOutputFile.Close
	Set objOutputFile = Nothing
end function 
'Find_And_Replace "..\config.vbs", "host_nic_name\(0\) = .+$", "hostonly_interface_name=""HOIF name"""


function get_first_file(strFolder,strFileExtention)
' Open strFolder and search for file with extention strFileExtention
' Returns: string filename
	get_first_file = ""
	dim objFiles, objFile
	Set objFiles = CreateObject("Scripting.FileSystemObject").Getfolder(strFolder).Files
	for each objFile in objFiles
		if Right(objFile.name,len(strFileExtention)) = strFileExtention then
			get_first_file = strFolder & "\" & objFile.name
			exit for
		end if 
	next
end Function
'wscript.echo get_first_file("..\iso\","iso")
