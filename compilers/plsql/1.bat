@echo off
sqlplus system/Admin001@//localhost/avtdb @1.out > 1.log
DEL C:\acm\compilers\plsql\123.stt
DEL 1.bat
