{��Ѹ�}{2008}
program Compil;

{$APPTYPE CONSOLE}

uses
  SysUtils, Classes, IdBaseComponent, IdComponent, IdTCPConnection, IdTCPClient,
  IdHTTP, IniFiles;

var
  myIdHTTP: TIdHTTP;
  tifFileIni: TIniFile;
  fFileIndex,fFileIn,fFileTmp: text;
  tslFileConfig,tslParams,tslFileSource,tsl___: TStringList;
  s,str,sQuery,sDirTmp,sFileInName,sPrbNum,sFileTmp,sResponse: string;
  i,j,n,iTime,iMemory,iAnswer: integer;

{
function myGetValue(Source: TStringList; Param: string): string;
var
  s: string;
  i,j,l: integer;
begin
  j:=Length(Param);
  for i:=0 to Source.Count-1 do
  begin
    s:=TrimLeft(Source.Strings[i]);
    l:=Length(s);
    if (l>j) and (s[1]<>'#') and (LowerCase(Copy(s,1,j))=LowerCase(Param)) then
    begin
      s:=TrimLeft(Copy(s,j+1,l-j));
      l:=Length(s);
      if (l>0) and (s[1]='=') then
      begin
        s:=Trim(Copy(s,2,l-1));
        Result:=s;
        Break;
      end;
    end;
  end;
end;
}

procedure myTerminate(ExitCode: integer);
begin
  tsl___.Free;
  tslFileSource.Free;
  tslParams.Free;
  tslFileConfig.Free;
  tifFileIni.Free;
  myIdHTTP.Free;
  Halt(ExitCode);
end;

procedure myRaiseFileError(FileName: string);
begin
  WriteLn('Read or write error in file "'+FileName+'"');
  myTerminate(1);
end;

procedure myCheckFileIni(FileName: string);
var
  tslTmp: TStringList;
begin
  tslTmp:=TStringList.Create;
  tifFileIni.ReadSections(tslTmp);
  if tslTmp.Count=0 then myRaiseFileError(FileName);
  tslTmp.Free;
end;

procedure myStrReplace(var tslSrc: TStringList; strFind, strNew: string);
var
  strSrc: string;
  i,j: integer;
begin
  for j:=0 to tslSrc.Count-1 do
  begin
    strSrc:=tslSrc.Strings[j];
    i:=Pos(strFind,strSrc);
    while i>0 do
    begin
      strSrc:=Copy(strSrc,1,i-1)+strNew+Copy(strSrc,i+Length(strFind),Length(strSrc)-Length(strFind)-i+1);
      i:=Pos(strFind,strSrc);
    end;
    tslSrc.Strings[j]:=strSrc;
  end;
end;

begin
  myIdHTTP:=TIdHTTP.Create(nil);
  tslFileConfig:=TStringList.Create;
  tslParams:=TStringList.Create;
  tslFileSource:=TStringList.Create;
  tsl___:=TStringList.Create;

  s:=ParamStr(3);
  tifFileIni:=TIniFile.Create(s);
  myCheckFileIni(s);

  try
    sDirTmp:=tifFileIni.ReadString('global paths','DirTemp','c:\acm\dir_tmp')+'\';
    str:=tifFileIni.ReadString('global paths','DirProblems','c:\acm\problems')+'\'+ParamStr(2)+'\';
    s:=str+tifFileIni.ReadString('problem paths','ListTests','index.lst');
    Assign(fFileIndex,s);
    Reset(fFileIndex);
    ReadLn(fFileIndex,sFileInName);
    Close(fFileIndex);

    s:=str+tifFileIni.ReadString('problem paths','Tests','tests')+'\'+sFileInName+'.in';
    Assign(fFileIn,s);
    Reset(fFileIn);
    ReadLn(fFileIn,sPrbNum);
    Close(fFileIn);

    s:=ParamStr(4);
    tslFileConfig.LoadFromFile(s);
    myStrReplace(tslFileConfig,'$(prb_num)',sPrbNum);
    myStrReplace(tslFileConfig,'$(src_file)',sDirTmp+ParamStr(1));

    s:=sDirTmp+ParamStr(1)+'.nul';
    sFileTmp:=s;
    tslFileConfig.SaveToFile(s);
    tifFileIni.Free;
    tifFileIni:=TIniFile.Create(s);
    myCheckFileIni(s);
    tifFileIni.ReadSectionValues('section2',tslParams);

    s:=sDirTmp+ParamStr(1)+'.pas';
    tslFileSource.LoadFromFile(s);
    sQuery:=tslFileSource.Strings[0];
    for i:=1 to tslFileSource.Count-1 do sQuery:=sQuery+#13#10+tslFileSource.Strings[i];
    myStrReplace(tslParams,'$(src_text)',sQuery);
  except
    myRaiseFileError(s);
  end;

