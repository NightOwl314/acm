unit testlibKC;
{$I testlib.inc}
BEGIN {ÈÍÈÖÈÀËÈÇÀÖÈß}
   if (ParamCount < 3) or (ParamCount>4) then
      Quit (_fail, 'Ñèíòàêñèñ: <INPUT-FILE> <OUTPUT-FILE> <ANSWER-FILE> [<log-file>]');

   if paramcount=4 then begin
     assign (output, paramstr (4)); rewrite (output);
     TestLibOutput:=true;
   end;

   inf.opened := false;
   ouf.opened := false;
   ans.opened := false;

   inf.init (ParamStr (1), _Input);
   ouf.init (ParamStr (2), _Output);
   ans.init (ParamStr (3), _Answer);
end.
