//---------------------------------------------------------------------------

#ifndef testingH
#define testingH
//---------------------------------------------------------------------------
#include "..\common_cpp\shared_types.h"
#include "readconfig.h"

extern unsigned int TestSolve(TPaths *pt, double *time, unsigned int *mem, unsigned int *test_num, int id_cmp, int &points, int hardlevel, bool preliminary);
extern void DelOldSrc(int cur_src);
extern __int64 TimeStamp();
extern __int64 GetCPUSpeed(void);
extern __int64 CPUSpeed;

BOOL InjectDll(DWORD pid,HANDLE hMainThread, char *lpszDllName);
unsigned int MemUseSize(HANDLE hProcess);
int FileExists(char *filename);
int RunProblem(TPaths *pt, double *time_lim, unsigned int *mem_lim, unsigned int *error_n, int run_checker);
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