//  myIdHTTP.Request.ContentType:='text/html';
    myIdHTTP.Request.AcceptCharSet:=tifFileIni.ReadString('section1','AcceptCharSet','dos-866');
//  myIdHTTP.Request.AcceptCharSet:='windows-1251';

  try
    s:=tifFileIni.ReadString('section1','URL Send','...');
//    Writeln('Sending request to '+s);
    sResponse:=myIdHTTP.Post(s,tslParams);
//    Writeln('Completed request to '+s);

    Sleep(tifFileIni.ReadInteger('section1','WaitTime',0));

    s:=tifFileIni.ReadString('section1','URL Status','...');
//    Writeln('Sending request to '+s);
    sResponse:=myIdHTTP.Get(s);
//    Writeln('Completed request to '+s);
  except
    Writeln('Error: cannot receiving data from '+s);
    Halt(1);
  end;

  // ��������� section3
  tsl___.Clear;
  i:=tslFileConfig.IndexOf('[section3]')+1;
  j:=tslFileConfig.Count-1;
  while i<=j do
  begin
    s:=Trim(tslFileConfig.Strings[i]);
    if Length(s)>0 then
      if s[1]='[' then Break else
        if s[1]<>'#' then tsl___.Add(s);
    inc(i);
  end;

  iTime:=0;
  iMemory:=0;
  iAnswer:=1;
  i:=0;
  j:=tsl___.Count-1;
  while i<=j do
  begin
    s:=Trim(tsl___.Strings[i]);
    if s[1]='$' then
    begin
      if (i+1)>j then n:=Length(sResponse)
        else n:=Pos(Trim(tsl___.Strings[i+1]),sResponse);

      if s='$(status)' then
      begin
        if Trim(Copy(sResponse,1,n-1))=tifFileIni.ReadString('section1','CompilError','...')
          then myTerminate(1) else
            if Trim(Copy(sResponse,1,n-1))=tifFileIni.ReadString('section1','NoError','...')
              then iAnswer:=0;
        end else

      if s='$(time)' then
        try
          iTime:=StrToInt(Trim(Copy(sResponse,1,n-1)))
        except

        end else
          if s='$(memory)' then
            try
              iMemory:=StrToInt(Trim(Copy(sResponse,1,n-1)));
            except

            end;
    end else
    begin
      n:=Pos(s,sResponse);
      if n>0 then
      begin
        Delete(sResponse,1,n+Length(s)-1);
      end else
      begin
        Break;
      end;
    end;
    inc(i);
  end;

  Assign(fFileTmp,sFileTmp);
  Rewrite(fFileTmp);
  Writeln(fFileTmp,iTime);   // �����
  Writeln(fFileTmp,iMemory);   // ������
  Writeln(fFileTmp,iAnswer);    // 0 - ����� ����������, 1 - �������� �����
  Writeln(fFileTmp,sQuery);   // ���������� ������������� ����� ���������
  Close(fFileTmp);

  myTerminate(0);
end.
