program runmmc;

uses windows, sysutils;

type
 TCreateProcessWithLogonW = function(
 lpUsername : PWideChar;
 lpDomain : PWideChar;
 lpPassword : PWideChar;
 dwLogonFlags : DWORD;
 lpApplicationName : PWideChar;
 lpCommandLine : PWideChar;
 dwCreationFlags : DWORD;
 lpEnvironment : Pointer;
 lpCurrentDirectory : PWideChar;
 const lpStartupInfo : _STARTUPINFOA;
 var lpProcessInfo : PROCESS_INFORMATION
 ):BOOL;stdcall;

var
 hLib:THandle;
 CreateProcessWithLogon : TCreateProcessWithLogonW;
 si : _STARTUPINFOA;
 pi : Process_Information;
 name,pass,domain,appname: WideString;
 exit_code: DWORD;
 MsgBuf: Pointer;
 f: text;

begin
  hLib:=LoadLibrary('advapi32.dll');
  ZeroMemory(@Si,Sizeof(si));
  si.cb:=SizeOf(si);
  CreateProcessWithLogon:=GetProcAddress(hLib,'CreateProcessWithLogonW');
  name := 'acm-checker';
  pass := 'acm';
  domain := 'AVT';
  appname := ExtractFilePath(ParamStr(0))+'doschk.exe ' + 
   GetCurrentDir + '\' + ParamStr(1) + ' ' + 
   GetCurrentDir + '\' +  ParamStr(2) + ' ' + 
   GetCurrentDir + '\' +  ParamStr(3);

  if not CreateProcessWithLogon(PWideChar(name),PWideChar(domain),PWideChar(pass),1,nil,PWideChar(appname),0,nil,nil,si,pi) then
  begin
    Writeln('Can''t create process with logon'); halt(5);
  end;
  if WaitForSingleObject(pi.hProcess,60*1000) = WAIT_TIMEOUT then
  begin
    TerminateProcess(pi.hProcess,3);
    halt(3);
  end;
  GetExitCodeProcess(pi.hProcess, exit_code);
  halt(exit_code);
end.
