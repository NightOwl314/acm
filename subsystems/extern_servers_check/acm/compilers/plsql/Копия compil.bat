@echo off
	REM	Запрещённые выражения для файла пользователя******************************
	SET	DANG=commit tablee trigger value %1
	REM	Адрес файла кода пользователя
	SET	NAM=c:\acm\dir_tmp\%1

	COPY /Y %1 i2.%1 > %1.out

@echo	--Создание пользователя > i.%1
@echo	Create user i%1 >> i.%1
@echo	identified by i%1 >> i.%1
@echo	default tablespace USERS >> i.%1
@echo	temporary tablespace TEMP; >> i.%1
@echo	Grant connect, resource to i%1; >> i.%1
@echo	connect i%1/i%1@orcl >> i.%1
@echo	@i2.%1 >> i.%1
@echo	rollback; >> i.%1
@echo	connect system/manager@orcl >> i.%1
@echo	drop user i%1 cascade; >> i.%1
@echo	exit; >> i.%1

REM	ОБЯЗАТЕЛЬНО***********************************
REM	Запускаем программу pl_sql2.exe в командной строке передаются имя файла и запрещённые выражения для пользователя
REM	первый параметр - имя файла с кодом пользователя
REM	пример - "pl_sql2.exe %1 DANG" - появление этих строк в коде пользователя будет отслеживаться
REM	**************************************************
	c:\acm\compilers\plsql\pl_sql2.exe %1 %DANG%
REM	C:\diplom\ishodniki\pl_sql2.exe %1 %DANG%

REM	**************************************************

REM Анализ кода завершения
IF ERRORLEVEL 2 GOTO ERROR_CH_SQL
GOTO NEXT
:ERROR_CH_SQL

GOTO ONEXIT

:NEXT
REM	О Б Я З А Т Е Л Ь Н О****************************
REM 	Укажите полный путь до файла с кодом пользователя
@echo	%NAM%> %1"psw"
REM	*************************************************


rem echo	rollback; >> i2.%1
rem echo	drop user i%1 cascade; >> i2.%1	

echo	quit|sqlplus system/manager@orcl @i.%1 > %1.out
REM	C:\diplom\ishodniki\plsql3.exe %1.out ora- sp2-
REM	C:\diplom\ishodniki\plsql3.exe %1.out ora- sp2-
	c:\acm\compilers\plsql\plsql3.exe %1.out ora- sp2-

IF ERRORLEVEL 1 GOTO ERROR_CH
GOTO ONEXIT
    :ERROR_CH
rem COPY /Y "c:\acm\compilers\plsql\555.exe" %1.bat

echo	sqlplus i%1/i%1@orcl @i2.%1 > %1.out
echo	c:\acm\compilers\plsql\pl_sql2.exe %1 %DANG% >> %1.out

@echo	123 > %1.bat
GOTO ONEXIT
    :ONEXIT
ECHO %ERRORLEVEL% > www.txt