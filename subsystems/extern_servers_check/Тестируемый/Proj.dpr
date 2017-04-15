{ВаСёК}{2008}
program Proj;

{$APPTYPE CONSOLE}

uses
  SysUtils;

var
  fFileTmp: text;
  p: pointer;
  iTime,iMem,iResult: integer;

begin
  // Считываем нужные данные из временного файла
  Assign(fFileTmp,Copy(ParamStr(0),1,Length(ParamStr(0))-4)+'.nul');
  Reset(fFileTmp);
  Readln(fFileTmp,iTime);   // Время
  Readln(fFileTmp,iMem);    // Память
  Readln(fFileTmp,iResult);   // 0 - ответ правильный, 1 - неверный ответ
  Close(fFileTmp);

  if iResult<>0 then Writeln('Output...');
  GetMem(p,iMem*1024);    // Резервируем память
  Sleep(iTime);   // Ждём...
  FreeMem(p,iMem*1024);
end.
