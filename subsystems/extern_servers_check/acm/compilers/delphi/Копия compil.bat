    @echo off
    set TEMP=c:\acm\dir_TMP
    set TMP=c:\acm\dir_TMP

rem ����������� ��������
    "c:\program files\borland\delphi7\bin\dcc32" -cc -$D- -$L- %1".pas"

rem ���� ������������, �� �������� ��������� ��� ������� ��������
   if not ERRORLEVEL 1 (
      rem ������� ��� ��������� ����������� �� ���������, ����� ��� �� �������� ���������� � ������ �����������
      perl "c:\acm\compilers\delphi\del_preprocess_delphi.pl" %1".pas" %1"_.pas"

      rem ����������� � ������� ������� �����������
      "c:\program files\borland\delphi7\bin\dcc32" -cc -JC -$A4 -$B- -$C- -$D- -$G+ -$H+ -$I- -$J- -$L- -$M- -$O+ -$P+ -$Q- -$R- -$T- -$U- -$V+ -$W- -$X+ -$Y+ -$Z1 %1"_.pas"
      
      rem �������� ���� ���������� �����
      "c:\program files\borland\cbuilder6\bin\tdump" %1"_.obj" >%1"_.dmp"
      
      rem �� ������ ����� �������� �� ���������� ����� ������ ��� ������������
      perl "c:\acm\tools\parse_obj_dmp.pl" %1"_.obj" %1"_.dmp" %1"_.prs" pas
      
      rem �������� �� 0 ��� 32� ������ ��������, �������� � ��������� � ����������� ��������
      "c:\acm\tools\null_imm.exe" %1"_.prs" %1".nul"
      
      rem ������� ��� ������
      del %1"_.pas"
      del %1"_.obj"
      del %1"_.prs"
      del %1"_.dmp"
   )

rem ���� ��� ���������� ���� ������, �� ������ ��� ���������� 
   if ERRORLEVEL 1 (
      del %1".exe"
      del %1".nul"
   )


