{$A+,B-,D+,E+,F-,G-,I-,L+,N+,O-,P-,Q+,R+,S+,T-,V+,X+,Y+}//aaa
//{$A+,B-,D+,E+,F-,G-,I-,L+,N+,O-,P-,Q+,R+,S+,T-,V+,X+,Y+}
//{$M 65520,0,655360} 

//Uses Crt;

type 
  tField = Array[1..3,1..3] of byte;

var
  A:tField;
  Was:Array[0..46000] of byte;

Procedure Init;
var
  i,j,e,k:Integer;
  ch:Char;
  S:String;
Begin
//  Assign(Input,'input.txt');
//  reSet(Input);

  e:=1;
  for i:=1 to 3 do begin
    readLn(S);
    if length(S)<3 then S:=S+' ';
    for j:=1 to 3 do
      case S[j] of
        '•':A[i,j]:=3;
        '€':A[i,j]:=4;
        'Œ':A[i,j]:=5;
        '…':begin A[i,j]:=e; inc(e); end;
        '‹':A[i,j]:=6;
        'Ž':A[i,j]:=7;
        '':A[i,j]:=8;
        ' ':A[i,j]:=9;
      end;
  end;

  Close(Input);
End;

const
  hex:Array[0..7] of byte  = (1,2,4,8,$10,$20,$40,$80);
  fakt:Array[1..8] of word = (1,2,6,24,120,720,5040,40320);

Procedure putWas(index:longInt);
Begin
  Was[index shr 3]:=Was[index shr 3] or hex[index mod 8];
End;

Function takeWas(index:longInt):boolean;
Begin
  takeWas:=boolean( (Was[index shr 3] shr (index mod 8)) and 1 );
End;

Procedure inMatr(var A:tField;k:longInt);
var
  Trans:Array[1..9] of byte;
  s:set of byte;
  i,j:Integer;
Begin
  for i:=1 to 9 do
    Trans[i]:=1;
  s:=[];
  for i:=1 to 8 do begin
    while k>=fakt[9-i] do begin
      while Trans[i] in s do inc(trans[i]);
      inc(Trans[i]);
      dec(k,fakt[9-i]);
    end;
    while Trans[i] in s do inc(trans[i]);
    include(s, Trans[i]);
  end;

  while Trans[9] in s do inc(trans[9]);

  for i:=1 to 3 do
    for j:=1 to 3 do
      A[i,j]:=Trans[(i-1)*3+j];
End;

Function inLong(A:tField):longInt;
var
  Trans:Array[1..9] of byte;
  i,j:Integer;
  res:longInt;
Begin
  for i:=1 to 3 do
    for j:=1 to 3 do
      Trans[(i-1)*3+j]:=A[i,j];

  res:=0;
  for i:=1 to 8 do begin
    inc(res,longInt(Trans[i]-1)*fakt[9-i]);
    for j:=i+1 to 9 do
      if Trans[j]>Trans[i] then
        dec(Trans[j]);
  end;

  inLong:=res;
End;

const
  numPred  = 4;
  maxStack = 16383;
  maxPred:longInt = 65535;
  mPred = 65535;
  sheet:Array[-1..1,-1..1] of byte = ( (0,1,2),
                                       (3,4,5),
                                       (6,7,8)
                                     );

type
  tSt=Array[0..maxStack-1] of longInt;
  pSt=^tSt;
  tPred=Array[0..mPred-1] of byte;
  pPred=^tPred;

var
  pred:Array[0..numPred-1] of pPred;
  St:Array[0..1] of pSt;
  Up,Down:longInt;

Procedure putPred(index:longInt;di,dj:shortInt);
var c:integer;
Begin
  c:=(index mod 2);
  index := index div 2;

  pred[index div maxPred]^[index mod maxPred]:=
     pred[index div maxPred]^[index mod maxPred] or (sheet[di,dj] shl (c*4))
End;

Procedure takePred(index:longInt;var di,dj:shortInt);
var c:integer;
    sh:Byte;
