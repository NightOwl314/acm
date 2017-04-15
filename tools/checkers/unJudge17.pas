////////////////////////////////////////////////////////////////////////////////
///                                                                          ///
///  Турнирная система Contester (www.contester.ru)                          ///
///  Вспомогательный модуль для тестирующих программ (чекеров)               ///
///  unJudge v1.7 от 14.03.08. FreePascal 2.0.4+, Delphi 6/7 и TurboDelphi   ///
///  Клопов Игорь, Ковровская Государственная Технологическая Академия       ///
///  По всем вопросам обращайтесь: www.contester.ru, igorklopov@yandex.ru    ///
///                                                                          ///
////////////////////////////////////////////////////////////////////////////////

// До начала работы чекера создаются три объекта -
// InputTxt, OutputTxt и PatternTxt -
// входной файл, выходной файл работы солвера и эталонный выходной файл.
// Все три - объекты класса TJudgeFile. Порядок работы с TJudgeFile и
// этими объектами прмерно таков:

// InputTxt.ReadLongInt(a);      // читает LongInt с текущей строки
//                               // если конец строки => тогда PE
//                               // если данные не являются LongInt => PE
//
// InputTxt.NextLine;            // если на этой строке еще есть данные => PE
//                               // если это последняя строка файла => PE
//                               // иначе переходит на следующую строку
//
// InputTxt.ReadLongInt(b);
//
// InputTxt.MustBeEof;           // если впереди есть данные => PE
//
// OutputTxt.ReadLongInt(s);
//
// OutputTxt.MustBeEof;          // сначала надо вычитать все данные из Output
//                               // (проверить PE), а затем уже сравнивать (WA)
//
// if a + b <> s then VRejectWA; // для вещественных используйте CompareFloats
//
// VAccept;                      // если выполнение чекера до этой строки
//                               // не прервалось на Reject, тогда Accept

// Рекомендуется проверять решения именно таким образом - сначала вычитывать
// весь InputTxt, затем весь OutputTxt. После этого вычислять и сравнивать.
// Это позволит чекерам правильно определять PE, а также поможет проверке
// самих чекеров при внесении их в систему.

// Кроме этого, в случае, когда необходино сравнить эталонный выходной файл
// с получившимся, а также когда варианты ответов будут содержать *одинаковое*
// количество строк и чисел в строках, можно воспользоваться процедурой
// CompareOutputAndPattern.

// CompareOutputAndPattern(False); // проверяет только на PE (структуру)
// CompareOutputAndPattern(True);  // проверяет и на PE и на WA
//
// VAccept;                        // если выполнение чекера до этой строки
//                                 // не прервалось на Reject, тогда Accept

unit unJudge17;

interface

// {$DEFINE DEBUG} // включить для отладки чекера, Input'ов и Pattern'ов

const
  GVerdictInternalCheckerInput          =  2;
  GVerdictInternalUnknownError          =  2;
  GVerdictRejectPresentationError       = 2;
  GVerdictRejectWrongAnswer             = 1;
  GVerdictAccept                        = 0;

  GVerdictIsReject: array[0..12] of Boolean =
   (False, False, False, False, False, True, True, True, True, True, True, True, False);

  GVerdictIsAccept: array[0..12] of Boolean =
   (False, False, False, False, False, False, False, False, False, False, False, False, True);

type
  TFileType = (ftInput, ftOutput, ftPattern);

type
  Real = Extended;

type
  TJudgeFile = class(TObject)
  private
    FType: TFileType;
    FName: String;
    FMemory: PChar;
    FSize, FPosition, FRow: Cardinal;
    FPrecision: Real;
    procedure SetSize(NewSize: Cardinal);
  protected
    function CheckBof: Boolean;
    function CheckEof: Boolean;
    function CheckLF: Boolean;
    function CheckCRLF: Boolean;
    function CheckSpace: Boolean;
    function CheckValid: Boolean;
    //
    procedure SkipSpaces;
    procedure SkipSpacesBackwards;
    //
    function FetchOneIfCan(var X: Char): Boolean;
    function FetchManyIfCan(var X: String): Boolean;
    function FetchLineIfCan(var X: String): Boolean;
  public
    constructor Create(AType: TFileType);
    destructor Destroy; override;
    procedure Reset;
    procedure Clear;
    procedure LoadFromString(S: String);
    procedure LoadFromFile(const FileName: string);
    property Precision: Real read FPrecision write FPrecision;
    property Row: Cardinal read FRow;
    //
    function Eoln: Boolean;
    function Eof: Boolean;
    function SeekEoln: Boolean;
    function SeekEof: Boolean;
    //
    procedure NextLine;
    procedure MustBeEof;
    //
    procedure ReadLine(var L: String); // вся строка до eoln
    //
    procedure ReadChar(var C: Char); overload; // один символ
    procedure ReadChar(var C1, C2: Char); overload;
    procedure ReadChar(var C1, C2, C3: Char); overload;
    procedure ReadChar(var C1, C2, C3, C4: Char); overload;
    //
    procedure ReadString(var S: String); overload; // строка до пробела
    procedure ReadString(var S1, S2: String); overload;
    procedure ReadString(var S1, S2, S3: String); overload;
    procedure ReadString(var S1, S2, S3, S4: String); overload;
    //
    procedure ReadLongInt(var I: LongInt); overload;
    procedure ReadLongInt(var I1, I2: LongInt); overload;
    procedure ReadLongInt(var I1, I2, I3: LongInt); overload;
    procedure ReadLongInt(var I1, I2, I3, I4: LongInt); overload;
    //
    procedure ReadLongWord(var W: LongWord); overload;
    procedure ReadLongWord(var W1, W2: LongWord); overload;
    procedure ReadLongWord(var W1, W2, W3: LongWord); overload;
    procedure ReadLongWord(var W1, W2, W3, W4: LongWord); overload;
    //
    procedure ReadLongLong(var N: Int64); overload;
    procedure ReadLongLong(var N1, N2: Int64); overload;
    procedure ReadLongLong(var N1, N2, N3: Int64); overload;
    procedure ReadLongLong(var N1, N2, N3, N4: Int64); overload;
    //
    procedure ReadFloat(var F: Real); overload;
    procedure ReadFloat(var F1, F2: Real); overload;
    procedure ReadFloat(var F1, F2, F3: Real); overload;
    procedure ReadFloat(var F1, F2, F3, F4: Real); overload;
    //
    function CompareFloats(F1, F2: Real): Boolean; // с учетом Precision
  end;

  // сравнивает два файла. Float'ы сравнивает с точностью OutputTxt.Precision:
  procedure CompareOutputAndPattern(AConsiderWA: Boolean);

  procedure VInternalCI(AReport: String = '');
  procedure VRejectPE(AReport: String = '');
  procedure VRejectWA(AReport: String = '');
  procedure VAccept(AReport: String = '');

////////////////////////////////////////////////////////////////////////////////
///                                                                          ///
///  Эмулятор TestLib. Отображает интерфейс класса TJudgeFile                ///
///  в стиле библиотеки TestLib для совместимости чекеров с Contester        ///
///                                                                          ///
////////////////////////////////////////////////////////////////////////////////

