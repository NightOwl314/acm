@echo off
	REM	����� ����� ��� ��������� PLSQL******************************
	SET	COMP_ADR=c:\acm\compilers\plsql\

	REM	����������� ��������� ��� ���� ������������******************************
	SET	DANG=commit connect %1

	REM	����� ����� ���� ������������
	SET	T_DIR=c:\acm\dir_tmp\

	REM	������ �����
	SET	STR_LINK=@orcl

	REM	�����/������@������ ����� ��������������
	SET	ADMIN_STR=system/manager

	REM	�����/������@������ ����� ������������
	SET	USER=user%1
	SET	USER_STR=%USER%/%USER%

	REM	�������� ����� ��� ����������� ������
	SET	SCHEME=kvn

	REM	�������� ����� ��� ����������� ������ (������ �����������)
	SET	SCHEME_STR=kvn/virus

	REM	�������� ����� � ���������� ���������� ����
	SET	F_NAME=create


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

@echo	--�������� ������������> %F_NAME%.%1
@echo	Create user %USER%>> %F_NAME%.%1
@echo	identified by %USER%>> %F_NAME%.%1
@echo	default tablespace USERS>> %F_NAME%.%1
@echo	temporary tablespace TEMP;>> %F_NAME%.%1
@echo	Grant connect, resource to %USER%;>> %F_NAME%.%1
@echo	connect %ADMIN_STR%%STR_LINK%>> %F_NAME%.%1
@echo	Grant select any table to %USER%;>> %F_NAME%.%1
@echo	exit>> %F_NAME%.%1



ECHO	quit|sqlplus %ADMIN_STR%%STR_LINK% @%F_NAME%.%1
	COPY /B /Y %COMP_ADR%plsql3.exe %1.exe

	DEL %F_NAME%.%1

REM	��������� � ������� ������������ ��������� ����������
ECHO	it's guid string -------------------->> %1
ECHO	%ADMIN_STR%%STR_LINK%>> %1
ECHO	%USER_STR%%STR_LINK%>> %1
ECHO	%SCHEME%>> %1
ECHO	drop user %USER% cascade>> %1

GOTO ONEXIT
    :ONEXIT