Begin
  c:=(index mod 2);
  index:=index div 2;

  if c = 0 then
    case (pred[index div maxPred]^[index mod maxPred]) and $F of
      1 : begin di:=-1; dj:=0;  end;
      3 : begin di:=0;  dj:=-1; end;
      5 : begin di:=0;  dj:=1;  end;
      7 : begin di:=1;  dj:=0;  end;
      else begin di:=0; dj:=0; end;
    end
  else
    case (pred[index div maxPred]^[index mod maxPred]) and $F0 of
      1 shl 4:begin di:=-1; dj:=0;  end;
      3 shl 4:begin di:=0;  dj:=-1; end;
      5 shl 4:begin di:=0;  dj:=1;  end;
      7 shl 4:begin di:=1;  dj:=0;  end;
      else begin di:=0; dj:=0; end;
    end;
End;

var
  pos:longInt;

Procedure searchHole(Matr:tField;var i,j:Integer);
Var ii,jj:byte;
Begin
  for ii:=1 to 3 do
    for jj:=1 to 3 do
      if Matr[ii,jj]=9 then begin
        i:=ii;
        j:=jj;
        Exit;
      end;
End;

Function Mutate(A:tField; i,j,di,dj:Integer):longInt;
Begin
  if (i+di<1) or (j+dj<1) or (i+di>3) or (j+dj>3) then
    Mutate:=-1
  else begin
    A[i,j]:=A[i+di,j+dj];
    A[i+di,j+dj]:=9;

    Mutate:=inLong(A);
  end;
End;

Procedure Solve;
const
  finPos1 = 92184;
  finPos2 = 92304;
var
  posMatr:tField;
  newPos:longInt;
  i,j,di,dj:Integer;
  Fin:boolean;
Label 1;
Begin
  fillChar(Was,sizeOf(Was),0);
  new(St[0]); new(St[1]);
  for i:=0 to numPred-1 do begin
    new(pred[i]);
    fillChar(pred[i]^,sizeOf(pred[i]^),0);
  end;

  Fin:=false;

  pos:=inLong(A);
  if (pos=finPos1) or (pos=finPos2) then
    Fin:=True;

  putWas(pos);

  Down:=0;Up:=1;
  St[0]^[0]:=pos;
  while not Fin do begin
    pos:=St[Down div maxStack]^[Down mod maxStack];
    Down:=(Down+1) mod (2*maxStack);

    inMatr(posMatr, pos);
    searchHole(posMatr,i,j);
    for di:=-1 to 1 do
      for dj:=-1 to 1 do
        if ((di<>0) or (dj<>0)) and ((di=0) or (dj=0)) then begin
          newPos:=Mutate(posMatr,i,j,di,dj);

          if (newPos>=0) and not TakeWas(newPos) then begin
            putWas(newPos);
            St[Up div maxStack]^[Up mod maxStack]:=newPos;
            Up:=(Up+1) mod (2*maxStack);

            putPred(newPos, di, dj);

            if (newpos=finPos1) or (newpos=finPos2) then begin
              Fin:=True;
              pos:=newPos;
              goto 1;
            end;
          end;
        end;
1:  end;
End;

Procedure Print;
const
  maxWay = 100;
var
  Way:Array[1..maxWay,1..2] of shortInt;
  Matr:tField;
  cnt,i,j,k:Integer;
  di,dj:shortInt;
Begin
  cnt:=0;
  takePred(pos,di,dj);
  Matr:=A;
  inMatr(A, pos);
  while (di<>0) or (dj<>0) do begin
    inc(Cnt);
    Way[Cnt,1]:=di;
    Way[Cnt,2]:=dj;

    searchHole(A,i,j);
    A[i,j]:=A[i-di,j-dj];
    A[i-di,j-dj]:=9;
    pos:=inLong(A);
    takePred(pos,di,dj);
  end;

//  Assign(Output,'Output.txt');
//  reWrite(Output);

  writeLn(Cnt);
{  searchHole(Matr,i,j);
  for k:=Cnt downto 1 do begin
    inc(i,Way[k,1]);
    inc(j,Way[k,2]);
    writeLn(i,' ',j);
  end;               }

  Close(Output);
End;

Begin
  Init;
  Solve;
  Print;
End.