type
  TResult = (_OK, _WA, _PE, _FAIL, _DIRT);
  { _OK - accepted,
    _WA - wrong answer,
    _PE - output format mismatch,
    _FAIL - when everything ***** up
    _DIRT - for inner using }

  TTestLibStream = class(TObject)
  private
    FJudgeFile: TJudgeFile;
  public
    constructor Create(AJudgeFile: TJudgeFile);
    function Eof: Boolean;
    function SeekEof: Boolean;
    function Eoln: Boolean;
    function SeekEoln: Boolean;
    procedure NextLine;
    function ReadLongInt: Integer;
    function ReadLongLong: Int64;
    function ReadInteger: Integer;
    function ReadReal: Extended;
    function ReadString: string;
  end;

  procedure Quit(Res: TResult; Report: string);

var
  InputTxt: TJudgeFile;
  OutputTxt: TJudgeFile;
  PatternTxt: TJudgeFile;
  WF: TJudgeFile;
  inf: TTestLibStream;
  ouf: TTestLibStream;
  ans: TTestLibStream;

implementation

uses
{$IFDEF MSWINDOWS}
  Windows,
{$ENDIF}
{$IFDEF LINUX}
  Libc,
{$ENDIF}
  SysUtils, Classes;

{$IFDEF VER150}
  {$DEFINE VCL7ORABOVE}
{$ENDIF}
{$IFDEF VER160}
  {$DEFINE VCL7ORABOVE}
{$ENDIF}
{$IFDEF VER170}
  {$DEFINE VCL7ORABOVE}
{$ENDIF}
{$IFDEF VER180}
  {$DEFINE VCL7ORABOVE}
{$ENDIF}
{$IFDEF VER190}
  {$DEFINE VCL7ORABOVE}
{$ENDIF}

{$IFDEF DEBUG}
var
  GLastVerdict: Integer;
{$ENDIF}

procedure DropToReportTxt(Report: String);
const
  CRLF: String = #13#10;
var
  ReportTxt: TFileStream;
begin
  if FileExists('report.txt') then
    ReportTxt := TFileStream.Create('report.txt', fmOpenReadWrite)
  else ReportTxt := TFileStream.Create('report.txt', fmCreate);
  ReportTxt.Seek(0, soFromEnd);
  ReportTxt.Write(PChar(Report)^, Length(Report));
  ReportTxt.Write(PChar(CRLF)^, Length(CRLF));
  ReportTxt.Free;
end;

procedure Verdict(AVerdict: Integer; AType: TFileType; AReport: String = '');
begin
  {$IFDEF DEBUG}
  if GLastVerdict = 0 then GLastVerdict := AVerdict;
  {$ELSE}
  if GVerdictIsReject[AVerdict] and (AType in [ftInput, ftPattern]) then begin
    AVerdict := GVerdictInternalCheckerInput; // ошибка в чекере или в input.txt
  end;
  InputTxt.Free;
  OutputTxt.Free;
  PatternTxt.Free;
  if AReport <> '' then begin
    DropToReportTxt(AReport);
  end;
  Halt(AVerdict); // exit-код для передачи в Contester
  {$ENDIF}
end;

procedure VInternalCI(AReport: String = '');
begin
  Verdict(GVerdictInternalCheckerInput, ftInput, AReport);
end;

procedure VRejectPE(AReport: String = '');
begin
  Verdict(GVerdictRejectPresentationError, ftOutput, AReport);
end;

procedure VRejectWA(AReport: String = '');
begin
  Verdict(GVerdictRejectWrongAnswer, ftOutput, AReport);
end;

procedure VAccept(AReport: String = '');
begin
  Verdict(GVerdictAccept, ftOutput, AReport);
end;

function ProcessLine(var S: String; const X: String): Boolean;
begin
  Result := False;
  if Length(X) = 0 then Exit;
  S := X;
  Result := True;
end;

function ProcessChar(var C: Char; const X: Char): Boolean;
begin
  C := X;
  Result := True;
end;

function ProcessString(var S: String; const X: String): Boolean;
begin
  Result := False;
  if Length(X) = 0 then Exit;
  S := X;
  Result := True;
end;

function ProcessLongInt(var I: LongInt; const X: String): Boolean;
var
  Code: Integer;
begin
  Result := False;
  if Length(X) = 0 then Exit;
  Val(X, I, Code);
  if Code <> 0 then Exit;
  Result := True;
end;

function ProcessLongWord(var W: LongWord; const X: String): Boolean;
var
  Code: Integer;
  X64: Int64;
begin
  Result := False;
  if Length(X) = 0 then Exit;
  Val(X, X64, Code);
  if Code <> 0 then Exit;
  if X64 < 0 then Exit;
  if X64 > $FFFFFFFF then Exit;
  W := X64;
  Result := True;
end;

function ProcessLongLong(var N: Int64; const X: String): Boolean;
var
  Code: Integer;
begin
  Result := False;
  if Length(X) = 0 then Exit;
  Val(X, N, Code);
  if Code <> 0 then Exit;
  Result := True;
end;

function ProcessFloat(var F: Real; const X: String): Boolean;
var
  E: Extended;
  {$IFDEF VCL7ORABOVE}
  FS: TFormatSettings;
  {$ENDIF}
begin
  Result := False;
  if Length(X) = 0 then Exit;
  if Pos('E', X) > 0 then Exit;
  if Pos('e', X) > 0 then Exit;
  {$IFDEF VCL7ORABOVE}
  FS.DecimalSeparator := '.';
  if not TextToFloat(PChar(X), E, fvExtended, FS) then Exit;
  {$ELSE}
  if not TextToFloat(PChar(X), E, fvExtended) then Exit;
  {$ENDIF}
  F := E;
  Result := True;
end;

function RoundFloat(const F: Real; const P: Real): Real;
begin
  Result := Round(F / P) / Round(1 / P);
end;

function HashFloat(const F: Real; const P: Real): LongInt;
begin
  Result := Round(F / P);
end;

{ TJudgeFile }

constructor TJudgeFile.Create(AType: TFileType);
begin
  inherited Create;
  FType := AType;
  FName := 'TJudgeFile';
  FPrecision := 0.01;
end;

destructor TJudgeFile.Destroy;
begin
  Clear;
  inherited;
end;

procedure TJudgeFile.SetSize(NewSize: Cardinal);
begin
  if NewSize = FSize then Exit;
  if NewSize = 0 then begin
    if FSize > 0 then begin
      FreeMem(FMemory);
      FMemory := nil;
    end;
  end else begin
    if FSize > 0 then begin
      ReallocMem(FMemory, NewSize);
    end else begin
      GetMem(FMemory, NewSize)
    end;
  end;
  FSize := NewSize;
end;

procedure TJudgeFile.Reset;
begin
  FPosition := 0;
  FRow := 1;
end;

procedure TJudgeFile.Clear;
begin
  SetSize(0);
end;

procedure TJudgeFile.LoadFromString(S: String);
begin
  SetSize(Length(S));
  Move(PChar(S)[0], FMemory^, FSize);
  Reset;
end;

procedure TJudgeFile.LoadFromFile(const FileName: string);
var
  FileStream: TFileStream;
begin
  if FileExists(FileName) then
    FileStream := TFileStream.Create(FileName, fmOpenRead)
  else FileStream := TFileStream.Create(FileName, fmCreate);
  FileStream.Seek(0, 0);
  SetSize(FileStream.Size);
  FileStream.Read(FMemory^, FSize);
  FileStream.Free;
  FName := FileName;
  Reset;
end;

function TJudgeFile.CheckBof: Boolean;
begin
  Result := (FPosition = 0);
end;

function TJudgeFile.CheckEof: Boolean;
begin
  Result := (FPosition >= FSize);
end;

