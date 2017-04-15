{*******************************************************************************
  ���� ������ ������������ ��� ���������� ��������-�����������

  (�) ������ �������

  ������� ��������� ������ ��� ������������� � ����������� ������� ������� ��� �����
*******************************************************************************}

unit USolutionCheck;

interface
uses
  SysUtils, Windows;

const
  {��� ���������, ������� ������������ ��� �������������� ����������
   � �������}
  {��������� ������}
  INTERNAL_ERROR        = $FF;
  {������� �������}
  ACCEPTED              = $00;
  {������ �������}
  PRESENTATION_ERROR    = $02;
  {��������� �����}
  WRONG_ANSWER          = $01;
  {������ ������������}
  SECURITY_VIOLATION    = $FD;

  {��� ������ ������}
  BufferSize            = 1024*1024;
  {��� ������� ����� �����}
  SYM_EOF               = #0;
  {������� ������ �����}
  SYM_SOF               = #1;
  {������� ����� �������}
  SYM_EOLN              = #2;

  {��������� ���������� ��������}
  BLANCK_SET            = [#9, ' '];


type
  TCharSet = set of Char;
  {**********************************************
    ������ ����� ������������ ��� ��������� �
    ��������� ����� ��� ��������
   **********************************************}
  TInnerFile = class
  private
    {��� ��� ����}
    hFile: THandle;
    {������� ������� � �����}
    FCurrent: Integer;
    {��� ����� - ������ 1 ��������}
    FBuffer: array [0..BufferSize - 1] of Byte;
    {��� ������� � ������}
    FBufPos: Integer;
    {��� ������ ������}
    FBufSize: Integer;
    {������ �����}
    FSize: Integer;
    {��� ���������� ������}
    FLastChar: Char;
  protected
    procedure   ReadSize;
    procedure   ReadBuffer;
    {��� ��������� ������ ��������� �� ��������� ������}
    procedure   MoveCurrent;
    {��� ���������, ������� ������������� ������� ������}
    procedure   ActualCurrent;
  public
    constructor Create(const FileName: String);
    destructor  Destroy; override;
    {������� ���������� ������ ������}
    function    CurrentChar: Char;
    {��������� �������� � ���������� �������}
    procedure   NextChar;
    {�������, ������� ���������� ������� "����� �����"}
    function    EOF: Boolean;
    {�������, ������� ���������� �������� ��������� ��������}
    procedure   SkipChars(SkipSet: TCharSet);
    {��� �������, ������� ���������� ���, ��� �����������
     ������� ���������}
    function    ReadChars(CharSet: TCharSet): String;
    {��� �������, ������� ��������� ��� �� ������ �������,
     �������������� ����-���������, ��������� ��� �������,
     ������� ����������� SKIP-���������}
    function    ReadUntil(StopSet: TCharSet; SkipSet: TCharSet = []): String;
    {������� ���������� ������ �������� - � ��� ��������
     ��� �������, ������� ���������� ������� � ��������
     �� �������� ������}
    function    ReadString: String;
    {��� ������� ���������� "����������" ������� - �� ������ ����������
     ��� ������� � ����������� ������� Blancks}
    function    ReadTrimString(Blancks: TCharSet = BLANCK_SET): String;
    {��������� ����� ����� - � ������������� ���������
     ���� ������� �����}
    function    ReadHugeInt: String;
    {��� �������, ������� ���������� ��������� ��������� ����
     ������� �����. ������� ��������� SGN(A - B)}
    function    CompHugeInts(A, B: String): Integer;
    {��� ������� ���������� ������ ������������� ������ � �����
     ������ ����� A<=x<=B. ��������� �������� �� ���������
     � ������ PRESENTATION_ERROR, ����� - WRONG_ANSWER}
    function    ReadHugeIntBound(A, B: String; PresentError: Boolean = TRUE): String;
    {������� ���������� PRESENTATION_ERROR, ���� ���� ��� ���-��
     �� ����������� � �����, ����� �������� � ��������� �����}
    procedure   IsEmpty;
    {������� ������ ������ �����}
    function    ReadInt: Int64;
    {������� ������ ������������� ������ �����}
    function    ReadIntBound(A, B: Int64; PresentError: Boolean = TRUE): Int64;
    {��������� ���������� ������ ������ �� ����� � ��� ���������,
     ���� ��� �� �������� - ������� WRONG_ANSWER}
    procedure   WaitString(S: String; CaseSence: Boolean = FALSE; Blancks: TCharSet = BLANCK_SET);
    {��������� ���������� ������ ������ �� ����� � ��� ���������,
     ���� ��� �� ��������� - ������� WRONG_ANSWER}
    procedure   WaitInt(Value: Int64);
    {��������� ���������� ������ �������� ������ �� ����� � ��� ���������,
     ���� ��� �� ��������� - ������� WRONG_ANSWER. ��������������
     ��� ������������ ����� �� �������� ������� �����}
    procedure   WaitHugeInt(Value: String);
    {��������� ������ � ��������� ������������� �����}
    procedure   WaitIntBound(Value, A, B: Int64);
    {��������� ������ � ��������� ������������� �������� �����}
    procedure   WaitHugeIntBound(Value, A, B: String);
    {��������� ������ �������� ����� (� ������)
     FracSize �������� ���������� ���� ����� �������
     ���� ��� ������� �� ����, �� ������������ ���������
     � �������� PRESENTATION_ERROR}
    function    ReadHugeFloat(FracSize: Integer = 0): String;
    {��������� ������ �������� �����}
    function    ReadFloat(FracSize: Integer = 0): Extended;
    {��������� ������ � ��������� ���� ������� �����}
    procedure   WaitHugeFloat(Value: String; FracSize: Integer = 0);
    {��������� ������ � ��������� ������� ����� � ��������}
    procedure   WaitFloat(Value, Quality: Extended; FracSize: Integer = 0);
  end;

  {��� ���� CALL_BACK ��������}
  TNGraphWayCallBack = function(I, J: Int64; First: Boolean): Boolean;


{��� �������� ���������, ������� ����� ���� ������������ ��� ��������}
{���������� ������}
procedure _QUIT(ExitCode: Integer; ErrMsg: String);

{��������� N �������� �����. ���� ��� ����� �������
 � ����� �����, �� ���������� ACCEPTED}
procedure CompareNInt(Src, Test: TInnerFile; N: Integer = 1);

{��� ��������� ����������� ��������� ������}
procedure CompareStrEOF(Src, Test: TInnerFile; Sence: Boolean = TRUE; Blancks: TCharSet = []);

{������ ��������� ��������� ���� ����� ����� K, ������� ��������
 ��������� ����������� �����. ����� ����������� � ����������
 ������ � ����������� ���������, ������� ���������� TRUE, ����
 ��� � �������, ��� FALSE, ���� �� � ������. ���� ����� �����
 ������ ��������� ��� �������� ����� � �����. ���� ������ �����
 (K) ����� ZeroConst, �� ���������, ��� ���� ������.
 ������� ����������� ������ ����� � ���������� � �������� I
 � ���������� First = TRUE}
procedure CompNGraphWay(Test: TInnerFile; KEqu: Integer; CallBack: TNGraphWayCallBack; ZeroConst: Integer = 0);


{**********************************************
  ��������� ���������� ��������� ���������
  �������� � ���
 **********************************************}
procedure SendToLogger(S: String; Lev: Integer);


var
  InFile, JudgeFile, ContFile: TInnerFile;

implementation

{**********************************************
  ��������������� ���������, ������� ����������
  ��������������� ��������� �� ������������
 **********************************************}

procedure SendToLogger(S: String; Lev: Integer);
begin
  Writeln('to log: level=',lev,', message=<',s,'>');
end;

procedure Error(const Msg: String);
begin
  //if MessageBox(0, PChar(Msg), '������ ��� ��������', MB_OKCANCEL + MB_ICONERROR + MB_TASKMODAL) = idOK
  //then _QUIT(SECURITY_VIOLATION, '')
  //else 
  _QUIT(INTERNAL_ERROR, '������ �� ������');
end;

procedure APIError(const Msg: String);
begin
  Error('API Error #' + IntToStr(GetLastError) + ' ' +
    SysErrorMessage(GetLastError) + #13 + Msg);
end;

{ TInnerFile }

procedure TInnerFile.ActualCurrent;
begin
  {���������, �������� �� ������� ������ � ��������� �����}
  if (FBufPos < 0) or (FBufPos > FBufSize - 1)
    {��������� ������� �����}
  then ReadBuffer;
end;

function TInnerFile.CompHugeInts(A, B: String): Integer;
var
  Index: Integer;
  Neg1, Neg2: Boolean;
begin
  Assert((A <> '') and (B <> ''), '� ��������� ��������� ��������� "������" �����');
  {�������� ������� � ����� ������}
  Neg1 := A[1] = '-';
  Neg2 := B[1] = '-';
  {�������� �����}
  if Neg1
  then Delete(A, 1, 1);
  if Neg2
  then Delete(B, 1, 1);
  Assert((A <> '') and (B <> ''), '� ��������� ��������� ��������� "������" �����');
  {��������� ������� ����}
  if Length(A) > Length(B)
  then B := StringOfChar('0', Length(A) - Length(B)) + B;
  if Length(A) < Length(B)
  then A := StringOfChar('0', Length(B) - Length(A)) + A;
  if not (Neg1 xor Neg2)
  then begin
    {��������� ����� ����, ���� � ��� ��������� �����}
    Result := 0;
    Assert(Length(A) = Length(B), '������ ��� ������������� ������!');
    {����������}
    for Index := 1 to Length(A) do begin
      Assert(A[Index] in ['0'..'9'], '�� ������ ������ �����');
      Assert(B[Index] in ['0'..'9'], '�� ������ ������ �����');
      if A[Index] < B[Index]
      then begin
        Result := -1;
        Break;
      end else if A[Index] > B[Index]
        then begin
          Result := 1;
          Break;
        end;
    end;
    {���� ����� - �������������, �� ����� ��������� ���������}
    if Neg1
    then Result := -Result;
           {����� �� ��������� - ��������� ��������� �� ���}
  end else Result := Ord(Neg2) - Ord(Neg1);
end;

constructor TInnerFile.Create(const FileName: String);
begin
  inherited Create;
  {��������� ����}
  hFile := CreateFile(
    PChar(FileName),
    GENERIC_READ,
    FILE_SHARE_READ,
    NIL, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, 0
  );
  if hFile = INVALID_HANDLE_VALUE
  then APIError('Try open file: ' + FileName);
  {�������� ������ �����}
  ReadSize;
  {������� ������� - �������}
  FCurrent := 0;
  FBufSize := -1;
  FBufPos := 0;
  FLastChar := SYM_SOF;
end;

function TInnerFile.CurrentChar: Char;
begin
  {���� � ������ ������ �� ����� �� ����� �����, ��
   ���������� ������ ������� SYM_EOF}
  if FCurrent >= FSize
  then Result := SYM_EOF
  else begin
    {��������� ������� ����}
    ActualCurrent;
    Result := Char(FBuffer[FBufPos]);
    {������ ��������, �� ����������� �� ������ ������
     �������� ������}
    if Result in [#10, #13]
    then begin
      {����� ���������, �� ����������� �� ��������� ������
       �������� ������}
      if FLastChar = SYM_EOLN
      then begin
        {�� ����������� - ������ ������ ����� ����������}
        FLastChar := SYM_SOF;
        MoveCurrent;
        Result := CurrentChar;
      end else Result := SYM_EOLN;
    end;
  end;  
end;

destructor TInnerFile.Destroy;
begin
  {��������� ����}
  CloseHandle(hFile);
  inherited;
end;

procedure _QUIT(ExitCode: Integer; ErrMsg: String);
begin
  Assert(ExitCode in [ACCEPTED, INTERNAL_ERROR, PRESENTATION_ERROR, WRONG_ANSWER]);
  case ExitCode of
    INTERNAL_ERROR: begin
      Writeln('INTERNAL_ERROR');
      SendToLogger('INTERNAL ERROR', 2);
      if ErrMsg <> '' then
        SendToLogger(ErrMsg, 2);
    end;
    ACCEPTED: begin
      Writeln('ACCEPTED');
      SendToLogger('ACCEPTED', 2);
      if ErrMsg <> '' then
        SendToLogger(ErrMsg, 2);
    end;
    PRESENTATION_ERROR: begin
      Writeln('PRESENTATION_ERROR');
      SendToLogger('PRESENTATION ERROR', 2);
      if ErrMsg <> '' then
        SendToLogger(ErrMsg, 2);
    end;
    WRONG_ANSWER: begin
      Writeln('WRONG_ANSWER');
      SendToLogger('WRONG ANSWER', 2);
      if ErrMsg <> '' then
        SendToLogger(ErrMsg, 2);
    end;
  end;
  Halt(ExitCode);
end;

procedure CompareNInt(Src, Test: TInnerFile; N: Integer = 1);
var
  Index: Integer;
begin
  for Index := 1 to N do
    Test.WaitHugeInt(Src.ReadHugeInt);
  Test.IsEmpty;
  _QUIT(ACCEPTED, '');
end;

procedure CompareStrEOF(Src, Test: TInnerFile; Sence: Boolean = TRUE; Blancks: TCharSet = []);
begin
  while not Src.EOF do
    Test.WaitString(Src.ReadString, Sence, Blancks);
  Test.IsEmpty;
  _QUIT(ACCEPTED, '');
end;

procedure CompNGraphWay(Test: TInnerFile; KEqu: Integer; CallBack: TNGraphWayCallBack; ZeroConst: Integer = 0);
var
  N: Int64;
  Index: Integer;
  Last: Int64;
  Current: Int64;
begin
  {��������� ��������� � ��������� �����������}
  N := Test.ReadIntBound(KEqu, KEqu, FALSE);
  {������ �������� �������}
  if N <> ZeroConst
  then begin
    {���������� ���������������� ���������� �����}
    Current := Test.ReadInt;
    {������ �����}
    if not CallBack(Current, 0, TRUE)
    then _QUIT(WRONG_ANSWER, '������� ��������� �������� ������� ������');
    for Index := 2 to N do begin
      Last := Current;
      Current := Test.ReadInt;
      {��������� �����}
      if not CallBack(Last, Current, FALSE)
      then _QUIT(WRONG_ANSWER, '������� ��������� �������� ������� ������');
    end;
  end;
  Test.IsEmpty;
  _QUIT(ACCEPTED, '');
end;

{ TInnerFile }

function TInnerFile.EOF: Boolean;
begin
  Result := FCurrent >= FSize;
end;

procedure TInnerFile.IsEmpty;
begin
  SkipChars(BLANCK_SET + [SYM_EOLN]);
  if not EOF
  then _QUIT(PRESENTATION_ERROR, '���� �������� ������ ����������');
end;

procedure TInnerFile.MoveCurrent;
begin
  Inc(FCurrent);
  Inc(FBufPos);
  ActualCurrent;
end;

procedure TInnerFile.NextChar;
begin
  {���������� ������ ������}
  FLastChar := CurrentChar;
  {��������� � ����������}
  MoveCurrent;
end;

procedure TInnerFile.ReadBuffer;
var
  ReadResult: DWORD;
begin
  {��������� ������ � �����}
  FBufPos := 0;
  if not ReadFile(hFile, FBuffer, SizeOf(FBuffer), ReadResult, NIL)
  then APIError('ReadBuffer()');
  FBufSize := ReadResult;
end;

function TInnerFile.ReadChars(CharSet: TCharSet): String;
begin
  Assert(not (SYM_EOF in CharSet), '������ "���������" ����� �����');
  Result := '';
  while CurrentChar in CharSet do begin
    Result := Result + CurrentChar;
    NextChar;
  end;
end;

function TInnerFile.ReadFloat(FracSize: Integer = 0): Extended;
var
  OldSeparator: Char;
begin
  OldSeparator := DecimalSeparator;
  DecimalSeparator := '.';
  Result := StrToFloat(ReadHugeFloat(FracSize));
  DecimalSeparator := OldSeparator;
end;

function TInnerFile.ReadHugeFloat(FracSize: Integer): String;
var
  Sign: String;
  Int, Frac: String;
  Index: Integer;
begin
  {���������� ��������� ������� ������� � �������� �������}
  SkipChars(BLANCK_SET + [SYM_EOLN]);
  {��������� �����}
  Sign := ReadChars(['-', '+']);
  if Length(Sign) > 1
  then _QUIT(PRESENTATION_ERROR, '����� �� ����� ��������� ������ ������ ����� + ��� -');
  if Sign = '+'
  then Sign := '';
  {��������� ����� �����}
  Int := ReadChars(['0'..'9']);
  if Int = ''
  then _QUIT(PRESENTATION_ERROR, '����� ����� �������� ����� �� ����� ���� ������');
  {��������� ������� �����}
  if CurrentChar = '.'
  then begin
    NextChar;
    Frac := ReadChars(['0'..'9']);
    if Frac = ''
    then _QUIT(PRESENTATION_ERROR, '������� ����� �� ����� ���� ������');
    {�������� ����� ������� �����}
    if (FracSize <> 0) and (Length(Frac) <> FracSize)
    then _QUIT(PRESENTATION_ERROR, '���������� ������ � ������� ����� �� ��������� � ��������� ' +
      IntToStr(Length(Frac)) + ' ������ ' + IntToStr(FracSize));
  end else begin
    {�������� ����� �� ������� �����}
    if FracSize <> 0
    then _QUIT(PRESENTATION_ERROR, '����� ����������� ������ ����� ������� �����');
    Frac := '';
  end;
  {�������� ������� ����}
  Index := 1;
  while (Index < Length(Int)) and (Int[Index] = '0') do
    Inc(Index);
  Delete(Int, 1, Index - 1);
  {���� ������� ����� ������, �� ��������� ���� 0}
  if Frac = ''
  then Frac := '0'
  else begin
    {�������� ���������� ����}
    Index := Length(Frac);
    while (Index > 1) and (Frac[Index] = '0') do
      Dec(Index);
    Frac := Copy(Frac, 1, Index);
  end;  
  {���������� ��� � �����}
  Result := Sign + Int + '.' + Frac;
end;

function TInnerFile.ReadHugeInt: String;
var
  Index: Integer;
  Sign: String;
begin
  {���������� ��������� ������� ������� � �������� �������}
  SkipChars(BLANCK_SET + [SYM_EOLN]);
  {���������� �������� - ��� �� ��� �����}
  Sign := ReadChars(['-', '+']);
  {���� ����� ���� ���������}
  if Length(Sign) > 1
  then _QUIT(PRESENTATION_ERROR, '����� �� ����� ��������� ������ ������ ����� + ��� -');
  {���� + ����� ��������}
  if Sign = '+'
  then Sign := '';
  {��������� ��� �����}
  Result := ReadChars(['0'..'9']);
  {�������� ������ ��������� - ���� �������� ���-�� �������� �����}
  if Result = ''
  then _QUIT(PRESENTATION_ERROR, '����� �� ����� ���� ������, ��� ��������� ����� �������� �� ����');
  {������� ������� ����}
  Index := 1;
  while (Index < Length(Result)) and (Result[Index] = '0') do
    Inc(Index);
  Delete(Result, 1, Index - 1);
  {��������� ����, �� ������ �� � ����}
  if Result <> '0'
  then Result := Sign + Result;
end;

function TInnerFile.ReadHugeIntBound(A, B: String; PresentError: Boolean = TRUE): String;
begin
  {��������� ������� �����}
  Result := ReadHugeInt;
  {����������}
  if (CompHugeInts(A, Result) > 0) or (CompHugeInts(Result, B) > 0)
  then begin
    if PresentError
    then _QUIT(PRESENTATION_ERROR, '��������� ����� �� ��������� [' + A + ', ' +
      B + ', � ������� ' + Result)
    else _QUIT(WRONG_ANSWER, '��������� ����� �� ��������� [' + A + ', ' +
      B + ', � ������� ' + Result);
  end;
end;

function TInnerFile.ReadInt: Int64;
begin
  try
    Result := StrToInt64(ReadHugeInt);
  except
    Result := 0;
    _QUIT(PRESENTATION_ERROR, '����� ������� ������ ��� ������� ����, ����� ������������ � Int64');
  end;
end;

function TInnerFile.ReadIntBound(A, B: Int64; PresentError: Boolean = TRUE): Int64;
begin
  Result := ReadInt;
  if (Result < A) or (Result > B)
  then begin
    if PresentError
    then _QUIT(PRESENTATION_ERROR, '��������� ����� �� ��������� [' + IntToStr(A) + ', ' +
      IntToStr(B) + ', � ������� ' + IntToStr(Result))
    else _QUIT(WRONG_ANSWER, '��������� ����� �� ��������� [' + IntToStr(A) + ', ' +
      IntToStr(B) + ', � ������� ' + IntToStr(Result));
  end;
end;

procedure TInnerFile.ReadSize;
begin
  {}
  FSize := GetFileSize(hFile, NIL);
end;

function TInnerFile.ReadString: String;
begin
  Result := ReadUntil([SYM_EOF, SYM_EOLN]);
  {������ ��������� ��������� �� ������ "����� �������"}
  NextChar;
end;

function TInnerFile.ReadTrimString(Blancks: TCharSet): String;
var
  NewLng: Integer;
begin
  {���������� ��� �������}
  SkipChars(Blancks);
  {������ ������ �������}
  Result := ReadString;
  {�������� ��� ���������� �������}
  NewLng := Length(Result);
  while NewLng > 0 do
    if Result[NewLng] in Blancks
    then Dec(NewLng)
    else Break;
  SetLength(Result, NewLng);  
end;

function TInnerFile.ReadUntil(StopSet: TCharSet; SkipSet: TCharSet = []): String;
begin
  {��������� � ����-��������� ����� �����}
  Include(StopSet, SYM_EOF);
  Assert(not (SYM_EOF in SkipSet), '������ ���������� ����� �����');
  Result := '';
  while not (CurrentChar in StopSet) do begin
    if not (CurrentChar in SkipSet)
    then Result := Result + CurrentChar;
    {��������� � ���������� �������}
    NextChar;
  end;
end;

procedure TInnerFile.SkipChars(SkipSet: TCharSet);
begin
  {��������� �� ��������� #0}
  Assert(not (SYM_EOF in SkipSet), '������ ��������� ����� �����');
  {��������� ��� ������� �� ���������}
  while CurrentChar in SkipSet do
    NextChar;
end;

procedure TInnerFile.WaitFloat(Value, Quality: Extended; FracSize: Integer =  0);
var
  Temp: Extended;
begin
  Temp := ReadFloat(FracSize);
  if Abs(Value - Temp) > Quality
  then _QUIT(WRONG_ANSWER, '|' + FloatToStr(Value) + ' - ' + FloatToStr(Temp) +
    '| > ' + FloatToStr(Quality));
end;

procedure TInnerFile.WaitHugeFloat(Value: String; FracSize: Integer = 0);
begin
  if Value <> ReadHugeFloat(FracSize)
  then _QUIT(WRONG_ANSWER, '������� ������� ����� �� ��������� � ��������');
end;

procedure TInnerFile.WaitHugeInt(Value: String);
var
  Temp: String;
begin
  Temp := ReadHugeInt;
  if Value <> Temp
  then _QUIT(WRONG_ANSWER, '������� ' + Value + ', � �������� ' + Temp);
end;

procedure TInnerFile.WaitHugeIntBound(Value, A, B: String);
var
  Temp: String;
begin
  Temp := ReadHugeIntBound(A, B);
  if Value <> Temp
  then _QUIT(WRONG_ANSWER, '������� ' + Value + ', � �������� ' + Temp);
end;

procedure TInnerFile.WaitInt(Value: Int64);
var
  Temp: Int64;
begin
  Temp := ReadInt;
  {����������� ����� � �������}
  if Temp <> Value
  then _QUIT(WRONG_ANSWER, '������� ' + IntToStr(Value) + ', � �������� ' + IntToStr(Temp));
end;

procedure TInnerFile.WaitIntBound(Value, A, B: Int64);
var
  Temp: Int64;
begin
  Temp := ReadIntBound(A, B);
  {����������� ����� � �������}
  if Temp <> Value
  then _QUIT(WRONG_ANSWER, '������� ' + IntToStr(Value) + ', � �������� ' + IntToStr(Temp));
end;

procedure TInnerFile.WaitString(S: String; CaseSence: Boolean = FALSE; Blancks: TCharSet = BLANCK_SET);
var
  I, L: Integer;
  R: String;
  CmpRes: Boolean;
begin
  {������� �������� �������}
  I := 1;
  while I <= Length(S) do
    if S[I] in Blancks
    then Inc(I)
    else Break;
  {I - ������ �� ���������� ������}
  L := Length(S) - I;
  while L > 0 do
    if S[I + L] in Blancks
    then Dec(L)
    else Break;
  S := Copy(S, I, L + 1);
  {������ ��������� �������}
  R := ReadTrimString(Blancks);
  if CaseSence
  then CmpRes := AnsiSameStr(S, R)
  else CmpRes := AnsiSameText(S, R);
  {���������� ������}
  if not CmpRes
  then _QUIT(WRONG_ANSWER, '������� ������ "' + S + '", � �������� "' + R + '"');
end;

initialization
  try
    InFile := TInnerFile.Create(ParamStr(1));
    JudgeFile := TInnerFile.Create(ParamStr(3));
    ContFile := TInnerFile.Create(ParamStr(2));
  except
    _QUIT(INTERNAL_ERROR, '������ ��� �������� ������');
  end;
finalization
  InFile.Free;
  JudgeFile.Free;
  ContFile.Free;
end.
