{*******************************************************************************
  Этот модуль используется при построении программ-проверщиков

  (С) Михаил Копачев

  Внесены небольшие правки для использования в проверяющей системе кафедры АВТ ВоГТУ
*******************************************************************************}

unit USolutionCheck;

interface
uses
  SysUtils, Windows;

const
  {Это константы, которые используются при интегрировании проверщика
   в систему}
  {Внутреняя ошибка}
  INTERNAL_ERROR        = $FF;
  {Решение принято}
  ACCEPTED              = $00;
  {Ошибка формата}
  PRESENTATION_ERROR    = $02;
  {Ошибочный ответ}
  WRONG_ANSWER          = $01;
  {Ошибка безопасности}
  SECURITY_VIOLATION    = $FD;

  {Это размер буфера}
  BufferSize            = 1024*1024;
  {Это признак конца файла}
  SYM_EOF               = #0;
  {Признак начала файла}
  SYM_SOF               = #1;
  {Признак конца строчки}
  SYM_EOLN              = #2;

  {Множество пробельных символов}
  BLANCK_SET            = [#9, ' '];


type
  TCharSet = set of Char;
  {**********************************************
    Данный класс используется для обращения к
    дисковому файлу при проверке
   **********************************************}
  TInnerFile = class
  private
    {Это сам файл}
    hFile: THandle;
    {Текущая позиция в файле}
    FCurrent: Integer;
    {Это буфер - размер 1 мегабайт}
    FBuffer: array [0..BufferSize - 1] of Byte;
    {Это позиция в буфере}
    FBufPos: Integer;
    {Это размер буфера}
    FBufSize: Integer;
    {Размер файла}
    FSize: Integer;
    {Это предыдущий символ}
    FLastChar: Char;
  protected
    procedure   ReadSize;
    procedure   ReadBuffer;
    {Это процедура сдвига указателя на следующий символ}
    procedure   MoveCurrent;
    {Это процедура, которая актуализирует текущий символ}
    procedure   ActualCurrent;
  public
    constructor Create(const FileName: String);
    destructor  Destroy; override;
    {Функция возвращает текщий символ}
    function    CurrentChar: Char;
    {Процедура перехода к следующему символу}
    procedure   NextChar;
    {Функция, которая возвращает признак "конец файла"}
    function    EOF: Boolean;
    {Функция, которая пропускает заданное множество символов}
    procedure   SkipChars(SkipSet: TCharSet);
    {Это функция, которая вычитывает все, что принадлежит
     данному множеству}
    function    ReadChars(CharSet: TCharSet): String;
    {Это функция, которая сичтывает все до любого символа,
     принадлежащего СТОП-множеству, игнорируя все символы,
     которые принадлежат SKIP-множеству}
    function    ReadUntil(StopSet: TCharSet; SkipSet: TCharSet = []): String;
    {Функция считывания строки символов - в нее попадают
     все символы, которые встретятся начиная с текущего
     до перевода строки}
    function    ReadString: String;
    {Это функция считывания "обрезанной" строчки - от строки отрезаются
     все ведущие и завершающие символы Blancks}
    function    ReadTrimString(Blancks: TCharSet = BLANCK_SET): String;
    {Считываем целое число - с одновременным удалением
     всех ведущих нулей}
    function    ReadHugeInt: String;
    {Это функция, которая возвращает результат сравнения двух
     длинных чисел. Функция возвращет SGN(A - B)}
    function    CompHugeInts(A, B: String): Integer;
    {Эта функция производит чтение ограниченного сверху и снизу
     целого числа A<=x<=B. Нарушение приводит по умолчанию
     к ошибке PRESENTATION_ERROR, иначе - WRONG_ANSWER}
    function    ReadHugeIntBound(A, B: String; PresentError: Boolean = TRUE): String;
    {Функция генерирует PRESENTATION_ERROR, если есть еще что-то
     не прочитанное в файле, кроме пробелов и переводов строк}
    procedure   IsEmpty;
    {Функция чтения целого числа}
    function    ReadInt: Int64;
    {Фукнция чтения ограниченного целого числа}
    function    ReadIntBound(A, B: Int64; PresentError: Boolean = TRUE): Int64;
    {Процедура производит чтение строки из файла и его сравнение,
     если они не свопадют - вызвает WRONG_ANSWER}
    procedure   WaitString(S: String; CaseSence: Boolean = FALSE; Blancks: TCharSet = BLANCK_SET);
    {Процедура производит чтение целого из файла и его сравнение,
     если оно не свопадает - вызвает WRONG_ANSWER}
    procedure   WaitInt(Value: Int64);
    {Процедура производит чтение длинного целого из файла и его сравенние,
     если оно не свопадает - вызвает WRONG_ANSWER. Предполагается
     что передаваемое число не содержит ведущих нулей}
    procedure   WaitHugeInt(Value: String);
    {Процедура чтения и сравнения ограниченного числа}
    procedure   WaitIntBound(Value, A, B: Int64);
    {Процедура чтения и сравнения ограниченного длинного числа}
    procedure   WaitHugeIntBound(Value, A, B: String);
    {Процедура чтения дробного числа (с точкой)
     FracSize означает количество цифр после запятой
     Если оно отлично от нуля, то производится сравнение
     и выдается PRESENTATION_ERROR}
    function    ReadHugeFloat(FracSize: Integer = 0): String;
    {Процедура чтения дробного числа}
    function    ReadFloat(FracSize: Integer = 0): Extended;
    {Процедура чтения и сравнения двух дробных чисел}
    procedure   WaitHugeFloat(Value: String; FracSize: Integer = 0);
    {Процедура чтения и сравнения дробных чисел с допуском}
    procedure   WaitFloat(Value, Quality: Extended; FracSize: Integer = 0);
  end;

  {Это типы CALL_BACK процедур}
  TNGraphWayCallBack = function(I, J: Int64; First: Boolean): Boolean;


{Это основные процедуры, которые могут быть использованы при проверке}
{Завершение работы}
procedure _QUIT(ExitCode: Integer; ErrMsg: String);

{Сравнение N заданных чисел. Если все числа совпали
 и файлы пусты, то возвращает ACCEPTED}
procedure CompareNInt(Src, Test: TInnerFile; N: Integer = 1);

{Это процедура построчного сравнения файлов}
procedure CompareStrEOF(Src, Test: TInnerFile; Sence: Boolean = TRUE; Blancks: TCharSet = []);

{Данная процедура считывает одно целое число K, которое означает
 кличество последующих чисел. Числа считываются и передаются
 парами в специальную процедуру, которая возвращает TRUE, если
 все в порядке, или FALSE, если не в прядке. Чаще всего такая
 задача возникает при проверку путей в графе. Если первое число
 (K) равно ZeroConst, то считается, что путь пустой.
 Сначала считывается первое число и передается в качестве I
 с параметром First = TRUE}
procedure CompNGraphWay(Test: TInnerFile; KEqu: Integer; CallBack: TNGraphWayCallBack; ZeroConst: Integer = 0);


{**********************************************
  Процедура отправляет текстовое сообщение
  проверки в лог
 **********************************************}
procedure SendToLogger(S: String; Lev: Integer);


var
  InFile, JudgeFile, ContFile: TInnerFile;

implementation

{**********************************************
  Вспомогательная процедура, которая отправляет
  вспомогательное сообщение от тестировании
 **********************************************}

procedure SendToLogger(S: String; Lev: Integer);
begin
  Writeln('to log: level=',lev,', message=<',s,'>');
end;

procedure Error(const Msg: String);
begin
  //if MessageBox(0, PChar(Msg), 'Ошибка при проверке', MB_OKCANCEL + MB_ICONERROR + MB_TASKMODAL) = idOK
  //then _QUIT(SECURITY_VIOLATION, '')
  //else 
  _QUIT(INTERNAL_ERROR, 'Ошибка по выбору');
end;

procedure APIError(const Msg: String);
begin
  Error('API Error #' + IntToStr(GetLastError) + ' ' +
    SysErrorMessage(GetLastError) + #13 + Msg);
end;

{ TInnerFile }

procedure TInnerFile.ActualCurrent;
begin
  {Проверяем, попадает ди текущий символ в считанный буфер}
  if (FBufPos < 0) or (FBufPos > FBufSize - 1)
    {Требуется сичтать буфер}
  then ReadBuffer;
end;

function TInnerFile.CompHugeInts(A, B: String): Integer;
var
  Index: Integer;
  Neg1, Neg2: Boolean;
begin
  Assert((A <> '') and (B <> ''), 'В процедуру сравнения переданое "пустое" число');
  {Проверим наличие у чисел знаков}
  Neg1 := A[1] = '-';
  Neg2 := B[1] = '-';
  {Отрезаем знаки}
  if Neg1
  then Delete(A, 1, 1);
  if Neg2
  then Delete(B, 1, 1);
  Assert((A <> '') and (B <> ''), 'В процедуру сравнения переданое "пустое" число');
  {Добавляем ведущие нули}
  if Length(A) > Length(B)
  then B := StringOfChar('0', Length(A) - Length(B)) + B;
  if Length(A) < Length(B)
  then A := StringOfChar('0', Length(B) - Length(A)) + A;
  if not (Neg1 xor Neg2)
  then begin
    {Проверять числа надо, если у них совпадают знаки}
    Result := 0;
    Assert(Length(A) = Length(B), 'Ошибка при выранвнивании нулями!');
    {Сравниваем}
    for Index := 1 to Length(A) do begin
      Assert(A[Index] in ['0'..'9'], 'Не верный формат числа');
      Assert(B[Index] in ['0'..'9'], 'Не верный формат числа');
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
    {Если числа - отрицательные, то нужно инвертить результат}
    if Neg1
    then Result := -Result;
           {Знаки не совпадают - результат вычисляем по ним}
  end else Result := Ord(Neg2) - Ord(Neg1);
end;

constructor TInnerFile.Create(const FileName: String);
begin
  inherited Create;
  {Открываем файл}
  hFile := CreateFile(
    PChar(FileName),
    GENERIC_READ,
    FILE_SHARE_READ,
    NIL, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, 0
  );
  if hFile = INVALID_HANDLE_VALUE
  then APIError('Try open file: ' + FileName);
  {Получаем длинну файла}
  ReadSize;
  {Текущая позиция - нулевая}
  FCurrent := 0;
  FBufSize := -1;
  FBufPos := 0;
  FLastChar := SYM_SOF;
end;

function TInnerFile.CurrentChar: Char;
begin
  {Если в данный момент мы дошли до конца файла, то
   производим выдачу символа SYM_EOF}
  if FCurrent >= FSize
  then Result := SYM_EOF
  else begin
    {Считываем текущий байт}
    ActualCurrent;
    Result := Char(FBuffer[FBufPos]);
    {Теперь проверим, не принадлежит ли данный символ
     переводу строки}
    if Result in [#10, #13]
    then begin
      {Нужно проверить, не принадлежал ли последний символ
       переводу строки}
      if FLastChar = SYM_EOLN
      then begin
        {Да принадлежал - данный символ нужно пропустить}
        FLastChar := SYM_SOF;
        MoveCurrent;
        Result := CurrentChar;
      end else Result := SYM_EOLN;
    end;
  end;  
end;

destructor TInnerFile.Destroy;
begin
  {Закрываем файл}
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
  {Считываем константу и проверяем соответсвие}
  N := Test.ReadIntBound(KEqu, KEqu, FALSE);
  {Теперь проверим пустоту}
  if N <> ZeroConst
  then begin
    {Производим последовательное считывание чисел}
    Current := Test.ReadInt;
    {Первый вызов}
    if not CallBack(Current, 0, TRUE)
    then _QUIT(WRONG_ANSWER, 'Внешняя процедура проверки вернула ошибку');
    for Index := 2 to N do begin
      Last := Current;
      Current := Test.ReadInt;
      {Очередной вызов}
      if not CallBack(Last, Current, FALSE)
      then _QUIT(WRONG_ANSWER, 'Внешняя процедура проверки вернула ошибку');
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
  then _QUIT(PRESENTATION_ERROR, 'Файл содержит лишнюю информацию');
end;

procedure TInnerFile.MoveCurrent;
begin
  Inc(FCurrent);
  Inc(FBufPos);
  ActualCurrent;
end;

procedure TInnerFile.NextChar;
begin
  {Запоминаем старый символ}
  FLastChar := CurrentChar;
  {Переходим к следующему}
  MoveCurrent;
end;

procedure TInnerFile.ReadBuffer;
var
  ReadResult: DWORD;
begin
  {Считываем данные в буфер}
  FBufPos := 0;
  if not ReadFile(hFile, FBuffer, SizeOf(FBuffer), ReadResult, NIL)
  then APIError('ReadBuffer()');
  FBufSize := ReadResult;
end;

function TInnerFile.ReadChars(CharSet: TCharSet): String;
begin
  Assert(not (SYM_EOF in CharSet), 'Нельзя "прочитать" конец файла');
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
  {Пропускаем возможные ведущие пробелы и переводы строчек}
  SkipChars(BLANCK_SET + [SYM_EOLN]);
  {Считываем знаки}
  Sign := ReadChars(['-', '+']);
  if Length(Sign) > 1
  then _QUIT(PRESENTATION_ERROR, 'Число не может содержать больше одного знака + или -');
  if Sign = '+'
  then Sign := '';
  {Считываем целую часть}
  Int := ReadChars(['0'..'9']);
  if Int = ''
  then _QUIT(PRESENTATION_ERROR, 'Целая часть дробного числа не может быть пустой');
  {Проверяем наличие точки}
  if CurrentChar = '.'
  then begin
    NextChar;
    Frac := ReadChars(['0'..'9']);
    if Frac = ''
    then _QUIT(PRESENTATION_ERROR, 'Дробная часть не может быть пустой');
    {Проверим длину дробной части}
    if (FracSize <> 0) and (Length(Frac) <> FracSize)
    then _QUIT(PRESENTATION_ERROR, 'Количество знаков в дробной части не совпадает с требуемым ' +
      IntToStr(Length(Frac)) + ' вместо ' + IntToStr(FracSize));
  end else begin
    {Проверим нужна ли дробная часть}
    if FracSize <> 0
    then _QUIT(PRESENTATION_ERROR, 'Число обязательно должно иметь дробную часть');
    Frac := '';
  end;
  {Обрезаем ведущие нули}
  Index := 1;
  while (Index < Length(Int)) and (Int[Index] = '0') do
    Inc(Index);
  Delete(Int, 1, Index - 1);
  {Если дробная часть пустая, то добавляем туда 0}
  if Frac = ''
  then Frac := '0'
  else begin
    {Обрезаем замыкающие нули}
    Index := Length(Frac);
    while (Index > 1) and (Frac[Index] = '0') do
      Dec(Index);
    Frac := Copy(Frac, 1, Index);
  end;  
  {Объединяем все в число}
  Result := Sign + Int + '.' + Frac;
end;

function TInnerFile.ReadHugeInt: String;
var
  Index: Integer;
  Sign: String;
begin
  {Пропускаем возможные ведущие пробелы и переводы строчек}
  SkipChars(BLANCK_SET + [SYM_EOLN]);
  {Произведем проверку - нет ли там знака}
  Sign := ReadChars(['-', '+']);
  {Знак может быть единичным}
  if Length(Sign) > 1
  then _QUIT(PRESENTATION_ERROR, 'Число не может содержать больше одного знака + или -');
  {Знак + можно опустить}
  if Sign = '+'
  then Sign := '';
  {Считываем все число}
  Result := ReadChars(['0'..'9']);
  {Возможен пустой результат - если записано что-то отличное число}
  if Result = ''
  then _QUIT(PRESENTATION_ERROR, 'Число не может быть пустым, или содержать знаки отличные от цифр');
  {Усекаем ведущие нули}
  Index := 1;
  while (Index < Length(Result)) and (Result[Index] = '0') do
    Inc(Index);
  Delete(Result, 1, Index - 1);
  {Добавляем знак, но только не к нулю}
  if Result <> '0'
  then Result := Sign + Result;
end;

function TInnerFile.ReadHugeIntBound(A, B: String; PresentError: Boolean = TRUE): String;
begin
  {Считываем длинное число}
  Result := ReadHugeInt;
  {Сравниваем}
  if (CompHugeInts(A, Result) > 0) or (CompHugeInts(Result, B) > 0)
  then begin
    if PresentError
    then _QUIT(PRESENTATION_ERROR, 'Ожидается число из интервала [' + A + ', ' +
      B + ', а считано ' + Result)
    else _QUIT(WRONG_ANSWER, 'Ожидается число из интервала [' + A + ', ' +
      B + ', а считано ' + Result);
  end;
end;

function TInnerFile.ReadInt: Int64;
begin
  try
    Result := StrToInt64(ReadHugeInt);
  except
    Result := 0;
    _QUIT(PRESENTATION_ERROR, 'Число слишком велико или слишком мало, чтобы разместиться в Int64');
  end;
end;

function TInnerFile.ReadIntBound(A, B: Int64; PresentError: Boolean = TRUE): Int64;
begin
  Result := ReadInt;
  if (Result < A) or (Result > B)
  then begin
    if PresentError
    then _QUIT(PRESENTATION_ERROR, 'Ожидается число из интервала [' + IntToStr(A) + ', ' +
      IntToStr(B) + ', а считано ' + IntToStr(Result))
    else _QUIT(WRONG_ANSWER, 'Ожидается число из интервала [' + IntToStr(A) + ', ' +
      IntToStr(B) + ', а считано ' + IntToStr(Result));
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
  {Теперь указатель указывает на символ "конец строчки"}
  NextChar;
end;

function TInnerFile.ReadTrimString(Blancks: TCharSet): String;
var
  NewLng: Integer;
begin
  {Пропускаем все пробелы}
  SkipChars(Blancks);
  {Теперь читаем строчку}
  Result := ReadString;
  {Обрезаем все пробельные символы}
  NewLng := Length(Result);
  while NewLng > 0 do
    if Result[NewLng] in Blancks
    then Dec(NewLng)
    else Break;
  SetLength(Result, NewLng);  
end;

function TInnerFile.ReadUntil(StopSet: TCharSet; SkipSet: TCharSet = []): String;
begin
  {Добавляем в СТОП-множество конец файла}
  Include(StopSet, SYM_EOF);
  Assert(not (SYM_EOF in SkipSet), 'Нельзя пропустить конец файла');
  Result := '';
  while not (CurrentChar in StopSet) do begin
    if not (CurrentChar in SkipSet)
    then Result := Result + CurrentChar;
    {Переходим к следующему символу}
    NextChar;
  end;
end;

procedure TInnerFile.SkipChars(SkipSet: TCharSet);
begin
  {Исключаем из множества #0}
  Assert(not (SYM_EOF in SkipSet), 'Нельзя прпустить конец файла');
  {Пропускам все символы из множества}
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
  then _QUIT(WRONG_ANSWER, 'Большое дробное число не совпадает с эталоном');
end;

procedure TInnerFile.WaitHugeInt(Value: String);
var
  Temp: String;
begin
  Temp := ReadHugeInt;
  if Value <> Temp
  then _QUIT(WRONG_ANSWER, 'Ожидали ' + Value + ', а получили ' + Temp);
end;

procedure TInnerFile.WaitHugeIntBound(Value, A, B: String);
var
  Temp: String;
begin
  Temp := ReadHugeIntBound(A, B);
  if Value <> Temp
  then _QUIT(WRONG_ANSWER, 'Ожидали ' + Value + ', а получили ' + Temp);
end;

procedure TInnerFile.WaitInt(Value: Int64);
var
  Temp: Int64;
begin
  Temp := ReadInt;
  {Преобразуем целое в строчку}
  if Temp <> Value
  then _QUIT(WRONG_ANSWER, 'Ожидали ' + IntToStr(Value) + ', а получили ' + IntToStr(Temp));
end;

procedure TInnerFile.WaitIntBound(Value, A, B: Int64);
var
  Temp: Int64;
begin
  Temp := ReadIntBound(A, B);
  {Преобразуем целое в строчку}
  if Temp <> Value
  then _QUIT(WRONG_ANSWER, 'Ожидали ' + IntToStr(Value) + ', а получили ' + IntToStr(Temp));
end;

procedure TInnerFile.WaitString(S: String; CaseSence: Boolean = FALSE; Blancks: TCharSet = BLANCK_SET);
var
  I, L: Integer;
  R: String;
  CmpRes: Boolean;
begin
  {Образем исходную строчку}
  I := 1;
  while I <= Length(S) do
    if S[I] in Blancks
    then Inc(I)
    else Break;
  {I - первый не пробельный символ}
  L := Length(S) - I;
  while L > 0 do
    if S[I + L] in Blancks
    then Dec(L)
    else Break;
  S := Copy(S, I, L + 1);
  {Теперь считываем строчку}
  R := ReadTrimString(Blancks);
  if CaseSence
  then CmpRes := AnsiSameStr(S, R)
  else CmpRes := AnsiSameText(S, R);
  {Генерируем ошибку}
  if not CmpRes
  then _QUIT(WRONG_ANSWER, 'Ожидали строку "' + S + '", а получили "' + R + '"');
end;

initialization
  try
    InFile := TInnerFile.Create(ParamStr(1));
    JudgeFile := TInnerFile.Create(ParamStr(3));
    ContFile := TInnerFile.Create(ParamStr(2));
  except
    _QUIT(INTERNAL_ERROR, 'Ошибка при открытии файлов');
  end;
finalization
  InFile.Free;
  JudgeFile.Free;
  ContFile.Free;
end.
