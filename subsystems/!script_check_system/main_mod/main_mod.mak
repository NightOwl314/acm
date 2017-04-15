#
# Borland C++ IDE generated makefile
# Generated 26.05.2007 at 16:14:47 
#
.AUTODEPEND


#
# Borland C++ tools
#
IMPLIB  = Implib
BCC32   = Bcc32 +BccW32.cfg 
BCC32I  = Bcc32i +BccW32.cfg 
TLINK32 = TLink32
ILINK32 = Ilink32
TLIB    = TLib
BRC32   = Brc32
TASM32  = Tasm32
#
# IDE macros
#


#
# Options
#
IDE_LinkFLAGS32 =  -LC:\cpp\BC5\LIB
IDE_ResFLAGS32 = 
LinkerLocalOptsAtW32_main_moddexe =  -v -Tpe -aa -V4.0 -c -LC:\PROGRAMS\BC5\LIB
ResLocalOptsAtW32_main_moddexe = 
BLocalOptsAtW32_main_moddexe = 
CompInheritOptsAt_main_moddexe = -IC:\PROGRAMS\BC5\INCLUDE 
LinkerInheritOptsAt_main_moddexe = -x
LinkerOptsAt_main_moddexe = $(LinkerLocalOptsAtW32_main_moddexe)
ResOptsAt_main_moddexe = $(ResLocalOptsAtW32_main_moddexe)
BOptsAt_main_moddexe = $(BLocalOptsAtW32_main_moddexe)
CompLocalOptsAtW32_db_funcdcpp =  -a
LinkerLocalOptsAtW32_db_funcdcpp = 
ResLocalOptsAtW32_db_funcdcpp = 
BLocalOptsAtW32_db_funcdcpp = 
CompOptsAt_db_funcdcpp = $(CompOptsAt_main_moddexe) $(CompLocalOptsAtW32_db_funcdcpp)
CompInheritOptsAt_db_funcdcpp = -IC:\PROGRAMS\BC5\INCLUDE 
LinkerInheritOptsAt_db_funcdcpp = -x
LinkerOptsAt_db_funcdcpp = $(LinkerOptsAt_main_moddexe) $(LinkerLocalOptsAtW32_db_funcdcpp)
ResOptsAt_db_funcdcpp = $(ResOptsAt_main_moddexe) $(ResLocalOptsAtW32_db_funcdcpp)
BOptsAt_db_funcdcpp = $(BOptsAt_main_moddexe) $(BLocalOptsAtW32_db_funcdcpp)
CompLocalOptsAtW32_main_moddcpp = 
LinkerLocalOptsAtW32_main_moddcpp = 
ResLocalOptsAtW32_main_moddcpp = 
BLocalOptsAtW32_main_moddcpp = 
CompOptsAt_main_moddcpp = $(CompOptsAt_main_moddexe) $(CompLocalOptsAtW32_main_moddcpp)
CompInheritOptsAt_main_moddcpp = -IC:\PROGRAMS\BC5\INCLUDE 
LinkerInheritOptsAt_main_moddcpp = -x
LinkerOptsAt_main_moddcpp = $(LinkerOptsAt_main_moddexe) $(LinkerLocalOptsAtW32_main_moddcpp)
ResOptsAt_main_moddcpp = $(ResOptsAt_main_moddexe) $(ResLocalOptsAtW32_main_moddcpp)
BOptsAt_main_moddcpp = $(BOptsAt_main_moddexe) $(BLocalOptsAtW32_main_moddcpp)

#
# Dependency List
#
Dep_main_mod = \
   main_mod.exe

main_mod : BccW32.cfg $(Dep_main_mod)
  echo MakeNode

Dep_main_moddexe = \
   com_substr_cnt.obj\
   testing.obj\
   log_support.obj\
   swap_message.obj\
   readconfig.obj\
   db_func.obj\
   gds32.lib\
   main_mod.obj

main_mod.exe : $(Dep_main_moddexe)
  $(ILINK32) @&&|
 /v $(IDE_LinkFLAGS32) $(LinkerOptsAt_main_moddexe) $(LinkerInheritOptsAt_main_moddexe) +
C:\PROGRAMS\BC5\LIB\c0w32.obj+
com_substr_cnt.obj+
testing.obj+
log_support.obj+
swap_message.obj+
readconfig.obj+
db_func.obj+
main_mod.obj
$<,$*
gds32.lib+
C:\PROGRAMS\BC5\LIB\import32.lib+
C:\PROGRAMS\BC5\LIB\cw32mt.lib



|
com_substr_cnt.obj :  com_substr_cnt.cpp
  $(BCC32) -c @&&|
 $(CompOptsAt_main_moddexe) $(CompInheritOptsAt_main_moddexe) -o$@ com_substr_cnt.cpp
|

testing.obj :  testing.cpp
  $(BCC32) -c @&&|
 $(CompOptsAt_main_moddexe) $(CompInheritOptsAt_main_moddexe) -o$@ testing.cpp
|

log_support.obj :  ..\common_cpp\log_support.cpp
  $(BCC32) -c @&&|
 $(CompOptsAt_main_moddexe) $(CompInheritOptsAt_main_moddexe) -o$@ ..\common_cpp\log_support.cpp
|

swap_message.obj :  ..\common_cpp\swap_message.cpp
  $(BCC32) -c @&&|
 $(CompOptsAt_main_moddexe) $(CompInheritOptsAt_main_moddexe) -o$@ ..\common_cpp\swap_message.cpp
|

readconfig.obj :  readconfig.cpp
  $(BCC32) -c @&&|
 $(CompOptsAt_main_moddexe) $(CompInheritOptsAt_main_moddexe) -o$@ readconfig.cpp
|

db_func.obj :  db_func.cpp
  $(BCC32) -c @&&|
 $(CompOptsAt_db_funcdcpp) $(CompInheritOptsAt_db_funcdcpp) -o$@ db_func.cpp
|

main_mod.obj :  main_mod.cpp
  $(BCC32) -c @&&|
 $(CompOptsAt_main_moddcpp) $(CompInheritOptsAt_main_moddcpp) -o$@ main_mod.cpp
|

# Compiler configuration file
BccW32.cfg : 
   Copy &&|
-w
-R
-v
-WM-
-vi
-H
-H=main_mod.csm
-6
-a
-rd
-f
-ff
-X
-Oi
-OM
-OI
-v
-R
-k
-y
-N
-vi-
-5
-a
-WM
-W
-Od
-r-
-O-i
-O-M
-O-I
-H-
| $@


