
#ifndef main_modH
#define main_modH

#include <windows.h>
#include <fstream>
#include "..\common_cpp\shared_types.h"
#include "readconfig.h"
#include "db_func.h"

using namespace std;

extern TConfig *master_cfg;
extern ofstream logfl;
extern TDataBase DB;
extern void err(const char *s);
extern void info2log(const char *s);

void WhileTestSolve(void);
void StrReplace(char *str_src, char *str_find, char *str_new);

#endif
