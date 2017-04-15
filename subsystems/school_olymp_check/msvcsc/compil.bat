    @echo off
    set TEMP=c:\acm\dir_TMP
    set TMP=c:\acm\dir_TMP

rem выставляем переменные окружения
call "C:\Program Files\Microsoft Visual Studio 8\Common7\Tools\vsvars32.bat"
set PATH=C:\WINDOWS\Microsoft.NET\Framework\v4.0.30319;%PATH%

rem компилируем и линкуем исходник
   csc.exe /o+ /r:System.Numerics.dll %1".cs"

copy %1.exe %1.nul
