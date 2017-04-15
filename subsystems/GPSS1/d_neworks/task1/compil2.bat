copy model2.mdl c:\GPSS1\
cd /d c:\GPSS1\
writestart @model2.mdl
gpsspc.exe
gpssrept 3.in
copy 3.in d:\networks\task1\
