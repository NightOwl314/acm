    @echo off
REM ������������ � Oracle, ����� ���������� ������ ���������� ��� ������� ��������
@echo quit | sqlplus buses0_select/buses0_select
    COPY /B /Y "c:\acm\compilers\sql\default_program.exe" %1.exe
