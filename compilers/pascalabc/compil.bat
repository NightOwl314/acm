    @echo off
    set TEMP=c:\acm\dir_TMP
    set TMP=c:\acm\dir_TMP

rem компилируем исходник
    "C:\Program Files (x86)\PascalABC.NET\pabcnetcclear.exe" %1".pas" | C:\acm\tools\iconv\bin\iconv.exe -f cp866 -t cp1251

rem если скомпилилось, то проводим обработку для анализа плагиата
   if not ERRORLEVEL 1 (

      copy %1".pas" %1"_.pas"

      rem компилируем с помощью FreePascal
      "C:\FPC\bin\i386-win32\fpc.exe" -O2 %1"_.pas"
      
      rem удаляем символы из объектного файла
      "C:\FPC\bin\i386-win32\strip.exe" %1"_.o"
      
      rem переименовываем объектный файл
      ren %1"_.o" %1".nul"

      rem удаляем все лишнее
      del %1"_.pas"
      del %1"_.exe"
   )

