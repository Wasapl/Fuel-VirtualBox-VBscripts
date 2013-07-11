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
	dim inputFile, strInputFile, outputFile, rxp
	Set inputFile = CreateObject("Scripting.FileSystemObject").OpenTextFile(strFilename, 1)
	strInputFile = inputFile.ReadAll
	inputFile.Close
	' wscript.echo inputFile
	' wscript.echo strFind
	' wscript.echo strReplace
	Set inputFile = Nothing
	Set outputFile = CreateObject("Scripting.FileSystemObject").OpenTextFile(strFilename, 2, true)

	Set rxp = New RegExp : rxp.Global = True : rxp.Multiline = True
	rxp.Pattern = strFind

	outputFile.Write rxp.Replace(strInputFile,  strReplace)
	outputFile.Close
	Set outputFile = Nothing
end function 
'Find_And_Replace "..\config.vbs", "host_nic_name\(0\) = .+$", "hostonly_interface_name=""HOIF name"""


function get_first_file(folder,FileExtention)
' Open folder and search for file with extention FileExtention
' Returns: string filename
	get_first_file = ""
	dim ISOs, f
	Set ISOs = CreateObject("Scripting.FileSystemObject").GetFolder(folder).Files
	for each f in ISOs
		if Right(f.name,len(FileExtention)) = FileExtention then
			get_first_file = folder & "\" & f.name
			exit for
		end if 
	next
end Function
'wscript.echo get_first_file("..\iso\","iso")
