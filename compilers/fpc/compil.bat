    @echo off
    set TEMP=c:\acm\dir_TMP
    set TMP=c:\acm\dir_TMP
                                                 
rem компилируем исходник
    "C:\FPC\bin\i386-win32\fpc.exe" -O2 -Sd %1".pas"


rem если скомпилилось, то проводим обработку для анализа плагиата
   if not ERRORLEVEL 1 (
      
      rem удаляем символы из объектного файла
      "C:\FPC\bin\i386-win32\strip.exe" %1".o"
      
      rem переименовываем объектный файл
      ren %1".o" %1".nul"

   )

