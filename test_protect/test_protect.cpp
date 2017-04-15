//-- ������������� � ���������� ������������� (� �� � DWORD � ��...)

#pragma pack(1)

#include <windows.h>
#include <cstring>
#include <string>
#include <fstream>
#include <tlhelp32.h>
#include <cstdio>

#include "test_protect.h"
#include "..\common_cpp\result_id.h"
#include "..\common_cpp\shared_types.h"
#include "..\common_cpp\log_support.h"

using namespace std;

#pragma pack(1)

//���� ��� ������ ������ ��� ��������
Tstek tree_stek(500);

//������ ������ �������
DWORD adr_ExitProc,adr_SV;
DWORD adr_LoadLibraryA,adr_LoadLibraryW,adr_LoadLibraryExA,adr_LoadLibraryExW;

//������ DLL ������� � ������� ���� ���������
TDll mas_dll[100];
int cntdll=0; //���������� DLL

//������������ ��� ���������� � ������ ������ �������
TList *n_el,*c_el,*pred_el;

//������� ������� ������
//  (1-�� ��������� ���������� ��������� ����� ������ ������������ �������)
int debug_protect=0;

//��������� ��� ����������� ����� � ��������� ��� ������ ������ ������ 2
int id_uniq=0;

//���� ��� �������� ����������� ������ ������ � main_mod.exe
ofstream svlog;

//��� ����
TLogFile flog;

//������� ������ ������� ��� ������� ������
DWORD buff_sv[200000],cnt_sv=0;

//��� ������ ������ ������������� ����� �������� ���� ���������� ����������
TStartThisDll StartThisDll;

//����� ����� � DLL (������-�� ���������� �� ������, ������� �� ������������)
extern "C" int APIENTRY WINAPI DllMain(HANDLE, DWORD , LPVOID)
{
   return TRUE;
}

//���������� ��� �������� ���� DLL
TStartThisDll::TStartThisDll(void)
{
   char s[20],log_fl[MAX_PATH];

   GetEnvironmentVariable("LogFile",log_fl,MAX_PATH);
   flog.open(log_fl,ios::app|ios::out);

   //����� ������ ����
   GetEnvironmentVariable("WriteExLog",s,19);
   flog.SetLevelLog(atoi(s));

   flog.SetFunc("StartThisDll");
   flog.ln() << t << fb;

   //����� ������� ������ ������
   GetEnvironmentVariable("debug_protect",s,19);
   debug_protect=atoi(s);

   //���������� ������������� ���������� ����������� ��������
   GetEnvironmentVariable("IdUnique",s,19);
   id_uniq=atoi(s);

   sprintf(log_fl,"%d\\SV_log.txt",id_uniq);
   svlog.open(log_fl,ios::app|ios::out);

   //�������� ������ ��������� ������ �������
   adr_ExitProc=(DWORD)GetProcAddress(GetModuleHandle("kernel32.dll"),"ExitProcess");
   adr_LoadLibraryA=(DWORD)GetProcAddress(GetModuleHandle("kernel32.dll"),"LoadLibraryA");
   adr_LoadLibraryW=(DWORD)GetProcAddress(GetModuleHandle("kernel32.dll"),"LoadLibraryW");
   adr_LoadLibraryExA=(DWORD)GetProcAddress(GetModuleHandle("kernel32.dll"),"LoadLibraryExA");
   adr_LoadLibraryExW=(DWORD)GetProcAddress(GetModuleHandle("kernel32.dll"),"LoadLibraryExW");
   
   //������� ���� ������� �� ���� �������
   SwapAllModules();
   
   flog.ln() << t << fe;
}

//���������� ����� ������(��������) � ������� ���������� ��������� �������(��� ������ �����)
HMODULE ModuleFromAddress(PVOID pv)
{
   MEMORY_BASIC_INFORMATION mbi;
   return((VirtualQuery(pv, &mbi, sizeof(mbi)) != 0)
      ? (HMODULE) mbi.AllocationBase : NULL);
}

