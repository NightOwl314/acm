unit queue;

interface

type 
  TEnqueueProc = procedure (x: integer);
  TDequeueFunction = function: integer;
  TFirstFunction = function: integer; 
  TSizeFunction = function: integer; 

//Проверка решения
procedure Check(enqueue: TEnqueueProc; dequeue: TDequeueFunction; 
  first: TFirstFunction; size: TSizeFunction);

implementation

procedure Check(enqueue: TEnqueueProc; dequeue: TDequeueFunction; 
  first: TFirstFunction; size: TSizeFunction);
var 
  i,k,testnum:integer;
begin
  assign(input,ParamStr(1));
  reset(input);
  read(testnum);

  //Проверка базовой функциональности
  if testnum=1 then begin
    for i:=1 to 5 do enqueue(i);
    for i:=1 to 5 do write(dequeue(),' ');
    exit;
  end;
    
  //Несколько заполнений и опустошений
  if testnum=2 then begin
    for k:=1 to 3 do
    begin
      for i:=1 to 5 do enqueue(i); 
      writeln(size());
      for i:=1 to 5 do write(dequeue(),' ');
      writeln; 
      writeln(size());
    end;
    exit;
  end;

  //Корректность освобождения памяти
  if testnum=3 then begin
    for k:=1 to 100000 do    
    begin
       for i:=1 to 10 do enqueue(i);
       for i:=1 to 9 do dequeue();
    end;
    for k:=1 to 100000 do dequeue();
    for k:=1 to 100 do enqueue(k);
    for k:=1 to 100 do write(dequeue(),' ');
    exit;
  end;

end; 


end.
