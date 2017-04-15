@echo off
c:\acm\compilers\timus\pascal\compil.exe %1 %2 %3 %4
if not ERRORLEVEL 1 copy c:\acm\compilers\timus\pascal\proj.exe %1.exe