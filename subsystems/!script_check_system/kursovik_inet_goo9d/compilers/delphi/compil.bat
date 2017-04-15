    @echo off
    c:
    cd c:\acm\dir_tmp
    set TEMP=c:\acm\dir_TMP
    set TMP=c:\acm\dir_TMP

   "c:\program files\borland\delphi7\bin\dcc32" -cc -$D- -$L- %1".pas"
   "c:\program files\borland\delphi7\bin\dcc32" -cc -J -$D- -$L- %1".pas" > nul
   if ERRORLEVEL 1 del %1".exe"
