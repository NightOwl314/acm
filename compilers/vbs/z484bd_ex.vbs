dim sfilter

sub makef(group)
  dim objExec

  sfilter = sfilter & "(memberof=" & group & ")"
    
  strCommand = "dsquery * -filter ""(&(memberof=" & group & ")(objectClass=group))"" -attr distinguishedName -l"
  Set objExec=objShell.Exec(strCommand)
  Do While objExec.StdOut.AtEndOfStream<>True 
    groupName=objExec.StdOut.ReadLine 
    makef(groupName)
  loop

end sub

set objShell=CreateObject("wscript.shell")
makef("CN=Administrators,CN=Builtin,DC=lab1,DC=local")
sfilter = "(&(objectClass=user)(|" & sfilter & "))"
strCommand = "cmd /c dsquery * -filter """ & sfilter & """ -attr samAccountName -l | sort"
Set objExec=objShell.Exec(strCommand)

Set objFSO=CreateObject("Scripting.FileSystemObject")
strFile="c:\\admins.txt"
Set objTS=objFSO.CreateTextFile(strFile)
Do While objExec.StdOut.AtEndOfStream<>True 
  userName=objExec.StdOut.ReadLine 
  objTS.WriteLine userName
loop
objTS.Close

