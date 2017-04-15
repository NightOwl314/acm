    @echo off
    c:
    cd c:\acm\dir_tmp
    set TEMP=c:\acm\dir_TMP
    set TMP=c:\acm\dir_TMP

copy /Y c:\acm\compilers\js\options.ini c:\acm\dir_tmp\options.ini 
copy /Y c:\acm\compilers\js\libeay32.dll c:\acm\dir_tmp\libeay32.dll 
copy /Y c:\acm\compilers\js\ssleay32.dll c:\acm\dir_tmp\ssleay32.dll 
copy /Y c:\acm\compilers\js\vix.dll c:\acm\dir_tmp\vix.dll 
copy /Y c:\acm\compilers\js\test_util.exe c:\acm\dir_tmp\test_util.exe 

   "c:\acm\compilers\js\compiler.exe" %1.js c:\acm\compilers\js\run.exe
    copy %1.exe qqq.exe
