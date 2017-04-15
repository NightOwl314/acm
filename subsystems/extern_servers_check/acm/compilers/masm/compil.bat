    @echo off
    set TEMP=c:\acm\dir_TMP
    set TMP=c:\acm\dir_TMP

rem компилируем исходник
   "c:\masm32\bin\ml.exe" /coff /c %1".asm"

rem если откомпилировалось без ошибок то линкуем
   if not ERRORLEVEL 1 "c:\masm32\bin\link.exe" /subsystem:console %1".obj"

rem если слинковалось, проводим обработку дл€ анализа плагиата
   if not ERRORLEVEL 1 (
      rem компилируем с немного другими параметрами (OMF-формат)
      "c:\masm32\bin\ml.exe" /c %1".asm" >nul
      
      rem получаем дамп объектного файла
      "c:\program files\borland\cbuilder6\bin\tdump" %1".obj" >%1".dmp"
      
      rem на основе дампа получаем из объектного файла только код пользовател€
      perl  "c:\acm\tools\parse_obj_dmp.pl" %1".obj" %1".dmp" %1".prs" asm
      
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
