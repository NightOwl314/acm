@echo off
    set TEMP=c:\acm\dir_TMP
    set TMP=c:\acm\dir_TMP

REM создаЄм каталог, где всЄ будет компилироватьс€
    mkdir %1
    copy %1.java %1\*
    cd %1

REM выполн€ем компил€цию
    c:\perl\bin\perl c:\acm\compilers\java\jmainrepl.pl %1.java
         
REM создаЄм jar-файл
    if not ERRORLEVEL 1 "C:\prog\src\java\jdk1.8.0_91_x64\bin\jar" cvfm %1.jar manifest.mf .
    if not ERRORLEVEL 1 copy %1.jar ..\%1.jar
    rem if ERRORLEVEL 1 del ..\%1.jar

REM удал€ем всЄ временное
rem    del /q *    
rem    cd ..
rem    rmdir %1