//����������� ��� ����������� ������ � �������� ������������ ������������ ��������
//��� ������� ������ �������� ������������� �������
void SwapAllModules(void)
{
   HANDLE hSnapshot;

   flog.SetFunc("SwapAllModules");
   flog.ln() << fb;

   //������� ������ ������� ����������� � �������� ������������
   hSnapshot=CreateToolhelp32Snapshot(TH32CS_SNAPMODULE, GetCurrentProcessId());
   if (hSnapshot==INVALID_HANDLE_VALUE)
      flog.ApiErr("CreateToolhelp32Snapshot");

   //���������� ��� ������
   MODULEENTRY32 me = { sizeof(me) };
   flog.ln() << "for each module...\n";
   for (BOOL fOk = Module32First(hSnapshot, &me); fOk; fOk = Module32Next(hSnapshot,&me)) {
      flog.ln(1) << "module=" << me.szModule << "\n";
      SwapAllFunctions(me.hModule);
   }

   CloseHandle(hSnapshot);

   //������ ����� ��� ������� ��������� ������ ���������� ������� �� ������ ������
   UseWhiteList();

   //����� ����� ����� ������� security violation
   SaveStatusFunc(0);
   flog.ln() << fe;
}

//��������� ��������� ������� ��� ���� ����������� �������
//0-��� ������ ����������� �������
//1-��� ��������� ����������� �������
void SaveStatusFunc(int bl)
{
   int i;
   flog.SetFunc("SaveStatusFunc");
   flog.ln() << fb;

   for (i=0;i<cntdll;i++) {  //����� ���� DLL
      c_el=mas_dll[i].root;

      tree_stek.init();
      while (true) { //����� ������ ������� ��� ��������
         if (c_el==NULL) {
            if (tree_stek.empty()) break;
            tree_stek.pop((void**)&c_el);

            if (bl) {
               c_el->callcnt1=c_el->callcnt;
               c_el->callcnt=-1;
            } else c_el->callcnt=c_el->callcnt1;

            c_el=c_el->right;
         } else {
            tree_stek.push(c_el);
            c_el=c_el->left;
         }
      }
   }
   flog.ln() << fe;
}

//�������� ����� ���� ����� �������
void SwapFunction(DWORD adr_new_f, DWORD adr_old_f)
{
   DWORD buf,op;
   unsigned long written,r;

   flog.SetFunc("SwapFunction");
   flog.ln() << fb;

   //�������� ����� �� ���� �������
   buf=adr_new_f;

   //�������� � ���� ������� ���������� ��� ������, ������������� ��������� ������
   r=VirtualProtect((void*)(adr_old_f),4,PAGE_READWRITE, &op);
   if (!r) flog.ApiErr("VirtualProtect PAGE_READWRITE");

   //����� ����� �����
   WriteProcessMemory(GetCurrentProcess(), (void*)(adr_old_f),
                    (void*)&buf,4,&written);
   if (!r) flog.ApiErr("WriteProcessMemory");

   //��������������� �������������� ������ ������� �� ������
   VirtualProtect((void*)(adr_old_f),4,op, &op);
   if (!r) flog.ApiErr("VirtualProtect RESTORE");
   flog.ln() << fe;
}

