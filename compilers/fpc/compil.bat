    @echo off
    set TEMP=c:\acm\dir_TMP
    set TMP=c:\acm\dir_TMP
                                                 
rem ����������� ��������
    "C:\FPC\bin\i386-win32\fpc.exe" -O2 -Sd %1".pas"


rem ���� ������������, �� �������� ��������� ��� ������� ��������
   if not ERRORLEVEL 1 (
      
      rem ������� ������� �� ���������� �����
      "C:\FPC\bin\i386-win32\strip.exe" %1".o"
      
      rem ��������������� ��������� ����
      ren %1".o" %1".nul"

   )

