Option Explicit

Function strip_quotes (str)
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
'Find_And_Replace "..\config.vbs", "hostonly_interface_name=.+$", "hostonly_interface_name=""shitty shit"""
