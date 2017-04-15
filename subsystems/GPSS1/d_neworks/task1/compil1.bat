copy model1.mdl c:\GPSS1\
cd /d c:\GPSS1\
writestart @model1.mdl
gpsspc.exe
gpssrept 2.in
copy 2.in d:\networks\task1\
