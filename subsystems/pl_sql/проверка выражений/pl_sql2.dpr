program pl_sql2;

{$APPTYPE CONSOLE}

uses
  SysUtils, Windows, Classes;

var
    f_sql,f_out,f_t: TextFile;
    s: String;
    i,t,j: integer;

begin
  { TODO -oUser -cConsole Main : Insert code here }

//Проверка на наличие файла с кодом пользователя ***********************
{  if ParamStr(1)<>'' then} AssignFile(f_sql,ParamStr(1));
  try
    reset(f_sql);
  except
    AssignFile(f_sql,'plsql.log');
    rewrite(f_sql);
    writeln(f_sql,'Отсутствует файл с кодом пользователя!');
         writeln(f_sql,ParamStr(0));
         writeln(f_sql,ParamStr(1));
         writeln(f_sql,ParamStr(2));
    CloseFile(f_sql);
    exit;
  end;
//**********************************************************************

//Обработка запрещённых конструкций ************************************
  t:=0;
  while not eof(f_sql) do
  begin
    readln(f_sql,s);
    for i:=2 to ParamCount do
    begin
       if (pos(UpperCase(ParamStr(i)),UpperCase(s))>0) and (s<>'')
       then
       begin
//         AssignFile(f_out,ParamStr(1)+'.out');
//         rewrite(f_out);
         writeln(output,'Ваш код содержит запрещённые выражения!');
         writeln(output,'Решение не должно содержать:');
         writeln(output,'+-------------------------------------+');
         for j:=2 to ParamCount do writeln(output,ParamStr(j));
         writeln(output,'+-------------------------------------+');
//         writeln(f_out,ParamStr(0));
//         writeln(f_out,ParamStr(1));
//         writeln(f_out,ParamStr(2));
//         CloseFile(f_out);
         t:=2;
         break;
       end;
    end;
    if t=2 then break;
  end;
  CloseFile(f_sql);
  if t=2 then begin halt(t); end;
//***********************************************************************



end.
