{ÂàÑ¸Ê}{2008}
program Test;

{$APPTYPE CONSOLE}

uses
  SysUtils;

var
  fFile: text;
  s: string;

begin
  try
    Assign(fFile,ParamStr(2));
    Reset(fFile);
    Readln(fFile,s);
    Close(fFile);
  except
    Writeln('Error: cannot read file "'+ParamStr(2)+'"');
    Halt(1);
  end;
  if s<>'Output...' then Halt(0);
  try
    Assign(fFile,ParamStr(1));
    Rewrite(fFile);
    Writeln(fFile,'Input...');
    Close(fFile);
  except
  end;
  Halt(1);
end.

