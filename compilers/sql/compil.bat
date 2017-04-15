    @echo off
    set TEMP=c:\acm\dir_TMP
    set TMP=c:\acm\dir_TMP

set path=C:\prog\database\oracle\11.2.0\dbhome_1\BIN;%path%

REM подключаемся к Oracle, чтобы присланный запрос выполнялся без сильных задержек
@echo quit | sqlplus buses0_select/buses0_select
    COPY /B /Y "c:\acm\compilers\sql\default_program.exe" %1.exe

REM for plagiat checking
c:\acm\compilers\sql\lcaser.exe %1 %1.nul
