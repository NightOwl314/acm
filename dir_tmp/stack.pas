unit stack;

interface

type 
  TPushProc = procedure (x: integer); 
  TPopFunction = function: integer;
  TTopFunction =  function: integer;
  TSizeFunction = function: integer;

//Проверка решения
procedure Check(push: TPushProc; pop: TPopFunction; 
  top: TTopFunction; size: TSizeFunction);

implementation

procedure Check(push: TPushProc; pop: TPopFunction; 
  top: TTopFunction; size: TSizeFunction);
var 
  i,k,testnum:integer;
begin
  assign(input,ParamStr(1));
  reset(input);
  read(testnum);

  //Проверка базовой функциональности
  if testnum=1 then begin
    for i:=1 to 5 do push(i);
    for i:=1 to 5 do write(pop(),' ');
    exit;
  end;
    
  //Несколько заполнений и опустошений
  if testnum=2 then begin
    for k:=1 to 3 do
    begin
      for i:=1 to 5 do push(i); 
      writeln(size());
      for i:=1 to 5 do write(pop(),' ');
      writeln; 
      writeln(size());
    end;
    exit;
  end;

  //Корректность освобождения памяти
  if testnum=3 then begin
    for k:=1 to 100000 do    
    begin
       for i:=1 to 10 do push(i);
       for i:=1 to 9 do pop();
    end;
    for k:=1 to 100000 do pop();
    for k:=1 to 100 do push(k);
    for k:=1 to 100 do write(pop(),' ');
    exit;
  end;

end; 


end.
