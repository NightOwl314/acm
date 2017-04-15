Dim objFSO,objFldr,objTS,s

strDir="c:"

on error resume next
Set objFSO=CreateObject("Scripting.FileSystemObject")
strFile="c:\\test.txt"
Set objTS=objFSO.OpenTextFile(strFile)
s=objTS.ReadLine
objTS.Close
if Err.Number=0 then
 if (s="3.14") then
   WSCript.Echo "OK" 
   WScript.Quit 0
 else
   WSCript.Echo "WA"
   WScript.Quit 1
 end if
else
  WSCript.Echo "PE"
  WScript.Quit 2
end if
 