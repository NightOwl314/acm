copy model.mdl c:\GPSS1\
cd /d c:\GPSS1\
writestart @model.mdl
gpsspc.exe
gpssrept 1.in
copy 1.in d:\networks\task1\
REM запустить проверяющую программу, если проверка прошла перезаписываем 2, файл программы и запускаем еще 2 раза
 

