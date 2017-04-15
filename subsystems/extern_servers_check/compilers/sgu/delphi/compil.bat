@echo off
c:\acm\compilers\sgu\delphi\compil.exe %1 %2 %3 %4
if not ERRORLEVEL 1 copy c:\acm\compilers\sgu\delphi\Proj.exe %1.exe