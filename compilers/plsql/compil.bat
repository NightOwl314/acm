@echo off
	REM	����� ����� ��� ��������� PLSQL******************************
	SET	COMP_ADR=c:\acm\compilers\plsql\

	REM	����������� ��������� ��� ���� ������������******************************
	SET	DANG=commit connect var_teacher

	REM	����� ����� ���� ������������
	SET	T_DIR=c:\acm\dir_tmp\

	REM	������ �����
	SET	STR_LINK=@//localhost/avtdb

	REM	�����/������@������ ����� ��������������
	SET	ADMIN_STR=system/Admin001

	REM	�����/������@������ ����� ������������
	SET	USER=user%1
	SET	USER_STR=%USER%/%USER%

	REM	�������� ����� ��� ����������� ������
	SET	SCHEME=buses0_creator

	REM	�������� ����� � ���������� ���������� ����
	SET	F_NAME=%1.stt


REM	��������� ��������� pl_sql2.exe � ��������� ������ ���������� ��� ����� � ����������� ��������� ��� ������������
REM	������ �������� - ��� ����� � ����� ������������
REM	������ - "pl_sql2.exe %1 DANG" - ��������� ���� ����� � ���� ������������ ����� �������������
REM	**************************************************
	%COMP_ADR%pl_sql2.exe %1 %DANG%
REM	**************************************************

REM ������ ���� ����������
IF ERRORLEVEL 2 GOTO ERROR_CH_SQL
GOTO NEXT
:ERROR_CH_SQL


GOTO ONEXIT

:NEXT

@echo	--�������� ������������> %F_NAME%
@echo	Create user %USER%>> %F_NAME%
@echo	identified by %USER%>> %F_NAME%
@echo	default tablespace USERS>> %F_NAME%
@echo	temporary tablespace TEMP;>> %F_NAME%
@echo	Grant connect, resource to %USER%;>> %F_NAME%
@echo	connect %ADMIN_STR%%STR_LINK%>> %F_NAME%
@echo	Grant select any table to %USER%;>> %F_NAME%
@echo	connect %USER_STR%%STR_LINK%;>> %F_NAME%



rem ECHO	quit|sqlplus %ADMIN_STR%%STR_LINK% @%F_NAME%
	COPY /B /Y %COMP_ADR%plsql.exe %1.exe

rem	DEL %F_NAME%

REM	��������� � ������� ������������ ��������� ����������
ECHO	it's guid string -------------------->> %F_NAME%
ECHO	%ADMIN_STR%%STR_LINK%>> %F_NAME%
ECHO	%USER_STR%%STR_LINK%>> %F_NAME%
ECHO	%SCHEME%>> %F_NAME%
ECHO	drop user %USER% cascade>> %F_NAME%

GOTO ONEXIT
    :ONEXIT