//���������� ���������� ������� �� ������ ������
void UseWhiteList(void)
{
   char wl_name[300],func_name[120];
   string dll_name,s;
   int c_call,dll_i,sravn;
   ifstream inp;

   flog.SetFunc("UseWhiteList");
   flog.ln() << fb;

   GetEnvironmentVariable("wl_name",wl_name,300);

   inp.open(wl_name);
   if (inp==NULL) {
      flog.err() << "file not found! \"" << wl_name << "\"\n";
      return;
   }

   //������������� ������ ������
   while (s[0]==' ') s.erase(0,1); 
   while (!inp.eof()) {
      inp >> s;
      s.read_line(inp);
      if (s=="") continue;
      else if (s.substr(0,4)=="dll=") {
         dll_name=s.substr(4);
      char *c = dll_name.c_str();
	  while(*c) { *c = toupper(*c); c++; }

         //������� ��� DLL ������
         dll_i=0;
         while(dll_i<cntdll && strcmp(dll_name.c_str(),mas_dll[dll_i].name)!=0) dll_i++;
      } else {
         if (dll_i==cntdll) continue;//�� �����

         //��� �������
         strcpy(func_name,s.substr(0,s.find_first_of(" ")).c_str());

         //���� ������� ����� �����������
         c_el=mas_dll[dll_i].root;
         while (c_el!=NULL) {
            sravn=strcmp(func_name,c_el->name);
            if (sravn>0) {
               c_el=c_el->right;
            }  else if (sravn<0) {
               c_el=c_el->left;
            } else break;
         }
         if (c_el==NULL) continue; //�� �����

         //���������� ����������� �������
         c_call=atoi(s.substr(s.find_last_of(" ")).c_str());
         c_el->callcnt1=c_call;
         c_el->callcnt_start=c_call;
      }
   }

   inp.close();
   flog.ln() << fe;
}

