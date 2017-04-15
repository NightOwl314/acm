{
 * argv[1] - input data
 * argv[2] - the program output
 * argv[3] - correct answer
}

var
 f1,f2: Text;
 c1,c2: Char;
 
begin
 assign(f1,ParamStr(2));
 reset(f1);
 assign(f2,ParamStr(3)); 
 reset(f2);
 while(not eof(f1))or(not eof(f2))do
 begin
  c1:=chr(0);
  while (not eof(f1)) and (c1=chr(0)) do
  begin
   read(f1,c1);
   if ord(c1)<=32 then c1:=chr(0);
  end; 
  c2:=chr(0);
  while (not eof(f2)) and (c2=chr(0)) do
  begin
   read(f2,c2);
   if ord(c2)<=32 then c2:=chr(0);
  end;    
  if c1 <> c2 then
  begin
   close(f1);
   close(f2);
   halt(1);
  end;
 end;
 close(f1);
 close(f2);
end.
   