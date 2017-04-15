@echo off
    set TEMP=c:\acm\dir_TMP
    set TMP=c:\acm\dir_TMP

REM ������ �������, ��� �� ����� ���������������
    mkdir %1
    copy %1.java %1\sol.java
    copy c:\acm\compilers\java\manifest.mf %1\*
    cd %1

REM �������� ��� ��������� ������, ����� �� �������� � %1
    perl c:\acm\compilers\java\jmainrepl.pl sol.java Main> Main.java
    del sol.java
         
REM ��������� ����������
    "c:\programs\java\bin\javac" Main.java 2>&1
rem     "c:\programs\java\bin\javac" Main.java

REM ������ jar-����
    if not ERRORLEVEL 1 c:\programs\java\bin\jar cvfm %1.jar manifest.mf .
    if not ERRORLEVEL 1 copy %1.jar ..\%1.jar
    rem if ERRORLEVEL 1 del ..\%1.jar

REM ������� �� ���������
    del /q *    
    cd ..
    rmdir %1