function TJudgeFile.CheckLF: Boolean;
begin
  Result := (FMemory[FPosition] = #10);
end;

function TJudgeFile.CheckCRLF: Boolean;
begin
  Result := (FPosition + 2 <= FSize);
  if not Result then Exit;
  Result := (FMemory[FPosition]     = #13) and
            (FMemory[FPosition + 1] = #10);
end;

function TJudgeFile.CheckSpace: Boolean;
begin
  Result := (FMemory[FPosition] = ' ');
end;

function TJudgeFile.CheckValid: Boolean;
begin
  Result := (FMemory[FPosition] >= ' ');
end;

procedure TJudgeFile.SkipSpaces;
begin
  while True do begin
    if CheckEof then Break;
    if not CheckSpace then Break;
    Inc(FPosition);
  end;
end;

procedure TJudgeFile.SkipSpacesBackwards;
begin
  while True do begin
    if CheckBof then Break;
    Dec(FPosition);
    if not CheckSpace then begin
      Inc(FPosition);
      Break;
    end;
  end;
end;

function TJudgeFile.FetchOneIfCan(var X: Char): Boolean;
begin
  SkipSpaces;
  Result := not CheckEof;
  if not Result then Exit;
  if CheckValid then begin
    X := FMemory[FPosition];
    Inc(FPosition);
    Result := True;
  end else
  begin
    Result := False;
  end;
end;

function TJudgeFile.FetchManyIfCan(var X: String): Boolean;
var
  B: Cardinal;
begin
  SkipSpaces;
  B := FPosition;
  while True do begin
    if CheckEof then Break;
    if CheckSpace or CheckLF or CheckCRLF then Break;
    if not CheckValid then Break;
    Inc(FPosition);
  end;
  if FPosition > B then begin
    SetString(X, PChar(@FMemory[B]), FPosition - B);
    Result := True;
  end else
  begin
    Result := False;
  end;
end;

function TJudgeFile.FetchLineIfCan(var X: String): Boolean;
var
  B: Cardinal;
begin
  // здесь не надо SkipSpaces;
  B := FPosition;
  while True do begin
    if CheckEof then Break;
    if CheckLF or CheckCRLF then Break;
    if not CheckValid then Break;
    Inc(FPosition);
  end;
  SkipSpacesBackwards;
  if FPosition > B then begin
    SetString(X, PChar(@FMemory[B]), FPosition - B);
    Result := True;
  end else
  begin
    Result := False;
  end;
end;

function TJudgeFile.Eoln: Boolean;
begin
  Result := not CheckEof;
  if not Result then Exit;
  Result := CheckLF or CheckCRLF;
end;

function TJudgeFile.Eof: Boolean;
begin
  Result := CheckEof;
end;

function TJudgeFile.SeekEoln: Boolean;
begin
  SkipSpaces;
  Result := not CheckEof;
  if not Result then Exit;
  Result := CheckLF or CheckCRLF;
end;

function TJudgeFile.SeekEof: Boolean;
begin
  while SeekEoln do NextLine;
  Result := CheckEof;
end;

procedure TJudgeFile.NextLine;
begin
  if not SeekEoln then Verdict(GVerdictRejectPresentationError, FType, 'eoln expected, extra data or eof found (' + FName + ', row ' + IntToStr(FRow) + ')');
  if CheckCRLF then Inc(FPosition, 2)
  else if CheckLF then Inc(FPosition);
  Inc(FRow);
end;

procedure TJudgeFile.MustBeEof;
begin
  if not SeekEof then Verdict(GVerdictRejectPresentationError, FType, 'eof expected, extra data found (' + FName + ', row ' + IntToStr(FRow) + ')');
end;

procedure TJudgeFile.ReadLine(var L: String); // вся строка до eoln
var
  X: String;
begin
  if not FetchLineIfCan(X) then Verdict(GVerdictRejectPresentationError, FType, 'line expected, something else found (' + FName + ', row ' + IntToStr(FRow) + ')');
  if not ProcessLine(L, X) then Verdict(GVerdictRejectPresentationError, FType, X + ' is not line (' + FName + ', row ' + IntToStr(FRow) + ')');
end;

procedure TJudgeFile.ReadChar(var C: Char); // один символ
var
  X: Char;
begin
  if not FetchOneIfCan(X) then Verdict(GVerdictRejectPresentationError, FType, 'char expected, something else found (' + FName + ', row ' + IntToStr(FRow) + ')');
  if not ProcessChar(C, X) then Verdict(GVerdictRejectPresentationError, FType, X + ' is not char (' + FName + ', row ' + IntToStr(FRow) + ')');
end;

procedure TJudgeFile.ReadChar(var C1, C2: Char);
begin
  ReadChar(C1);
  ReadChar(C2);
end;

procedure TJudgeFile.ReadChar(var C1, C2, C3: Char);
begin
  ReadChar(C1, C2);
  ReadChar(C3);
end;

procedure TJudgeFile.ReadChar(var C1, C2, C3, C4: Char);
begin
  ReadChar(C1, C2);
  ReadChar(C3, C4);
end;

procedure TJudgeFile.ReadString(var S: String); // строка до пробела
var
  X: String;
begin
  if not FetchManyIfCan(X) then Verdict(GVerdictRejectPresentationError, FType, 'string expected, something else found (' + FName + ', row ' + IntToStr(FRow) + ')');
  if not ProcessString(S, X) then Verdict(GVerdictRejectPresentationError, FType, X + ' is not string (' + FName + ', row ' + IntToStr(FRow) + ')');
end;

procedure TJudgeFile.ReadString(var S1, S2: String);
begin
  ReadString(S1);
  ReadString(S2);
end;

procedure TJudgeFile.ReadString(var S1, S2, S3: String);
begin
  ReadString(S1, S2);
  ReadString(S3);
end;

procedure TJudgeFile.ReadString(var S1, S2, S3, S4: String);
begin
  ReadString(S1, S2);
  ReadString(S3, S4);
end;

procedure TJudgeFile.ReadLongInt(var I: LongInt);
var
  X: String;
begin
  if not FetchManyIfCan(X) then Verdict(GVerdictRejectPresentationError, FType, 'longint expected, something else found (' + FName + ', row ' + IntToStr(FRow) + ')');
  if not ProcessLongInt(I, X) then Verdict(GVerdictRejectPresentationError, FType, X + ' is not longint (' + FName + ', row ' + IntToStr(FRow) + ')');
end;

procedure TJudgeFile.ReadLongInt(var I1, I2: LongInt);
begin
  ReadLongInt(I1);
  ReadLongInt(I2);
end;

procedure TJudgeFile.ReadLongInt(var I1, I2, I3: LongInt);
begin
  ReadLongInt(I1, I2);
  ReadLongInt(I3);
end;

procedure TJudgeFile.ReadLongInt(var I1, I2, I3, I4: LongInt);
begin
  ReadLongInt(I1, I2);
  ReadLongInt(I3, I4);
end;

procedure TJudgeFile.ReadLongWord(var W: LongWord);
var
  X: String;
begin
  if not FetchManyIfCan(X) then Verdict(GVerdictRejectPresentationError, FType, 'longword expected, something else found (' + FName + ', row ' + IntToStr(FRow) + ')');
  if not ProcessLongWord(W, X) then Verdict(GVerdictRejectPresentationError, FType, X + ' is not longword (' + FName + ', row ' + IntToStr(FRow) + ')');
end;

procedure TJudgeFile.ReadLongWord(var W1, W2: LongWord);
begin
  ReadLongWord(W1);
  ReadLongWord(W2);
end;

procedure TJudgeFile.ReadLongWord(var W1, W2, W3: LongWord);
begin
  ReadLongWord(W1, W2);
  ReadLongWord(W3);
end;

procedure TJudgeFile.ReadLongWord(var W1, W2, W3, W4: LongWord);
begin
  ReadLongWord(W1, W2);
  ReadLongWord(W3, W4);
end;

procedure TJudgeFile.ReadLongLong(var N: Int64);
var
  X: String;
begin
  if not FetchManyIfCan(X) then Verdict(GVerdictRejectPresentationError, FType, 'longlong expected, something else found (' + FName + ', row ' + IntToStr(FRow) + ')');
  if not ProcessLongLong(N, X) then Verdict(GVerdictRejectPresentationError, FType, X + ' is not longlong (' + FName + ', row ' + IntToStr(FRow) + ')');
end;

procedure TJudgeFile.ReadLongLong(var N1, N2: Int64);
begin
  ReadLongLong(N1);
  ReadLongLong(N2);
end;

procedure TJudgeFile.ReadLongLong(var N1, N2, N3: Int64);
begin
  ReadLongLong(N1, N2);
  ReadLongLong(N3);
end;

procedure TJudgeFile.ReadLongLong(var N1, N2, N3, N4: Int64);
begin
  ReadLongLong(N1, N2);
  ReadLongLong(N3, N4);
end;

procedure TJudgeFile.ReadFloat(var F: Real);
var
  X: String;
begin
  if not FetchManyIfCan(X) then Verdict(GVerdictRejectPresentationError, FType, 'float expected, something else found (' + FName + ', row ' + IntToStr(FRow) + ')');
  if not ProcessFloat(F, X) then Verdict(GVerdictRejectPresentationError, FType, X + ' is not float (' + FName + ', row ' + IntToStr(FRow) + ')');
  F := RoundFloat(F, Precision);
end;

procedure TJudgeFile.ReadFloat(var F1, F2: Real);
begin
  ReadFloat(F1);
  ReadFloat(F2);
end;

procedure TJudgeFile.ReadFloat(var F1, F2, F3: Real);
begin
  ReadFloat(F1, F2);
  ReadFloat(F3);
end;

procedure TJudgeFile.ReadFloat(var F1, F2, F3, F4: Real);
begin
  ReadFloat(F1, F2, F3);
  ReadFloat(F4);
end;

function TJudgeFile.CompareFloats(F1, F2: Real): Boolean;
begin
  Result := (HashFloat(F1, Precision) = HashFloat(F2, Precision));
end;

procedure CompareOutputAndPattern(AConsiderWA: Boolean);
var
  DidPat, DidOut: Boolean;
  PatX, OutX: String;
  PatS, OutS: String;
  PatN, OutN: Int64;
  PatI, OutI: LongInt;
  PatW, OutW: LongWord;
  PatF, OutF: Real;
begin
  PatternTxt.Reset;
  OutputTxt.Reset;
  while True do begin
    DidPat := PatternTxt.FetchManyIfCan(PatX);
    DidOut := OutputTxt.FetchManyIfCan(OutX);
    //
    if DidPat and DidOut then begin
      if not AConsiderWA then begin
        Continue;
      end else
      if ProcessLongLong(PatN, PatX) and ProcessLongLong(OutN, OutX) then begin
        if (PatN <> OutN) then begin
          Verdict(GVerdictRejectWrongAnswer, ftOutput);
          Break;
        end;
      end else
      if ProcessLongInt(PatI, PatX) and ProcessLongInt(OutI, OutX) then begin
        if (PatI <> OutI) then begin
          Verdict(GVerdictRejectWrongAnswer, ftOutput);
          Break;
        end;
      end else
      if ProcessLongWord(PatW, PatX) and ProcessLongWord(OutW, OutX) then begin
        if (PatW <> OutW) then begin
          Verdict(GVerdictRejectWrongAnswer, ftOutput);
          Break;
        end;
      end else
      if ProcessFloat(PatF, PatX) and ProcessFloat(OutF, OutX) then begin
        if (not OutputTxt.CompareFloats(PatF, OutF)) then begin
          Verdict(GVerdictRejectWrongAnswer, ftOutput);
          Break;
        end;
      end else
      if ProcessString(PatS, PatX) and ProcessString(OutS, OutX) then begin
        if (PatS <> OutS) then begin
          Verdict(GVerdictRejectWrongAnswer, ftOutput);
          Break;
        end;
      end else
      begin
        Verdict(GVerdictRejectPresentationError, ftOutput);
        Break; // оба Fetch удались, но Process не сработал
      end;
      Continue;
    end;
    //
    if DidPat or DidOut then begin // один из Fetch не удался
      Verdict(GVerdictRejectPresentationError, ftOutput);
      Break;
    end;
    //
    DidPat := PatternTxt.SeekEoln;
    DidOut := OutputTxt.SeekEoln;
    if DidPat then PatternTxt.NextLine;
    if DidOut then OutputTxt.NextLine;
    if DidPat and DidOut then begin
      Continue;
    end;
    //
    if PatternTxt.Eof and OutputTxt.Eof then begin
      // VAccept вызывай снаружи
      Break;
    end;
    //
    if PatternTxt.SeekEoln then PatternTxt.NextLine;
    if OutputTxt.SeekEoln then OutputTxt.NextLine;
    //
    if PatternTxt.Eof and OutputTxt.Eof then begin
      // VAccept вызывай снаружи
      Break;
    end;
    //
    Verdict(GVerdictRejectPresentationError, ftOutput);
    Break;
  end;
end;

{$IFDEF DEBUG}

procedure TestJudgeFile;
var
  OutF: TJudgeFile;
  L, S: String;
  C: Char;
  I: LongInt;
  W: LongWord;
  N: Int64;
  F: Real;
begin
  OutF := TJudgeFile.Create(ftOutput);
  OutF.Precision := 0.01;

  ////////////////////////////// тест A0
  GLastVerdict := 0;
  OutF.LoadFromString(
  '');

  OutF.ReadString(S);
  Assert(S = '');

  GLastVerdict := 0;
  OutF.LoadFromString(
  '');

  OutF.ReadLine(L);
  Assert(L = '');

  GLastVerdict := 0;
  OutF.LoadFromString(
  '  '                     + #13#10);

  OutF.ReadString(S);
  Assert(S = '');

  GLastVerdict := 0;
  OutF.LoadFromString(
  '  '                     + #13#10);

  OutF.ReadLine(L);
  Assert(L = '');

  ////////////////////////////// тест A1
  GLastVerdict := 0;
  OutF.LoadFromString(
  '  45  348 '             + #13#10 +
  '23 54'                  + #13#10 +
  '    46                ' + #13#10 +
  '1'                      + #13#10);


  Assert(OutF.SeekEoln = False);
  Assert(OutF.SeekEoln = False);
  OutF.ReadLine(L);
  Assert(L = '45  348');

  Assert(OutF.SeekEoln = True);
  Assert(OutF.SeekEoln = True); OutF.NextLine;
  OutF.ReadLine(L);
  Assert(L = '23 54');

  Assert(OutF.SeekEoln = True);
  Assert(OutF.SeekEoln = True); OutF.NextLine;
  OutF.ReadLine(L);
  Assert(L = '    46');

  Assert(OutF.SeekEoln = True);
  Assert(OutF.SeekEoln = True); OutF.NextLine;
  OutF.ReadLine(L);
  Assert(L = '1');

  Assert(OutF.Eof = False);
  Assert(OutF.SeekEoln = True);
  Assert(OutF.SeekEoln = True); OutF.NextLine;

  Assert(OutF.Eof = True);
  Assert(OutF.SeekEof = True);
  Assert(OutF.SeekEoln = False);
  Assert(OutF.SeekEoln = False);

  Assert(OutF.Eof = True);
  Assert(OutF.SeekEof = True);
  Assert(OutF.SeekEoln = False);
  Assert(OutF.SeekEoln = False);

  Assert(GLastVerdict = 0);

  ////////////////////////////// тест A2
  GLastVerdict := 0;
  OutF.LoadFromString(
  '  45  348 '             + #13#10 +
  '23 54'                  + #13#10 +
  '    46                ' + #13#10 +
  '1'                      + #13#10);

  Assert(OutF.SeekEoln = False);
  Assert(OutF.SeekEoln = False);
  OutF.ReadChar(C);
  Assert(C = '4');

  Assert(OutF.SeekEoln = False);
  Assert(OutF.SeekEoln = False);
  OutF.ReadChar(C);
  Assert(C = '5');

  Assert(OutF.SeekEoln = False);
  Assert(OutF.SeekEoln = False);
  OutF.ReadChar(C);
  Assert(C = '3');

  Assert(OutF.SeekEoln = False);
  Assert(OutF.SeekEoln = False);
  OutF.ReadChar(C);
  Assert(C = '4');

  Assert(OutF.SeekEoln = False);
  Assert(OutF.SeekEoln = False);
  OutF.ReadChar(C);
  Assert(C = '8');

  Assert(OutF.SeekEoln = True);
  Assert(OutF.SeekEoln = True); OutF.NextLine;
  OutF.ReadChar(C);
  Assert(C = '2');

  Assert(OutF.SeekEoln = False);
  Assert(OutF.SeekEoln = False);
  OutF.ReadChar(C);
  Assert(C = '3');

  Assert(OutF.SeekEoln = False);
  Assert(OutF.SeekEoln = False);
  OutF.ReadChar(C);
  Assert(C = '5');

  Assert(OutF.SeekEoln = False);
  Assert(OutF.SeekEoln = False);
  OutF.ReadChar(C);
  Assert(C = '4');

  Assert(OutF.SeekEoln = True);
  Assert(OutF.SeekEoln = True); OutF.NextLine;
  OutF.ReadChar(C);
  Assert(C = '4');

  Assert(OutF.SeekEoln = False);
  Assert(OutF.SeekEoln = False);
  OutF.ReadChar(C);
  Assert(C = '6');

  Assert(OutF.SeekEoln = True);
  Assert(OutF.SeekEoln = True); OutF.NextLine;
  OutF.ReadChar(C);
  Assert(C = '1');

  Assert(OutF.SeekEoln = True);
  Assert(OutF.SeekEoln = True); OutF.NextLine;

  Assert(OutF.SeekEof = True);
  Assert(OutF.SeekEoln = False);
  Assert(OutF.SeekEoln = False);

  Assert(OutF.SeekEof = True);
  Assert(OutF.SeekEoln = False);
  Assert(OutF.SeekEoln = False);

  Assert(GLastVerdict = 0);

  ////////////////////////////// тест A3
  GLastVerdict := 0;
  OutF.LoadFromString(
  '  45  348 '             + #13#10 +
  '23 54'                  + #13#10 +
  '    46                ' + #13#10 +
  '1'                      + #13#10);


  Assert(OutF.SeekEoln = False);
  Assert(OutF.SeekEoln = False);
  OutF.ReadString(S);
  Assert(S = '45');

  Assert(OutF.SeekEoln = False);
  Assert(OutF.SeekEoln = False);
  OutF.ReadString(S);
  Assert(S = '348');

  Assert(OutF.SeekEoln = True);
  Assert(OutF.SeekEoln = True); OutF.NextLine;
  OutF.ReadString(S);
  Assert(S = '23');

  Assert(OutF.SeekEoln = False);
  Assert(OutF.SeekEoln = False);
  OutF.ReadString(S);
  Assert(S = '54');

  Assert(OutF.SeekEoln = True);
  Assert(OutF.SeekEoln = True); OutF.NextLine;
  OutF.ReadString(S);
  Assert(S = '46');

  Assert(OutF.SeekEoln = True);
  Assert(OutF.SeekEoln = True); OutF.NextLine;
  OutF.ReadString(S);
  Assert(S = '1');

  Assert(OutF.SeekEoln = True);
  Assert(OutF.SeekEoln = True); OutF.NextLine;

  Assert(OutF.SeekEof = True);
  Assert(OutF.SeekEoln = False);
  Assert(OutF.SeekEoln = False);

  Assert(OutF.SeekEof = True);
  Assert(OutF.SeekEoln = False);
  Assert(OutF.SeekEoln = False);

  Assert(GLastVerdict = 0);

  ////////////////////////////// тест A4
  GLastVerdict := 0;
  OutF.LoadFromString(
  '  45  348 '             + #13#10 +
  '23 54'                  + #13#10 +
  '    46                ' + #13#10 +
  '1'                      + #13#10);

  Assert(OutF.SeekEoln = False);
  OutF.ReadLongInt(I);
  Assert(I = 45);

  Assert(OutF.SeekEoln = False);
  OutF.ReadLongInt(I);
  Assert(I = 348);

  Assert(OutF.SeekEoln = True); OutF.NextLine;
  OutF.ReadLongInt(I);
  Assert(I = 23);

  Assert(OutF.SeekEoln = False);
  OutF.ReadLongInt(I);
  Assert(I = 54);

  Assert(OutF.SeekEoln = True); OutF.NextLine;
  OutF.ReadLongInt(I);
  Assert(I = 46);

  Assert(OutF.SeekEoln = True); OutF.NextLine;
  OutF.ReadLongInt(I);
  Assert(I = 1);

  Assert(OutF.SeekEoln = True); OutF.NextLine;

  Assert(OutF.SeekEoln = False);

  Assert(OutF.SeekEoln = False);

  Assert(GLastVerdict = 0);

  ////////////////////////////// тест A5
  GLastVerdict := 0;
  OutF.LoadFromString(
  '  45  348 '             + #13#10 +
  '23 54'                  + #13#10 +
  '    46                ' + #13#10 +
  '1'                      + #13#10);

  Assert(OutF.SeekEoln = False);
  OutF.ReadLongWord(W);
  Assert(W = 45);

  Assert(OutF.SeekEoln = False);
  OutF.ReadLongWord(W);
  Assert(W = 348);

  Assert(OutF.SeekEoln = True); OutF.NextLine;
  OutF.ReadLongWord(W);
  Assert(W = 23);

  Assert(OutF.SeekEoln = False);
  OutF.ReadLongWord(W);
  Assert(W = 54);

  Assert(OutF.SeekEoln = True); OutF.NextLine;
  OutF.ReadLongWord(W);
  Assert(W = 46);

  Assert(OutF.SeekEoln = True); OutF.NextLine;
  OutF.ReadLongWord(W);
  Assert(W = 1);

  Assert(OutF.SeekEoln = True); OutF.NextLine;

  Assert(OutF.SeekEoln = False);

  Assert(OutF.SeekEoln = False);

  Assert(GLastVerdict = 0);

  ////////////////////////////// тест A6
  GLastVerdict := 0;
  OutF.LoadFromString(
  '  45.7422  348.169 '    + #13#10 +
  '23.170 54.174'          + #13#10 +
  '    46.175            ' + #13#10 +
  '1.176'                  + #13#10);

  Assert(OutF.SeekEoln = False);
  OutF.ReadFloat(F);
  Assert(F = 45.74);

  Assert(OutF.SeekEoln = False);
  OutF.ReadFloat(F);
  Assert(F = 348.17);

  Assert(OutF.SeekEoln = True); OutF.NextLine;
  OutF.ReadFloat(F);
  Assert(F = 23.17);

  Assert(OutF.SeekEoln = False);
  OutF.ReadFloat(F);
  Assert(F = 54.17);

  Assert(OutF.SeekEoln = True); OutF.NextLine;
  OutF.ReadFloat(F);
  Assert(F = 46.18);

  Assert(OutF.SeekEoln = True); OutF.NextLine;
  OutF.ReadFloat(F);
  Assert(F = 1.18);

  Assert(OutF.SeekEoln = True); OutF.NextLine;

  Assert(OutF.SeekEoln = False);

  Assert(OutF.SeekEoln = False);

  Assert(GLastVerdict = 0);

  ////////////////////////////// тест BX1
  GLastVerdict := 0;
  OutF.LoadFromString(
  '0'                      + #13#10 +
  '0'                      + #13#10 +
  '0'                      + #13#10 +
  '0'                      + #13#10);

  Assert(OutF.SeekEoln = False);
  OutF.ReadLongLong(N);
  Assert(N = 0);
  Assert(GLastVerdict = 0);

  Assert(OutF.SeekEoln = True); OutF.NextLine;
  OutF.ReadLongWord(W);
  Assert(W = 0);
  Assert(GLastVerdict = 0);

  Assert(OutF.SeekEoln = True); OutF.NextLine;
  OutF.ReadLongInt(I);
  Assert(I = 0);
  Assert(GLastVerdict = 0);

  ////////////////////////////// тест BX2
  GLastVerdict := 0;
  OutF.LoadFromString(
  '123'                    + #13#10 +
  '234'                    + #13#10 +
  '345'                    + #13#10 +
  '456'                    + #13#10);

  Assert(OutF.SeekEoln = False);
  OutF.ReadLongLong(N);
  Assert(N = 123);
  Assert(GLastVerdict = 0);

  Assert(OutF.SeekEoln = True); OutF.NextLine;
  OutF.ReadLongWord(W);
  Assert(W = 234);
  Assert(GLastVerdict = 0);

  Assert(OutF.SeekEoln = True); OutF.NextLine;
  OutF.ReadLongInt(I);
  Assert(I = 345);
  Assert(GLastVerdict = 0);

  ////////////////////////////// тест BX3
  GLastVerdict := 0;
  OutF.LoadFromString(
  '2147483643'             + #13#10 +
  '2147483643'             + #13#10 +
  '2147483643'             + #13#10 +
  '4294967231'             + #13#10 +
  '4294967231'             + #13#10 +
  '4294967231'             + #13#10);

  Assert(OutF.SeekEoln = False);
  OutF.ReadLongLong(N);
  Assert(N = 2147483643);
  Assert(GLastVerdict = 0);

  Assert(OutF.SeekEoln = True); OutF.NextLine;
  OutF.ReadLongWord(W);
  Assert(W = 2147483643);
  Assert(GLastVerdict = 0);

  Assert(OutF.SeekEoln = True); OutF.NextLine;
  OutF.ReadLongInt(I);
  Assert(I = 2147483643);
  Assert(GLastVerdict = 0);

  Assert(OutF.SeekEoln = True); OutF.NextLine;
  OutF.ReadLongLong(N);
  Assert(N = 4294967231);
  Assert(GLastVerdict = 0);

  Assert(OutF.SeekEoln = True); OutF.NextLine;
  OutF.ReadLongWord(W);
  Assert(W = 4294967231);
  Assert(GLastVerdict = 0);

  Assert(OutF.SeekEoln = True); OutF.NextLine;
  OutF.ReadLongInt(I);
  Assert(GLastVerdict = GVerdictRejectPresentationError);

  ////////////////////////////// тест BX4
  GLastVerdict := 0;
  OutF.LoadFromString(
  '4294969999'             + #13#10);

  Assert(OutF.SeekEoln = False);
  OutF.ReadLongLong(N);
  Assert(N = 4294969999);
  Assert(GLastVerdict = 0);

  ////////////////////////////// тест BX5
  GLastVerdict := 0;
  OutF.LoadFromString(
  '4294969999'             + #13#10);

  Assert(OutF.SeekEoln = False);
  OutF.ReadLongWord(W);
  Assert(GLastVerdict = GVerdictRejectPresentationError);

  ////////////////////////////// тест BX6
  GLastVerdict := 0;
  OutF.LoadFromString(
  '4294969999'             + #13#10);

  Assert(OutF.SeekEoln = False);
  OutF.ReadLongInt(I);
  Assert(GLastVerdict = GVerdictRejectPresentationError);

  ////////////////////////////// тест BX7
  GLastVerdict := 0;
  OutF.LoadFromString(
  '9223379999999999999'    + #13#10);

  Assert(OutF.SeekEoln = False);
  OutF.ReadLongLong(N);
  Assert(GLastVerdict = GVerdictRejectPresentationError);

  ////////////////////////////// тест BX8
  GLastVerdict := 0;
  OutF.LoadFromString(
  '9223379999999999999'    + #13#10);

  Assert(OutF.SeekEoln = False);
  OutF.ReadLongWord(W);
  Assert(GLastVerdict = GVerdictRejectPresentationError);

  ////////////////////////////// тест BX9
  GLastVerdict := 0;
  OutF.LoadFromString(
  '9223379999999999999'    + #13#10);

  Assert(OutF.SeekEoln = False);
  OutF.ReadLongInt(I);
  Assert(GLastVerdict = GVerdictRejectPresentationError);

  ////////////////////////////// тест BX10
  GLastVerdict := 0;
  OutF.LoadFromString(
  '-2147483643'            + #13#10);

  Assert(OutF.SeekEoln = False);
  OutF.ReadLongLong(N);
  Assert(N = -2147483643);
  Assert(GLastVerdict = 0);

  ////////////////////////////// тест BX11
  GLastVerdict := 0;
  OutF.LoadFromString(
  '-2147483643'            + #13#10);

  Assert(OutF.SeekEoln = False);
  OutF.ReadLongWord(W);
  Assert(GLastVerdict = GVerdictRejectPresentationError);

  ////////////////////////////// тест BX12
  GLastVerdict := 0;
  OutF.LoadFromString(
  '-2147483643'            + #13#10);

  Assert(OutF.SeekEoln = False);
  OutF.ReadLongInt(I);
  Assert(I = -2147483643);
  Assert(GLastVerdict = 0);

  ////////////////////////////// тест BX13
  GLastVerdict := 0;
  OutF.LoadFromString(
  '-429496723'            + #13#10);

  Assert(OutF.SeekEoln = False);
  OutF.ReadLongLong(N);
  Assert(N = -429496723);
  Assert(GLastVerdict = 0);

  ////////////////////////////// тест BX14
  GLastVerdict := 0;
  OutF.LoadFromString(
  '-4294967231'            + #13#10);

  Assert(OutF.SeekEoln = False);
  OutF.ReadLongWord(W);
  Assert(GLastVerdict = GVerdictRejectPresentationError);

  ////////////////////////////// тест BX15
  GLastVerdict := 0;
  OutF.LoadFromString(
  '-4294967231'            + #13#10);

  Assert(OutF.SeekEoln = False);
  OutF.ReadLongInt(I);
  Assert(GLastVerdict = GVerdictRejectPresentationError);

  ////////////////////////////// тест BX16
  GLastVerdict := 0;
  OutF.LoadFromString(
  '-4294969999'            + #13#10);

  Assert(OutF.SeekEoln = False);
  OutF.ReadLongLong(N);
  Assert(N = -4294969999);
  Assert(GLastVerdict = 0);

  ////////////////////////////// тест BX17
  GLastVerdict := 0;
  OutF.LoadFromString(
  '-4294969999'            + #13#10);

  Assert(OutF.SeekEoln = False);
  OutF.ReadLongWord(W);
  Assert(GLastVerdict = GVerdictRejectPresentationError);

  ////////////////////////////// тест BX18
  GLastVerdict := 0;
  OutF.LoadFromString(
  '-4294969999'            + #13#10);
  OutF.ReadLongInt(I);
  Assert(GLastVerdict = GVerdictRejectPresentationError);

  ////////////////////////////// тест BX19
  GLastVerdict := 0;
  OutF.LoadFromString(
  '-9223379999999999999'   + #13#10);

  Assert(OutF.SeekEoln = False);
  OutF.ReadLongLong(N);
  Assert(GLastVerdict = GVerdictRejectPresentationError);

  ////////////////////////////// тест BX20
  GLastVerdict := 0;
  OutF.LoadFromString(
  '-9223379999999999999'   + #13#10);

  Assert(OutF.SeekEoln = False);
  OutF.ReadLongWord(W);
  Assert(GLastVerdict = GVerdictRejectPresentationError);

  ////////////////////////////// тест BX21
  GLastVerdict := 0;
  OutF.LoadFromString(
  '-9223379999999999999'   + #13#10);

  Assert(OutF.SeekEoln = False);
  OutF.ReadLongInt(I);
  Assert(GLastVerdict = GVerdictRejectPresentationError);

  ////////////////////////////// тест C1
  GLastVerdict := 0;
  OutF.LoadFromString(
  '  45.7422  348.169 '    + #10    +
  '23.170 54.174'          + #13    +
  '    46.175            ' + #13#10 +
  '1.176'                  + #13#10);

  Assert(OutF.SeekEoln = False);
  OutF.ReadFloat(F);
  Assert(F = 45.74);
  Assert(GLastVerdict = 0);

  Assert(OutF.SeekEoln = False);
  OutF.ReadFloat(F);
  Assert(F = 348.17);
  Assert(GLastVerdict = 0);

  Assert(OutF.SeekEoln = True); OutF.NextLine;
  OutF.ReadFloat(F);
  Assert(F = 23.17);
  Assert(GLastVerdict = 0);

  Assert(OutF.SeekEoln = False);
  OutF.ReadFloat(F);
  Assert(F = 54.17);
  Assert(GLastVerdict = 0);

  Assert(OutF.SeekEoln = False);
  OutF.NextLine;
  Assert(GLastVerdict = GVerdictRejectPresentationError);

  ////////////////////////////// тест C2
  GLastVerdict := 0;
  OutF.LoadFromString(
  '214748'#3'3643'          + #13#10);

  Assert(OutF.SeekEoln = False);
  OutF.ReadLongInt(I);
  Assert(I = 214748);
  Assert(GLastVerdict = 0);

  Assert(OutF.SeekEoln = False);
  OutF.ReadLongWord(W);
  Assert(GLastVerdict = GVerdictRejectPresentationError);

  DropToReportTxt('JudgeFile tests passed!'); // все тесты должны проходить удачно
end;

procedure TestCompare;
var
  OutSF: TJudgeFile;
  PatSF: TJudgeFile;
begin
  OutSF := OutputTxt;
  OutputTxt := TJudgeFile.Create(ftOutput);
  OutputTxt.Precision := 0.01;
  PatSF := PatternTxt;
  PatternTxt := TJudgeFile.Create(ftPattern);
  PatternTxt.Precision := 0.01;

  ////////////////////////////// тест A1
  GLastVerdict := 0;
  OutputTxt.LoadFromString(
  '  45  348 '             + #13#10 +
  '23 54'                  + #13#10 +
  '    46                ' + #13#10 +
  '1'                      + #13#10);
  PatternTxt.LoadFromString(
  '  45  348 '             + #13#10 +
  '23 54'                  + #13#10 +
  '    46                ' + #13#10 +
  '1'                      + #13#10);
  CompareOutputAndPattern(False);
  Assert(GLastVerdict = 0);
  CompareOutputAndPattern(True);
  Assert(GLastVerdict = 0);

  ////////////////////////////// тест A2
  GLastVerdict := 0;
  OutputTxt.LoadFromString(
  '  45  348 '             + #13#10 +
  '23 54'                  + #13#10 +
  '    46                ' + #13#10 +
  '1'                      + #13#10);
  PatternTxt.LoadFromString(
  '45  348'                + #13#10 +
  '  23 54 '               + #13#10 +
  '46'                     + #13#10 +
  '   1       '            + #13#10);
  CompareOutputAndPattern(False);
  Assert(GLastVerdict = 0);
  CompareOutputAndPattern(True);
  Assert(GLastVerdict = 0);

  ////////////////////////////// тест A3
  GLastVerdict := 0;
  OutputTxt.LoadFromString(
  '  45  348 '             + #13#10 +
  '23 54'                  + #13#10 +
  '    46                ' + #13#10 +
  '1'                      + #13#10);
  PatternTxt.LoadFromString(
  '45  348'                + #13#10 +
  '  23 54 '               + #13#10 +
  '46'                     + #13#10 +
  '   1       '            + #13#10);
  CompareOutputAndPattern(False);
  Assert(GLastVerdict = 0);
  CompareOutputAndPattern(True);
  Assert(GLastVerdict = 0);

  ////////////////////////////// тест A4
  GLastVerdict := 0;
  OutputTxt.LoadFromString(
  '  45  348  77 '         + #13#10 +
  '23 54'                  + #13#10 +
  '    46                ' + #13#10 +
  '1'                      + #13#10);
  PatternTxt.LoadFromString(
  '45  348'                + #13#10 +
  '  23 54 '               + #13#10 +
  '46'                     + #13#10 +
  '   1       '            + #13#10);
  CompareOutputAndPattern(False);
  Assert(GLastVerdict = GVerdictRejectPresentationError);
  CompareOutputAndPattern(True);
  Assert(GLastVerdict = GVerdictRejectPresentationError);

  ////////////////////////////// тест A5
  GLastVerdict := 0;
  OutputTxt.LoadFromString(
  '  45  348 '             + #13#10 +
  '23 54'                  + #13#10 +
  '    46                ' + #13#10 +
  '1'                      + #13#10);
  PatternTxt.LoadFromString(
  '45  348  77'            + #13#10 +
  '  23 54 '               + #13#10 +
  '46'                     + #13#10 +
  '   1       '            + #13#10);
  CompareOutputAndPattern(False);
  Assert(GLastVerdict = GVerdictRejectPresentationError);
  CompareOutputAndPattern(True);
  Assert(GLastVerdict = GVerdictRejectPresentationError);

  ////////////////////////////// тест A6
  GLastVerdict := 0;
  OutputTxt.LoadFromString(
  '  45  348 B'            + #13#10 +
  '23 54'                  + #13#10 +
  '    46   7.234        ' + #13#10 +
  '1'                      + #13#10);
  PatternTxt.LoadFromString(
  '45  348              B' + #13#10 +
  '  23 54 '               + #13#10 +
  '46 7.229'               + #13#10 +
  '   1       '            + #13#10);
  CompareOutputAndPattern(False);
  Assert(GLastVerdict = 0);
  CompareOutputAndPattern(True);
  Assert(GLastVerdict = 0);

  ////////////////////////////// тест A7
  GLastVerdict := 0;
  OutputTxt.LoadFromString(
  '  45  348 B'            + #13#10 +
  '23 54'                  + #13#10 +
  '    46   7.234        ' + #13#10 +
  '1'                      + #13#10);
  PatternTxt.LoadFromString(
  '45  348              C' + #13#10 +
  '  23 54 '               + #13#10 +
  '46 7.229'               + #13#10 +
  '   1       '            + #13#10);
  CompareOutputAndPattern(False);
  Assert(GLastVerdict = 0);
  CompareOutputAndPattern(True);
  Assert(GLastVerdict = GVerdictRejectWrongAnswer);

  ////////////////////////////// тест A8
  GLastVerdict := 0;
  OutputTxt.LoadFromString(
  '  45  348 B'            + #13#10 +
  '23 54'                  + #13#10 +
  '    46   7.234        ' + #13#10 +
  '1'                      + #13#10);
  PatternTxt.LoadFromString(
  '45  348              B' + #13#10 +
  '  23 54 '               + #13#10 +
  '46 7.224'               + #13#10 +
  '   1       '            + #13#10);
  CompareOutputAndPattern(False);
  Assert(GLastVerdict = 0);
  CompareOutputAndPattern(True);
  Assert(GLastVerdict = GVerdictRejectWrongAnswer);

  ////////////////////////////// тест A9
  GLastVerdict := 0;
  OutputTxt.LoadFromString(
  '  45  348      B '      + #13#10 +
  '23 54'                  + #13#10 +
  '    46                ' + #13#10 +
  '1'                      + #13#10);
  PatternTxt.LoadFromString(
  '45  348'                + #13#10 +
  '  23 54 '               + #13#10 +
  '46'                     + #13#10 +
  '   1       '            + #13#10);
  CompareOutputAndPattern(False);
  Assert(GLastVerdict = GVerdictRejectPresentationError);
  CompareOutputAndPattern(True);
  Assert(GLastVerdict = GVerdictRejectPresentationError);

  ////////////////////////////// тест A10
  GLastVerdict := 0;
  OutputTxt.LoadFromString(
  '  45  348      '        + #13#10 +
  '23 54'                  + #13#10 +
  '    46                ' + #13#10 +
  '1'                      + #13#10);
  PatternTxt.LoadFromString(
  '45  348              B' + #13#10 +
  '  23 54 '               + #13#10 +
  '46'                     + #13#10 +
  '   1       '            + #13#10);
  CompareOutputAndPattern(False);
  Assert(GLastVerdict = GVerdictRejectPresentationError);
  CompareOutputAndPattern(True);
  Assert(GLastVerdict = GVerdictRejectPresentationError);

  ////////////////////////////// тест B1
  GLastVerdict := 0;
  OutputTxt.LoadFromString(
  '45'                     + #13#10 +
                             #13#10);
  PatternTxt.LoadFromString(
  '45'                             );
  CompareOutputAndPattern(False);
  Assert(GLastVerdict = 0);
  CompareOutputAndPattern(True);
  Assert(GLastVerdict = 0);

  ////////////////////////////// тест B2
  GLastVerdict := 0;
  OutputTxt.LoadFromString(
  '45'                             );
  PatternTxt.LoadFromString(
  '45'                     + #13#10 +
                             #13#10);
  CompareOutputAndPattern(False);
  Assert(GLastVerdict = 0);
  CompareOutputAndPattern(True);
  Assert(GLastVerdict = 0);

  ////////////////////////////// тест B3
  GLastVerdict := 0;
  OutputTxt.LoadFromString(
  '45'                     + #13#10 +
                             #13#10 +
                             #13#10);
  PatternTxt.LoadFromString(
  '45'                             );
  CompareOutputAndPattern(False);
  Assert(GLastVerdict = GVerdictRejectPresentationError);
  CompareOutputAndPattern(True);
  Assert(GLastVerdict = GVerdictRejectPresentationError);

  ////////////////////////////// тест B4
  GLastVerdict := 0;
  OutputTxt.LoadFromString(
  '45'                             );
  PatternTxt.LoadFromString(
  '45'                     + #13#10 +
                             #13#10 +
                             #13#10);
  CompareOutputAndPattern(False);
  Assert(GLastVerdict = GVerdictRejectPresentationError);
  CompareOutputAndPattern(True);
  Assert(GLastVerdict = GVerdictRejectPresentationError);

  DropToReportTxt('Compare tests passed!'); // все тесты должны проходить удачно

  OutputTxt := OutSF;
  PatternTxt := PatSF;
end;

{$ENDIF}

{ TTestLibStream }

constructor TTestLibStream.Create(AJudgeFile: TJudgeFile);
begin
  inherited Create;
  FJudgeFile := AJudgeFile;
end;

function TTestLibStream.Eof: Boolean;
begin
  Result := FJudgeFile.Eof;
end;

function TTestLibStream.SeekEof: Boolean;
begin
  Result := FJudgeFile.SeekEof;
end;

function TTestLibStream.Eoln: Boolean;
begin
  Result := FJudgeFile.Eoln;
end;

function TTestLibStream.SeekEoln: Boolean;
begin
  Result := FJudgeFile.SeekEoln;
end;

procedure TTestLibStream.NextLine;
begin
  FJudgeFile.NextLine;
end;

function TTestLibStream.ReadLongInt: Integer;
begin
  if FJudgeFile.SeekEoln then FJudgeFile.NextLine;
  FJudgeFile.ReadLongInt(Result);
end;

function TTestLibStream.ReadLongLong: Int64;
begin
  if FJudgeFile.SeekEoln then FJudgeFile.NextLine;
  FJudgeFile.ReadLongLong(Result);
end;

function TTestLibStream.ReadInteger: Integer;
begin
  if FJudgeFile.SeekEoln then FJudgeFile.NextLine;
  FJudgeFile.ReadLongInt(Result);
end;

function TTestLibStream.ReadReal: Extended;
begin
  if FJudgeFile.SeekEoln then FJudgeFile.NextLine;
  FJudgeFile.ReadFloat(Result);
end;

function TTestLibStream.ReadString: string;
begin
  if FJudgeFile.SeekEoln then FJudgeFile.NextLine;
  FJudgeFile.ReadLine(Result);
end;

procedure Quit(Res: TResult; Report: string);
begin
  case Res of
    _FAIL: VInternalCI(Report);
    _DIRT: VRejectPE(Report);
    _PE:   VRejectPE(Report);
    _WA:   VRejectWA(Report);
    _OK:   VAccept(Report);
  else
           VInternalCI(Report);
  end;
end;

initialization
  {$IFDEF DEBUG}
  DropToReportTxt('www.contester.ru / unJudge.pas v1.7');
  TestJudgeFile;
  TestCompare;
  ReadLn;
  {$ENDIF}
  InputTxt := TJudgeFile.Create(ftInput);
  InputTxt.LoadFromFile(ParamStr(1));
  OutputTxt := TJudgeFile.Create(ftOutput);
  OutputTxt.LoadFromFile(ParamStr(2));
  PatternTxt := TJudgeFile.Create(ftPattern);
  PatternTxt.LoadFromFile(ParamStr(3));
  WF := InputTxt;
  inf := TTestLibStream.Create(InputTxt);
  ouf := TTestLibStream.Create(OutputTxt);
  ans := TTestLibStream.Create(PatternTxt);
end.

