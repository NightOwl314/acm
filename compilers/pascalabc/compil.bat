    @echo off
    set TEMP=c:\acm\dir_TMP
    set TMP=c:\acm\dir_TMP

rem ����������� ��������
    "C:\Program Files (x86)\PascalABC.NET\pabcnetcclear.exe" %1".pas" | C:\acm\tools\iconv\bin\iconv.exe -f cp866 -t cp1251

rem ���� ������������, �� �������� ��������� ��� ������� ��������
   if not ERRORLEVEL 1 (

      copy %1".pas" %1"_.pas"

      rem ����������� � ������� FreePascal
      "C:\FPC\bin\i386-win32\fpc.exe" -O2 %1"_.pas"
      
      rem ������� ������� �� ���������� �����
      "C:\FPC\bin\i386-win32\strip.exe" %1"_.o"
      
      rem ��������������� ��������� ����
      ren %1"_.o" %1".nul"

      rem ������� ��� ������
      del %1"_.pas"
      del %1"_.exe"
   )

