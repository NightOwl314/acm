@echo off
	REM	Адрес папки для обработки PLSQL******************************
	SET	COMP_ADR=c:\acm\compilers\plsql\

	REM	Запрещённые выражения для кода пользователя******************************
	SET	DANG=commit connect %1

	REM	Адрес файла кода пользователя
	SET	T_DIR=c:\acm\dir_tmp\

	REM	Строка связи
	SET	STR_LINK=@orcl

	REM	логин/пароль@строка связи администратора
	SET	ADMIN_STR=system/manager

	REM	логин/пароль@строка связи пользователя
	SET	USER=user%1
	SET	USER_STR=%USER%/%USER%

	REM	Исходная схема для копирования таблиц
	SET	SCHEME=kvn

	REM	Исходная схема для копирования таблиц (строка подключения)
	SET	SCHEME_STR=kvn/virus

	REM	Название файла с генерацией стартового кода
	SET	F_NAME=create


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

@echo	--Создание пользователя> %F_NAME%.%1
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

REM	Добавляем к запросу пользователя служебную информацию
ECHO	it's guid string -------------------->> %1
ECHO	%ADMIN_STR%%STR_LINK%>> %1
ECHO	%USER_STR%%STR_LINK%>> %1
ECHO	%SCHEME%>> %1
ECHO	drop user %USER% cascade>> %1

GOTO ONEXIT
    :ONEXIT