//������ ���� ������������� ������� ��� ������� ������
void SwapAllFunctions(HINSTANCE pimage)
{
   // ����������� ��������� �������� PE ���������
   IMAGE_DOS_HEADER *idh;
   IMAGE_OPTIONAL_HEADER *ioh;
   IMAGE_IMPORT_DESCRIPTOR *iid;
   DWORD *isd1,*isd2;
   TCodeForAll CFA;

   int mode,dll_i,sravn;
   char func_name[120],fln[MAX_PATH],*func_name_ptr;

   ifstream func_file;
   string dll_name;

   flog.SetFunc("SwapAllFunctions");
   flog.ln() << fb;
   if (pimage==NULL || ModuleFromAddress(SwapAllModules)==pimage) {
      flog.ln() << fe;
      return;
   }

   // �������� ��������� �� ����������� ��������� ������ PE ���������
   idh = (IMAGE_DOS_HEADER*)pimage;
   //���� ��� ���������� ��������� DOS-��������� �� �������
   if (idh->e_magic!=IMAGE_DOS_SIGNATURE) {
      flog.ln() << fe;
      return;
   }

   ioh = (IMAGE_OPTIONAL_HEADER*)((BYTE*)pimage + idh->e_lfanew
                                 + 4 + sizeof(IMAGE_FILE_HEADER));
   //���� ��� ���������� ��������� ������������� ��������� �� �������
   if (ioh->Magic!=0x10b/*IMAGE_NT_OPTIONAL_HDR32_MAGIC*/ ||
      //��� ����������� �����(RVA) ������ ������� ����� NULL
      !ioh->DataDirectory[1].VirtualAddress) {
      flog.ln() << fe;
      return;
   }

   iid = (IMAGE_IMPORT_DESCRIPTOR*)((BYTE*)pimage + ioh->DataDirectory[1].VirtualAddress);

   //�������� ����������� ���� ����������
   CFA.instr_mov1=0x0D8B;
   CFA.instr_cmp=0xF983;
   CFA.arg_cmp=0;
   CFA.instr_jnz=0x0B75;
   CFA.instr_push1=0x68;
   CFA.instr_call1=0x15FF;
   CFA.instr_dec=0x0DFF;
   CFA.instr_popecx=0x59;
   CFA.instr_mov2=0x0D89;
   CFA.instr_call2=0x15FF;
   CFA.instr_push2=0x35FF;
   CFA.instr_ret=0xC3;
   CFA.adr_exit_func=(DWORD)&adr_SV;
   adr_SV=(DWORD)Security_violation;

   if (pimage == (BYTE*)GetModuleHandle(NULL)) {

      sprintf(fln,"%d\\list_ifunc.txt",id_uniq);
      func_file.open(fln);
      if (func_file==NULL) mode=1;
      else mode=2;
   } else mode=1;

   flog.ln() << "for each DLL...\n";

   while(iid->Name) { //�� ��� ��� ���� ���� ��������� �� �������� 0

      dll_name=string((char*)((BYTE*)pimage + iid->Name));
	  
	  char *c = dll_name.c_str();
	  while(*c) { *c = toupper(*c); c++; }

      flog.ln(1) << "DLL=" << dll_name.c_str() << "\n";

      //������� ��� DLL � ������
      dll_i=0;
      while(dll_i<cntdll && strcmp(dll_name.c_str(),mas_dll[dll_i].name)!=0) dll_i++;
      if (dll_i==cntdll) {//�� �����
         //������� ����� DLL � ������
         mas_dll[cntdll].name=new char[dll_name.length()+1];
         strcpy(mas_dll[cntdll].name,dll_name.c_str());
         mas_dll[cntdll].root=NULL;
         cntdll++;
      }

      //������ ����� (��������� �� ����������� ���)
      isd1 = (DWORD*)((BYTE*)pimage + (DWORD)iid->FirstThunk);

      //������ ����� (��������� �� ��������)
      if (mode==1) isd2 = (DWORD*)((BYTE*)pimage + (DWORD)iid->OriginalFirstThunk);

      while(*isd1!=0)  {
         if (mode==1) func_name_ptr=(char*)(*isd2+2+(BYTE*)pimage);
         if (mode==2) {
            func_file >> func_name;
            func_name_ptr=(char*)func_name;
         }

         c_el=mas_dll[dll_i].root;
         while (c_el!=NULL) {
            pred_el=c_el;
            sravn=strcmp(func_name_ptr,c_el->name);
            if (sravn>0) {
               c_el=c_el->right;
            }  else if (sravn<0) {
               c_el=c_el->left;
            } else break;
         }

         flog.ln(2) << "func=" << func_name_ptr << "\n";

         if (c_el==NULL) { //������� ������� � ������ ����, �� ��� �� ����
            n_el=new TList;
            n_el->name=new char[strlen(func_name_ptr)+1];
            strcpy(n_el->name,func_name_ptr);
            n_el->callcnt=-1;
            n_el->callcnt1=0;
            n_el->callcnt_start=0;
            n_el->buff=0;
            n_el->left=NULL;
            n_el->right=NULL;
            n_el->adrcall=*isd1;
            n_el->dll_name=mas_dll[dll_i].name;

            //������� ������� ��� ������ �������, ������� ���������� ��������
            if (dll_name=="KERNEL32.DLL") {
               if (strcmp(func_name_ptr,"ExitProcess")==0) n_el->adrcall=(DWORD)Intercept_ExitProc;
               if (strcmp(func_name_ptr,"LoadLibraryExA")==0) n_el->adrcall=(DWORD)Intercept_LoadLibraryExA;
               if (strcmp(func_name_ptr,"LoadLibraryExW")==0) n_el->adrcall=(DWORD)Intercept_LoadLibraryExW;
               if (strcmp(func_name_ptr,"LoadLibraryA")==0) n_el->adrcall=(DWORD)Intercept_LoadLibraryA;
               if (strcmp(func_name_ptr,"LoadLibraryW")==0) n_el->adrcall=(DWORD)Intercept_LoadLibraryW;
            }

            memmove(&n_el->CFA,&CFA,sizeof(TCodeForAll));

            //�������� ������������ ������ ��� ����� �������
            n_el->CFA.adr_cnt1=(DWORD)&n_el->callcnt;
            n_el->CFA.adr_cnt2=(DWORD)&n_el->callcnt;
            n_el->CFA.adr_src_func=(DWORD)&n_el->adrcall;
            n_el->CFA.sec_voil_code=(DWORD)n_el;
            n_el->CFA.adr_buff1=(DWORD)&n_el->buff;
            n_el->CFA.adr_buff2=(DWORD)&n_el->buff;

            if (mas_dll[dll_i].root==NULL)
               mas_dll[dll_i].root=n_el;
            else {
               if (sravn>0) pred_el->right=n_el;
               else pred_el->left=n_el;
            }

            c_el=n_el;
         }

         if (dll_name!="MSVCRT.DLL" ) {
            //������� ������ � ������� �������
            SwapFunction((DWORD)&c_el->CFA, (DWORD)isd1);
         }

         isd1++;
         if (mode==1) isd2++;
      }

      iid++;
   }

   if (mode==2) func_file.close();

   flog.ln() << fe;
}

