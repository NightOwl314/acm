    @echo off
    set TEMP=c:\acm\dir_TMP
    set TMP=c:\acm\dir_TMP

rem компилируем исходник
    "C:\Program Files (x86)\FreeBASIC\fbc.exe" -lang qb %1".bas"
