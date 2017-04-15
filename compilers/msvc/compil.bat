    @echo off

rem выставл€ем переменные окружени€
call "C:\Program Files (x86)\Microsoft Visual Studio 12.0\Common7\Tools\vsvars32.bat"

rem компилируем и линкуем исходник
   cl.exe /O2 /G6 /Zp1 /Ze /F 67108864 %1".cpp"

rem если при компил€ции или линковке была ошибка, то удалим все результаты 
   if ERRORLEVEL 1 (
      del %1".exe"
      del %1".nul"
   )

rem если слинковалось, проводим обработку дл€ анализа плагиата
   if not ERRORLEVEL 1 (

      rem получаем объектный файл
      "C:\Program Files (x86)\CodeBlocks\MinGW\bin\g++" -Xlinker --stack=0x4000000 %1".cpp" -c -o %1"_.o"
      
      rem удал€ем символы из объектного файла
      "C:\FPC\bin\i386-win32\strip.exe" %1"_.o"
      
      rem переименовываем объектный файл
      ren %1"_.o" %1".nul"
   )

rem удаление временных файлов после линкера
   del %1".i*"
   del %1".tds"
   del %1".obj"
   del %1".pdb"
