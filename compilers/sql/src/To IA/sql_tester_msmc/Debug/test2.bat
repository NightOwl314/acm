@echo off
cls
echo begin: > report.txt
set file=sql_tester.exe
set /a j=2;
copy /y .\test\%j%\1.txt 1.txt
copy /y .\test\%j%\2.txt 2.txt
copy /y .\test\%j%\3.txt 3.txt
IF EXIST .\test\%j%\error.txt (set answer=ERROR) ELSE (set answer=OK)
%file% 1.txt 2.txt 3.txt
IF ERRORLEVEL 1 (
ECHO TEST%j% = {ERROR-%answer%} >> report.txt
rem чтобы можно было посмотреть ошибку
mkdir .\test\%j%\out
copy /y 2.txt .\test\%j%\out\2.txt
copy /y 3.txt .\test\%j%\out\3.txt
) ELSE (ECHO TEST%j% = {OK-%answer%} >> report.txt)

report.txt
