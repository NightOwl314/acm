    @echo off
    set TEMP=c:\acm\dir_TMP
    set TMP=c:\acm\dir_TMP

rem ����������� ��������
    "C:\Program Files (x86)\Borland\BDS\4.0\Bin\dcc32.exe" -cc -IC:\PROGRA~2\Borland\BDS\4.0\lib -$D- -$L- %1".pas"

rem ���� ������������, �� �������� ��������� ��� ������� ��������
   if not ERRORLEVEL 1 (

      copy %1".pas" %1"_.pas"

      rem ����������� � ������� FreePascal
      "C:\FPC\bin\i386-win32\fpc.exe" -O2 -Mdelphi %1"_.pas"
      
      rem ������� ������� �� ���������� �����
      "C:\FPC\bin\i386-win32\strip.exe" %1"_.o"
      
      rem ��������������� ��������� ����
      ren %1"_.o" %1".nul"

      rem ������� ��� ������
      del %1"_.pas"
      del %1"_.o"
      del %1"_.exe"
   )

