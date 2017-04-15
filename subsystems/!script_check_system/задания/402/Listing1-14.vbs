On Error Resume Next
Dim objFSO,objTS
Dim objDom,objUser

Const FORREADING=1

strFile="newusers.csv"
'format of newusers.csv
'givenname,sn,password,telephonenumber,upnsuffix
'example:
'Jeff,Hicks,P@sswordJH,555-1234,@jdhitsolutions.com
'Don,Jones,$cr1pting@nsw3rs,555-1234,@scriptinganswers.com

Set objFSO=CreateObject("Scripting.FileSystemObject")
Set objTS=objFSO.OpenTextFile(strFile,FORREADING)

Set objDom=GetObject("LDAP://OU=students,DC=avt,DC=vstu,DC=edu,DC=ru")

'open text file and process user data on each line
Do while objTS.AtEndofStream<>True
 rline=objTS.readline
 UserArray=Split(rline,",")

 	strFirst=UserArray(0)
	strLast=UserArray(1)
	strUser=strFirst & " " & strLast
	strLogon=Left(strFirst,1)&strLast
	strUsername=LCASE(Left(strFirst,1)&strlast)
	strPass=UserArray(2)
	strPhone=UserArray(3)
	strUPN=strUserName & UserArray(4)

'Create user object
Set objUser=objDom.Create ("User","cn="&strUser)
objUser.Put "samAccountName",strUserName
objUser.SetInfo

'Now that user object is created, let's set some properties
objUser.Put "givenname",strFirst
objUser.Put "sn",strLast
objUser.Put "displayname",strFirst & " " & strLast
objUser.Put "UserPrincipalName",strUPN
objUser.Put "AccountDisabled",FALSE
objUser.Put "TelephoneNumber",strPhone
objUser.SetPassword(strPass)
objUser.SetInfo
objUser.Put "AccountDisabled",FALSE
objUser.SetInfo
Loop

objTS.Close

WScript.Quit