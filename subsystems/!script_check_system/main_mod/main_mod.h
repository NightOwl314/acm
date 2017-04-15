
#ifndef main_modH
#define main_modH

#include <windows.h>
#include "..\common_cpp\shared_types.h"
#include "readconfig.h"
#include <fstream>

using namespace std;

extern TConfig *master_cfg;
extern ofstream logf;

void WhileTestSolve(void);
void StrReplace(char *str_src, char *str_find, char *str_new);

#endif
