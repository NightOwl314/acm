//-- компилировать с побайтовым выравниванием (а не с DWORD и тп...)

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

//стек для обхода дерева без рекурсии
Tstek tree_stek(500);

//адреса важных функций
DWORD adr_ExitProc,adr_SV;
DWORD adr_LoadLibraryA,adr_LoadLibraryW,adr_LoadLibraryExA,adr_LoadLibraryExW;

//массив DLL функции в которых были подменены
TDll mas_dll[100];
int cntdll=0; //количество DLL

//используются при построении и обходе дерева функций
TList *n_el,*c_el,*pred_el;

//признак отладки защиты
//  (1-не прерывает выполнение программы после вызова недопустимой функции)
int debug_protect=0;

//необходим для определения файла с функциями при режиме работы защиты 2
int id_uniq=0;

//файл для передачи результатов работы защиты в main_mod.exe
ofstream svlog;

//лог файл
TLogFile flog;

//порядок вызова функций при отладке защиты
DWORD buff_sv[200000],cnt_sv=0;

//эта строка должна располагаться после описания всех глобальных переменных
TStartThisDll StartThisDll;

//точка входа в DLL (почему-то вызывается не всегда, поэтому не используется)
extern "C" int APIENTRY WINAPI DllMain(HANDLE, DWORD , LPVOID)
{
   return TRUE;
}

//вызывается при загрузке этой DLL
TStartThisDll::TStartThisDll(void)
{
   char s[20],log_fl[MAX_PATH];

   GetEnvironmentVariable("LogFile",log_fl,MAX_PATH);
   flog.open(log_fl,ios::app|ios::out);

   //режим работы лога
   GetEnvironmentVariable("WriteExLog",s,19);
   flog.SetLevelLog(atoi(s));

   flog.SetFunc("StartThisDll");
   flog.ln() << t << fb;

   //режим отладки белого списка
   GetEnvironmentVariable("debug_protect",s,19);
   debug_protect=atoi(s);

   //уникальный идентификатор переданный проверяющим сервером
   GetEnvironmentVariable("IdUnique",s,19);
   id_uniq=atoi(s);

   sprintf(log_fl,"%d\\SV_log.txt",id_uniq);
   svlog.open(log_fl,ios::app|ios::out);

   //сохраним адреса некоторых важных функций
   adr_ExitProc=(DWORD)GetProcAddress(GetModuleHandle("kernel32.dll"),"ExitProcess");
   adr_LoadLibraryA=(DWORD)GetProcAddress(GetModuleHandle("kernel32.dll"),"LoadLibraryA");
   adr_LoadLibraryW=(DWORD)GetProcAddress(GetModuleHandle("kernel32.dll"),"LoadLibraryW");
   adr_LoadLibraryExA=(DWORD)GetProcAddress(GetModuleHandle("kernel32.dll"),"LoadLibraryExA");
   adr_LoadLibraryExW=(DWORD)GetProcAddress(GetModuleHandle("kernel32.dll"),"LoadLibraryExW");
   
   //подмена всех функций во всех модулях
   SwapAllModules();
   
   flog.ln() << t << fe;
}

//возвращает адрес модуля(сегмента) в котором содержится указанная функция(или другой адрес)
HMODULE ModuleFromAddress(PVOID pv)
{
   MEMORY_BASIC_INFORMATION mbi;
   return((VirtualQuery(pv, &mbi, sizeof(mbi)) != 0)
      ? (HMODULE) mbi.AllocationBase : NULL);
}

//перечисляет все загруженные модули в адресном пространстве проверяемого процесса
//для каждого модуля заменяет импортируемые функции
void SwapAllModules(void)
{
   HANDLE hSnapshot;

   flog.SetFunc("SwapAllModules");
   flog.ln() << fb;

   //сдалаем снимок модулей загруженных в адресное пространство
   hSnapshot=CreateToolhelp32Snapshot(TH32CS_SNAPMODULE, GetCurrentProcessId());
   if (hSnapshot==INVALID_HANDLE_VALUE)
      flog.ApiErr("CreateToolhelp32Snapshot");

   //перечислим все модули
   MODULEENTRY32 me = { sizeof(me) };
   flog.ln() << "for each module...\n";
   for (BOOL fOk = Module32First(hSnapshot, &me); fOk; fOk = Module32Next(hSnapshot,&me)) {
      flog.ln(1) << "module=" << me.szModule << "\n";
      SwapAllFunctions(me.hModule);
   }

   CloseHandle(hSnapshot);

   //теперь когда все функции подменены укажем количество вызовов из белого списка
   UseWhiteList();

   //после этого может настать security violation
   SaveStatusFunc(0);
   flog.ln() << fe;
}

