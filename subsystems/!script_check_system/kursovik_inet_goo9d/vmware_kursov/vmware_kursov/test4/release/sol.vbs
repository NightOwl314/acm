Dim objFSO,objFldr,objTS

strDir="c:"

Set objFSO=CreateObject("Scripting.FileSystemObject")
strFile="c:\\test.txt"
Set objTS=objFSO.CreateTextFile(strFile)
objTS.WriteLine "3.14"
objTS.Close
WScript.Quit
