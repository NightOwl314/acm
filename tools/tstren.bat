@echo off

set PREFIX=zashishennoe_soobshenie_
set IN_SUFFIX=_input.txt 
set OUT_SUFFIX=_pattern.txt 
del /Q index.lst

for /l %%i in (1,1,9) do (
 if NOT EXIST %PREFIX%0%%i%IN_SUFFIX% goto ok
 ren %PREFIX%0%%i%IN_SUFFIX% 0%%i.in
 ren %PREFIX%0%%i%OUT_SUFFIX% 0%%i.out
 echo 0%%i>>index.lst
)

for /l %%i in (10,1,99) do (
 if NOT EXIST %PREFIX%%%i%IN_SUFFIX% goto ok
 ren %PREFIX%%%i%IN_SUFFIX% %%i.in
 ren %PREFIX%%%i%OUT_SUFFIX% %%i.out
 echo %%i>>index.lst
)

:OK
