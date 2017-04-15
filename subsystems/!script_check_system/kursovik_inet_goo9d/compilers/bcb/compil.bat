    @echo off
    "c:\program files\borland\cbuilder6\bin\bcc32" -c -w- -v- -d -X -H- -5 -Od -Jgd -a1 -tWC %1".cpp"
    if not ERRORLEVEL 1 "c:\program files\borland\cbuilder6\bin\ilink32" -S:40000000 /Tpe /ap /c /x /j"c:\program files\borland\cbuilder6\lib" c0x32.obj %1".obj",%1".exe", ,cw32.lib import32.lib
    if not ERRORLEVEL 1 "c:\program files\borland\cbuilder6\bin\bcc32" -c -w- -v- -d -X -H- -5 -Od -Jgx -a1 -tWC %1".cpp" > nul
    if ERRORLEVEL 1 del %1".exe"

    del %1".i*"
    del %1".tds"

rem    "c:\program files\borland\cbuilder6\bin\bcc32" -c -w- %1".cpp"
rem    "c:\program files\borland\cbuilder6\bin\ilink32" -S:40000000 /Tpe /ap /c /x /j"c:\program files\borland\cbuilder6\lib" c0x32.obj %1".obj",%1".exe", ,cw32.lib import32.lib

rem    del %1".i*"
rem    del %1".tds"
rem    del %1".obj"


