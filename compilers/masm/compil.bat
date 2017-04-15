    @echo off
    set TEMP=c:\acm\dir_TMP
    set TMP=c:\acm\dir_TMP

    SET PATH=c:\masm32\bin
    SET INCLUDE=c:\masm32\INCLUDE
    SET LIB=c:\masm32\lib


rem ����������� ��������
   "c:\masm32\bin\ml.exe" -Zi -c -Fl -coff %1".asm"

rem ���� ����������������� ��� ������ �� �������
   if not ERRORLEVEL 1 "c:\masm32\bin\link.exe" /subsystem:console %1".obj" kernel32.lib

rem ���� ������������, �������� ��������� ��� ������� ��������
   if not ERRORLEVEL 1 (
      rem ����������� � ������� ������� ����������� (OMF-������)
      "c:\masm32\bin\ml.exe" /c %1".asm" >nul
      
      rem �������� ���� ���������� �����
      "c:\program files\borland\cbuilder6\bin\tdump" %1".obj" >%1".dmp"
      
      rem �� ������ ����� �������� �� ���������� ����� ������ ��� ������������
      perl  "c:\acm\tools\parse_obj_dmp.pl" %1".obj" %1".dmp" %1".prs" asm
      
      rem �������� �� 0 ��� 32� ������ ��������, �������� � ��������� � ����������� ��������
      "c:\acm\tools\null_imm.exe" %1".prs" %1".nul" 
      
      rem ������� ��� ������
      del %1".obj"
      del %1".prs"
      del %1".dmp"
   )

rem ���� ��� ���������� ��� �������� ���� ������, �� ������ ��� ���������� 
   if ERRORLEVEL 1 (
      del %1".exe"
      del %1".nul"
   )
