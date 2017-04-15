    @echo off

    set path="C:\Program Files (x86)\CodeBlocks\MinGW\bin";%path%

rem компилируем и линкуем исходник
   "C:\Program Files (x86)\CodeBlocks\MinGW\bin\g++.exe" -O2 -std=c++11 -Xlinker --stack=0x4000000 %1.cpp  -o %1.exe 2>&1

rem если слинковалось, проводим обработку для анализа плагиата
   if not ERRORLEVEL 1 (

      rem получаем объектный файл
      "C:\Program Files (x86)\CodeBlocks\MinGW\bin\g++" -Xlinker --stack=0x4000000 %1".cpp" -c -o %1"_.o"
      
      rem удаляем символы из объектного файла
      "C:\FPC\bin\i386-win32\strip.exe" %1"_.o"
      
      rem переименовываем объектный файл
      ren %1"_.o" %1".nul"

   )
