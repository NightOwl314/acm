    @echo off
    "c:\program files\borland\cbuilder6\bin\bcc32" -c -w- -v- -d -X -H- -5 -Od -Jgd -a1 -tWC %1".cpp"
    if not ERRORLEVEL 1 "c:\program files\borland\cbuilder6\bin\ilink32" /Tpe /ap /c /x /j"c:\program files\borland\cbuilder6\lib" c0x32.obj hde.obj %1".obj",%1".exe", ,cw32.lib import32.lib

    del %1".i*"
    del %1".tds"
    del %1".obj"


