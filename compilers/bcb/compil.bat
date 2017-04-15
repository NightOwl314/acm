    @echo off

rem компилируем исходник
   "c:\program files\borland\cbuilder6\bin\bcc32" -c -w- -v- -d -X -H- -5 -Od -Jgd -a1 -tWC %1".cpp"

rem если откомпилировалось без ошибок то линкуем
   if not ERRORLEVEL 1 "c:\program files\borland\cbuilder6\bin\ilink32" /S:0x4000000 /Sc:0x1000 /Tpe /ap /c /x /j"c:\program files\borland\cbuilder6\lib" c0x32.obj %1".obj",%1".exe", ,cw32.lib import32.lib vcl.lib vcle.lib rtl.lib

rem если слинковалось, проводим обработку дл€ анализа плагиата
   if not ERRORLEVEL 1 (
      rem компилируем с немного другими параметрами
      "c:\program files\borland\cbuilder6\bin\bcc32" -V -c -w- -v- -d -X -H- -5 -O -Oc -Jgx -a4 -tWC %1".cpp" >nul
      
      rem получает дамп объектного файла
      "c:\program files\borland\cbuilder6\bin\tdump" %1".obj" >%1".dmp"
      
      rem на основе дампа получаем из объектного файла только код пользовател€
      perl  "c:\acm\tools\parse_obj_dmp.pl" %1".obj" %1".dmp" %1".prs" cpp 
      
      rem замен€ем на 0 все 32х битные значени€, смещени€ и указатели в асемблерных командах
      "c:\acm\tools\null_imm.exe" %1".prs" %1".nul" 
      
      rem удал€ем все лишнее
      del %1".obj"
      del %1".prs"
      del %1".dmp"
   )

rem если при компил€ции или линковке была ошибка, то удалим все результаты 
   if ERRORLEVEL 1 (
      del %1".exe"
      del %1".nul"
   )

rem удаление временных файлов осле линкера
   del %1".i*"
   del %1".tds"