//���������� ���������� ��������
extern "C" VOID WINAPI Intercept_ExitProc( UINT uExitCode )
{
   //�������� �������� ������ �������
   SaveStatusFunc(1);

   //��������� ������������������ ������� ����������� �������
   for (unsigned int i=0;i<cnt_sv;i++) {
      svlog << ((TList*)buff_sv[i])->dll_name << endl;
      svlog << ((TList*)buff_sv[i])->name << endl;
      svlog << ((TList*)buff_sv[i])->callcnt_start << endl;
   }

   svlog.close();

   Sleep(30); //��������, ����� ������� ������ ����� ���������� ��� �����������
   if (cnt_sv) uExitCode=EXIT_CODE_SECURITY_VIOLATION;

   //��� ������� ������� �������� ������� �������
   TerminateProcess(GetCurrentProcess(),uExitCode); 
}

//������� ������� ����������� �-���
extern "C" VOID WINAPI Security_violation(DWORD xxx)
{

   if (debug_protect==1) { //����� ������� ������
      //������� ����� ������� � ������ �������
      buff_sv[cnt_sv++]=xxx;
      ((TList*)xxx)->callcnt=1; 
   } else {
      //������������� ����������� ����� ���� �������
      SaveStatusFunc(1);
      Sleep(30); //��������, ����� ������� ������ ����� ���������� ��� �����������

      //�������� �������� �������, ������� ������������ ������� �������
      svlog << ((TList*)xxx)->dll_name << endl;
      svlog << ((TList*)xxx)->name << endl;
      svlog << ((TList*)xxx)->callcnt_start << endl;
      svlog.close();

      //��� ������� ������� �������� ������� �������
      TerminateProcess(GetCurrentProcess(),EXIT_CODE_SECURITY_VIOLATION);
   }
}

//---------------------------------------------------------------------------

extern "C" HINSTANCE WINAPI Intercept_LoadLibraryExA(LPCTSTR  lpLibFileName, HANDLE  hFile,  DWORD  dwFlags )
{
   HINSTANCE hModule;
   //����� ��������� �������
   hModule=((HINSTANCE (__stdcall*)(LPCTSTR,HANDLE,DWORD))adr_LoadLibraryExA)(lpLibFileName,hFile,dwFlags);
   return NULL; //��������� DLL ������������ � �� ������!!!
}

extern "C" HINSTANCE WINAPI Intercept_LoadLibraryExW(LPCTSTR  lpLibFileName, HANDLE  hFile,  DWORD  dwFlags )
{
   HINSTANCE hModule;
   //����� ��������� �������
   hModule=((HINSTANCE (__stdcall*)(LPCTSTR,HANDLE,DWORD))adr_LoadLibraryExW)(lpLibFileName,hFile,dwFlags);
   return NULL; //��������� DLL ������������ � �� ������!!!
}

extern "C" HINSTANCE WINAPI Intercept_LoadLibraryA(LPCTSTR  lpLibFileName)
{
   HINSTANCE hModule;
   //����� ��������� �������
   hModule=((HINSTANCE (__stdcall*)(LPCTSTR))adr_LoadLibraryA)(lpLibFileName);
   return NULL; //��������� DLL ������������ � �� ������!!!
}

extern "C" HINSTANCE WINAPI Intercept_LoadLibraryW(LPCTSTR  lpLibFileName)
{
   HINSTANCE hModule;
   //����� ��������� �������
   hModule=((HINSTANCE (__stdcall*)(LPCTSTR))adr_LoadLibraryW)(lpLibFileName);
   return NULL; //��������� DLL ������������ � �� ������!!!
}

