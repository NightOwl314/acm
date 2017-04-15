    @echo off
    c:
    cd c:\acm\dir_tmp
    set TEMP=c:\acm\dir_TMP
    set TMP=c:\acm\dir_TMP

copy /Y c:\acm\compilers\vbs\options.ini c:\acm\dir_tmp\options.ini 
copy /Y c:\acm\compilers\vbs\libeay32.dll c:\acm\dir_tmp\libeay32.dll 
copy /Y c:\acm\compilers\vbs\ssleay32.dll c:\acm\dir_tmp\ssleay32.dll 
copy /Y c:\acm\compilers\vbs\vix.dll c:\acm\dir_tmp\vix.dll 
copy /Y c:\acm\compilers\vbs\test_util.exe c:\acm\dir_tmp\test_util.exe 

   "c:\acm\compilers\vbs\compiler.exe" %1.vbs c:\acm\compilers\vbs\run.exe
    copy %1.exe qqq.exe
