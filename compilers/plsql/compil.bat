@echo off
	REM	Адрес папки для обработки PLSQL******************************
	SET	COMP_ADR=c:\acm\compilers\plsql\

	REM	Запрещённые выражения для кода пользователя******************************
	SET	DANG=commit connect var_teacher

	REM	Адрес файла кода пользователя
	SET	T_DIR=c:\acm\dir_tmp\

	REM	Строка связи
	SET	STR_LINK=@//localhost/avtdb

	REM	логин/пароль@строка связи администратора
	SET	ADMIN_STR=system/Admin001

	REM	логин/пароль@строка связи пользователя
	SET	USER=user%1
	SET	USER_STR=%USER%/%USER%

	REM	Исходная схема для копирования таблиц
	SET	SCHEME=buses0_creator

	REM	Название файла с генерацией стартового кода
	SET	F_NAME=%1.stt


REM	Запускаем программу pl_sql2.exe в командной строке передаются имя файла и запрещённые выражения для пользователя
REM	первый параметр - имя файла с кодом пользователя
REM	пример - "pl_sql2.exe %1 DANG" - появление этих строк в коде пользователя будет отслеживаться
REM	**************************************************
	%COMP_ADR%pl_sql2.exe %1 %DANG%
REM	**************************************************

REM Анализ кода завершения
IF ERRORLEVEL 2 GOTO ERROR_CH_SQL
GOTO NEXT
:ERROR_CH_SQL


GOTO ONEXIT

:NEXT

@echo	--Создание пользователя> %F_NAME%
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

REM	Добавляем к запросу пользователя служебную информацию
ECHO	it's guid string -------------------->> %F_NAME%
ECHO	%ADMIN_STR%%STR_LINK%>> %F_NAME%
ECHO	%USER_STR%%STR_LINK%>> %F_NAME%
ECHO	%SCHEME%>> %F_NAME%
ECHO	drop user %USER% cascade>> %F_NAME%

GOTO ONEXIT
    :ONEXIT
