    @echo off
REM подключаемся к Oracle, чтобы присланный запрос выполнялся без сильных задержек
@echo quit | sqlplus buses0_select/buses0_select@orcl
    COPY /B /Y "c:\acm\compilers\sql\default_program.exe" %1.exe