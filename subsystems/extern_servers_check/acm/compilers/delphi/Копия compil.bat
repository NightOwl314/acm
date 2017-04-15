    @echo off
    set TEMP=c:\acm\dir_TMP
    set TMP=c:\acm\dir_TMP

rem компилируем исходник
    "c:\program files\borland\delphi7\bin\dcc32" -cc -$D- -$L- %1".pas"

rem если скомпилилось, то проводим обработку дл€ анализа плагиата
   if not ERRORLEVEL 1 (
      rem убираем все директивы компил€тора из исходника, чтобы они не помешали компил€ции с нашими параметрами
      perl "c:\acm\compilers\delphi\del_preprocess_delphi.pl" %1".pas" %1"_.pas"

      rem компилируем с немного другими параметрами
      "c:\program files\borland\delphi7\bin\dcc32" -cc -JC -$A4 -$B- -$C- -$D- -$G+ -$H+ -$I- -$J- -$L- -$M- -$O+ -$P+ -$Q- -$R- -$T- -$U- -$V+ -$W- -$X+ -$Y+ -$Z1 %1"_.pas"
      
      rem получаем дамп объектного файла
      "c:\program files\borland\cbuilder6\bin\tdump" %1"_.obj" >%1"_.dmp"
      
      rem на основе дампа получаем из объектного файла только код пользовател€
      perl "c:\acm\tools\parse_obj_dmp.pl" %1"_.obj" %1"_.dmp" %1"_.prs" pas
      
      rem замен€ем на 0 все 32х битные значени€, смещени€ и указатели в асемблерных командах
      "c:\acm\tools\null_imm.exe" %1"_.prs" %1".nul"
      
      rem удал€ем все лишнее
      del %1"_.pas"
      del %1"_.obj"
      del %1"_.prs"
      del %1"_.dmp"
   )

rem если при компил€ции была ошибка, то удалим все результаты 
   if ERRORLEVEL 1 (
      del %1".exe"
      del %1".nul"
   )