//сохраняет количесто вызовов для всех подмененных функций
//0-при начале мониторинга вызовов
//1-при окончании мониторинга вызовов
void SaveStatusFunc(int bl)
{
   int i;
   flog.SetFunc("SaveStatusFunc");
   flog.ln() << fb;

   for (i=0;i<cntdll;i++) {  //обход всех DLL
      c_el=mas_dll[i].root;

      tree_stek.init();
      while (true) { //обход дерева функций без рекурсии
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

//заменяет адрес кода одной функции
void SwapFunction(DWORD adr_new_f, DWORD adr_old_f)
{
   DWORD buf,op;
   unsigned long written,r;

   flog.SetFunc("SwapFunction");
   flog.ln() << fb;

   //Заменяем адрес на свою функцию
   buf=adr_new_f;

   //страницы в этой области недоступны для записи, принудительно разрешаем запись
   r=VirtualProtect((void*)(adr_old_f),4,PAGE_READWRITE, &op);
   if (!r) flog.ApiErr("VirtualProtect PAGE_READWRITE");

   //Пишем новый адрес
   WriteProcessMemory(GetCurrentProcess(), (void*)(adr_old_f),
                    (void*)&buf,4,&written);
   if (!r) flog.ApiErr("WriteProcessMemory");

   //восстанавливаем первоначальную защиту области по записи
   VirtualProtect((void*)(adr_old_f),4,op, &op);
   if (!r) flog.ApiErr("VirtualProtect RESTORE");
   flog.ln() << fe;
}

//заполнение количества вызовов из белого списка
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

   //инициализация белого списка
   while (s[0]==' ') s.erase(0,1); 
   while (!inp.eof()) {
      inp >> s;
      s.read_line(inp);
      if (s=="") continue;
      else if (s.substr(0,4)=="dll=") {
         dll_name=s.substr(4);
      char *c = dll_name.c_str();
	  while(*c) { *c = toupper(*c); c++; }

         //находим эту DLL списке
         dll_i=0;
         while(dll_i<cntdll && strcmp(dll_name.c_str(),mas_dll[dll_i].name)!=0) dll_i++;
      } else {
         if (dll_i==cntdll) continue;//не нашли

         //имя функции
         strcpy(func_name,s.substr(0,s.find_first_of(" ")).c_str());

         //ищем функцию среди подмененных
         c_el=mas_dll[dll_i].root;
         while (c_el!=NULL) {
            sravn=strcmp(func_name,c_el->name);
            if (sravn>0) {
               c_el=c_el->right;
            }  else if (sravn<0) {
               c_el=c_el->left;
            } else break;
         }
         if (c_el==NULL) continue; //не нашли

         //количество разрешенных вызовов
         c_call=atoi(s.substr(s.find_last_of(" ")).c_str());
         c_el->callcnt1=c_call;
         c_el->callcnt_start=c_call;
      }
   }

   inp.close();
   flog.ln() << fe;
}

//замена всех импортируемых функций для данного модуля
void SwapAllFunctions(HINSTANCE pimage)
{
   // Стандартные структуры описания PE заголовка
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

   // Получаем указатели на стандартные структуры данных PE заголовка
   idh = (IMAGE_DOS_HEADER*)pimage;
   //если нет правильной сигнатуры DOS-заголовка то выходим
   if (idh->e_magic!=IMAGE_DOS_SIGNATURE) {
      flog.ln() << fe;
      return;
   }

   ioh = (IMAGE_OPTIONAL_HEADER*)((BYTE*)pimage + idh->e_lfanew
                                 + 4 + sizeof(IMAGE_FILE_HEADER));
   //если нет правильной сигнатуры опционального заголовка то выходим
   if (ioh->Magic!=0x10b/*IMAGE_NT_OPTIONAL_HDR32_MAGIC*/ ||
      //или виртуальный адрес(RVA) секции импорта равен NULL
      !ioh->DataDirectory[1].VirtualAddress) {
      flog.ln() << fe;
      return;
   }

   iid = (IMAGE_IMPORT_DESCRIPTOR*)((BYTE*)pimage + ioh->DataDirectory[1].VirtualAddress);

   //заполним статические коды инструкций
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

   while(iid->Name) { //до тех пор пока поле структуры не содержит 0

      dll_name=string((char*)((BYTE*)pimage + iid->Name));
	  
	  char *c = dll_name.c_str();
	  while(*c) { *c = toupper(*c); c++; }

      flog.ln(1) << "DLL=" << dll_name.c_str() << "\n";

      //находим эту DLL в списке
      dll_i=0;
      while(dll_i<cntdll && strcmp(dll_name.c_str(),mas_dll[dll_i].name)!=0) dll_i++;
      if (dll_i==cntdll) {//не нашли
         //добавим новую DLL в список
         mas_dll[cntdll].name=new char[dll_name.length()+1];
         strcpy(mas_dll[cntdll].name,dll_name.c_str());
         mas_dll[cntdll].root=NULL;
         cntdll++;
      }

      //первая копия (указатель на выполняемый код)
      isd1 = (DWORD*)((BYTE*)pimage + (DWORD)iid->FirstThunk);

      //вторая копия (указатель на название)
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

         if (c_el==NULL) { //добавим функцию в список если, ее там не было
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

            //двойная обертка для важных функций, которые подменяюся отдельно
            if (dll_name=="KERNEL32.DLL") {
               if (strcmp(func_name_ptr,"ExitProcess")==0) n_el->adrcall=(DWORD)Intercept_ExitProc;
               if (strcmp(func_name_ptr,"LoadLibraryExA")==0) n_el->adrcall=(DWORD)Intercept_LoadLibraryExA;
               if (strcmp(func_name_ptr,"LoadLibraryExW")==0) n_el->adrcall=(DWORD)Intercept_LoadLibraryExW;
               if (strcmp(func_name_ptr,"LoadLibraryA")==0) n_el->adrcall=(DWORD)Intercept_LoadLibraryA;
               if (strcmp(func_name_ptr,"LoadLibraryW")==0) n_el->adrcall=(DWORD)Intercept_LoadLibraryW;
            }

            memmove(&n_el->CFA,&CFA,sizeof(TCodeForAll));

            //заполним динамические адреса для новой функции
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
            //подмена адреса в таблице импорта
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

//завершение выполнения процесса
extern "C" VOID WINAPI Intercept_ExitProc( UINT uExitCode )
{
   //отменяем контроль вызова функций
   SaveStatusFunc(1);

   //сохраняем последовательность вызовов запрещенных функций
   for (unsigned int i=0;i<cnt_sv;i++) {
      svlog << ((TList*)buff_sv[i])->dll_name << endl;
      svlog << ((TList*)buff_sv[i])->name << endl;
      svlog << ((TList*)buff_sv[i])->callcnt_start << endl;
   }

   svlog.close();

   Sleep(30); //ожидание, чтобы внешний модуль успел определить все необходимое
   if (cnt_sv) uExitCode=EXIT_CODE_SECURITY_VIOLATION;

   //эта команда надежно завершит текущий процесс
   TerminateProcess(GetCurrentProcess(),uExitCode); 
}

//попытка вызвать запрещенную ф-цию
extern "C" VOID WINAPI Security_violation(DWORD xxx)
{

   if (debug_protect==1) { //режим отладки защиты
      //заносим адрес функции в список вызовов
      buff_sv[cnt_sv++]=xxx;
      ((TList*)xxx)->callcnt=1; 
   } else {
      //предотвращает рекурсивный вызов этой функции
      SaveStatusFunc(1);
      Sleep(30); //ожидание, чтобы внешний модуль успел определить все необходимое

      //сохраним название функции, которую пользователь пытался вызвать
      svlog << ((TList*)xxx)->dll_name << endl;
      svlog << ((TList*)xxx)->name << endl;
      svlog << ((TList*)xxx)->callcnt_start << endl;
      svlog.close();

      //эта команда надежно завершит текущий процесс
      TerminateProcess(GetCurrentProcess(),EXIT_CODE_SECURITY_VIOLATION);
   }
}

//---------------------------------------------------------------------------

extern "C" HINSTANCE WINAPI Intercept_LoadLibraryExA(LPCTSTR  lpLibFileName, HANDLE  hFile,  DWORD  dwFlags )
{
   HINSTANCE hModule;
   //вызов настоящей функции
   hModule=((HINSTANCE (__stdcall*)(LPCTSTR,HANDLE,DWORD))adr_LoadLibraryExA)(lpLibFileName,hFile,dwFlags);
   return NULL; //загрузить DLL неполучилось и не должно!!!
}

extern "C" HINSTANCE WINAPI Intercept_LoadLibraryExW(LPCTSTR  lpLibFileName, HANDLE  hFile,  DWORD  dwFlags )
{
   HINSTANCE hModule;
   //вызов настоящей функции
   hModule=((HINSTANCE (__stdcall*)(LPCTSTR,HANDLE,DWORD))adr_LoadLibraryExW)(lpLibFileName,hFile,dwFlags);
   return NULL; //загрузить DLL неполучилось и не должно!!!
}

extern "C" HINSTANCE WINAPI Intercept_LoadLibraryA(LPCTSTR  lpLibFileName)
{
   HINSTANCE hModule;
   //вызов настоящей функции
   hModule=((HINSTANCE (__stdcall*)(LPCTSTR))adr_LoadLibraryA)(lpLibFileName);
   return NULL; //загрузить DLL неполучилось и не должно!!!
}

extern "C" HINSTANCE WINAPI Intercept_LoadLibraryW(LPCTSTR  lpLibFileName)
{
   HINSTANCE hModule;
   //вызов настоящей функции
   hModule=((HINSTANCE (__stdcall*)(LPCTSTR))adr_LoadLibraryW)(lpLibFileName);
   return NULL; //загрузить DLL неполучилось и не должно!!!
}

