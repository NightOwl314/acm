//---------------------------------------------------------------------------

#ifndef testingH
#define testingH
//---------------------------------------------------------------------------
#include "..\common_cpp\shared_types.h"
#include "readconfig.h"

extern unsigned int TestSolve(TPaths *pt, unsigned int *time, unsigned int *mem, unsigned int *test_num, int id_cmp);
extern void err(const char *s);
extern void DelOldSrc(int cur_src);

BOOL InjectDll(DWORD pid,HANDLE hMainThread, char *lpszDllName);
unsigned int MemUseSize(HANDLE hProcess);
int FileExists(char *filename);
int RunProblem(TPaths *pt, unsigned int *time_lim, unsigned int *mem_lim, unsigned int *error_n);
void SaveImportFuncList(char *file_exe, char *file_list);
void AddFileInOtchet(char *otchet_fl, char *file);
void SavePointTime(char *msg);
void AddSecurityViolationInOtchet(char *file_otchet, char *file_sv_log, int id_cmp);
__int64 GetIdleTimes(void);

struct TList{
   char *name;
   int callcnt_start;
   TList *left;
   TList *right;
};

struct TDll{
   char *name;
   ::TList *root;
};

//---------------------------------------------------------------------------
#endif
