{��Ѹ�}{2008}
program Proj;

{$APPTYPE CONSOLE}

uses
  SysUtils;

var
  fFileTmp: text;
  p: pointer;
  iTime,iMem,iResult: integer;

begin
  // ��������� ������ ������ �� ���������� �����
  Assign(fFileTmp,Copy(ParamStr(0),1,Length(ParamStr(0))-4)+'.nul');
  Reset(fFileTmp);
  Readln(fFileTmp,iTime);   // �����
  Readln(fFileTmp,iMem);    // ������
  Readln(fFileTmp,iResult);   // 0 - ����� ����������, 1 - �������� �����
  Close(fFileTmp);

  if iResult<>0 then Writeln('Output...');
  GetMem(p,iMem*1024);    // ����������� ������
  Sleep(iTime);   // ���...
  FreeMem(p,iMem*1024);
end.
