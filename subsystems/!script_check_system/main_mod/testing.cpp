//---------------------------------------------------------------------------
#define _WIN32_WINNT 0x0500

#include <windows.h>

#include <winternl.h>

#include <cstring>
#include <string>
#include <fstream>
#include <stdio.h>
#include "..\common_cpp\result_id.h"
#include "testing.h"
#include "main_mod.h"


#include <userenv.h>

//---------------------------------------------------------------------------

using namespace std;


//������ ��������� �� ������
void err(const char *s)
{
    logf << "error : " << s << "\n";
    MessageBoxA(NULL, s, "Error!", 0);
}

//�������� dll � ��������� �������
BOOL InjectDll(DWORD pid, HANDLE hMainThread, char *lpszDllName)
{
  HANDLE hProcess;
  BYTE *p_code;
  DWORD wr, id;
  unsigned long (__stdcall *thread_addr)(void *) ;


  //������� ������� � ������ ��������
  hProcess=OpenProcess(PROCESS_CREATE_THREAD|PROCESS_VM_WRITE|
                       PROCESS_VM_OPERATION, FALSE, pid);
  if (hProcess == NULL) {
    err("You have not enough rights to attach dlls");
    return FALSE;
  }

  //��������������� ������ � ��������
  p_code = (BYTE*)VirtualAllocEx(hProcess, 0, MAX_PATH,
                                 MEM_COMMIT, PAGE_EXECUTE_READWRITE);
  if (p_code==NULL) {
      err("Unable to alloc memory in remote process");
      return FALSE;
  }

  if (strlen(lpszDllName)>MAX_PATH) {
     err("Dll Name too long");
     return FALSE;
  }

  //�������� �������� dll � ����������������� ������ � ��������� ��������
  WriteProcessMemory(hProcess, p_code, lpszDllName, (strlen(lpszDllName)+1)*2, &wr);

  thread_addr=(unsigned long (__stdcall *)(void *))
              GetProcAddress(GetModuleHandle("kernel32.dll"), "LoadLibraryA");
  HANDLE z = CreateRemoteThread(hProcess, NULL, 0,
               thread_addr, p_code, 0, &id); //������� ��������� �����

  SuspendThread(hMainThread);//��� ������ ���� �� win2k Server � win2003

  //������� ���������� ���������� ������
  WaitForSingleObject(z, INFINITE);

  CloseHandle(z);

  //���������� ������
  VirtualFreeEx(hProcess, (void*)p_code, MAX_PATH, MEM_RELEASE);
  CloseHandle(hProcess);

  return TRUE;
}

//���������� ������ ������ ������������ ��������� (KB)
unsigned int MemUseSize(HANDLE hProcess)
{
   LPCVOID pvMax = (LPCVOID)0x77000000; //�������� ��� �������� ������������ ��������
                                        //�� ��������� DLL
   LPCVOID pvAddress = (LPCVOID)0;

   MEMORY_BASIC_INFORMATION buf;
   unsigned int actsz,sz_commit=0;
   while (pvAddress<pvMax) {
      actsz=VirtualQueryEx(hProcess,pvAddress,&buf,sizeof(buf));
      if (actsz==0) break;
      if (buf.State==MEM_COMMIT && buf.Type!=MEM_MAPPED) {
         sz_commit+=buf.RegionSize;
         }

      pvAddress = (LPCVOID)((DWORD)pvAddress + buf.RegionSize);
   }

   return (sz_commit/1024);
}

//������� ��������� ����������� ������� � ����������:
//"Accepted"
//"WA"
//"Run Time Error"
//"Time Limit"
//"Memory Limit"
//"Security violation"
//"Sleep detect"
//��������� 3 ��������� ��������:
//����� ������ (ms), ������ �������������� ������ (KB), ��� ��������
int RunProblem(TPaths *pt, unsigned int *time_lim, unsigned int *mem_lim, unsigned int *error_n)
{
   unsigned int ec,cTime=0,cOldTime=0,minus_time=0,minus_mem=0;
   __int64 tm_stamp,end_sleep;
   FILETIME cr,ex,kr,ur;
   int ret=RS_ACCEPTED,cMem=0,mm;
   BOOL er;
   char WACmd[400],fln[MAX_PATH];

   *error_n=0;

   //���������� ���������, ������������ � .DLL
   char env[MAX_PATH*3], *ienv;
   memset(env, 0, MAX_PATH*3);
   if (pt->WLFile!=NULL) {
      ienv=env;
      sprintf(ienv,"wl_name=%s",pt->WLFile);
      ienv=ienv+strlen(ienv)+1;
      sprintf(ienv,"debug_protect=%d",pt->debug_protect);
      ienv=ienv+strlen(ienv)+1;
      sprintf(ienv,"LogFile=%s",master_cfg->GlobalPaths->LogFile);
      ienv=ienv+strlen(ienv)+1;
      sprintf(ienv,"WriteExLog=%d",master_cfg->Options->WriteExLog);
      ienv=ienv+strlen(ienv)+1;
      sprintf(ienv,"IdUnique=%d",pt->id_uniq);
   }

   PROCESS_INFORMATION ProcessInfo; //����������� �������� CreateProcess

   OFSTRUCT FileInfo;
   memset(&FileInfo, 0, sizeof(OFSTRUCT));
   FileInfo.cBytes = sizeof(OFSTRUCT);

   //������� ���� �����
   HANDLE hInput=(void*)OpenFile(pt->inpF,&FileInfo,OF_READ);

   //�������� ���� ������
   HANDLE hOutput=CreateFile(pt->outF,
       GENERIC_WRITE,0,NULL,CREATE_ALWAYS,FILE_ATTRIBUTE_NORMAL,NULL);

   //�������� ���� ������
   HANDLE hError=CreateFile(pt->errF,
       GENERIC_WRITE,0,NULL,CREATE_ALWAYS,FILE_ATTRIBUTE_NORMAL,NULL);


   //�������� ��������� ��� �������� � ����������� �������
   HANDLE hStdOut=NULL, hStdIn=NULL, hStdErr=NULL;
   DuplicateHandle(GetCurrentProcess(), hOutput, GetCurrentProcess(),
                   &hStdOut, 0, TRUE, DUPLICATE_SAME_ACCESS);
   DuplicateHandle(GetCurrentProcess(), hInput, GetCurrentProcess(),
                   &hStdIn, 0, TRUE, DUPLICATE_SAME_ACCESS);
   DuplicateHandle(GetCurrentProcess(), hError, GetCurrentProcess(),
                   &hStdErr, 0, TRUE, DUPLICATE_SAME_ACCESS);

   STARTUPINFO StartupInfo;
   memset(&StartupInfo, 0, sizeof(STARTUPINFO));
   StartupInfo.cb=sizeof(STARTUPINFO);
   StartupInfo.dwFlags=STARTF_USESTDHANDLES|STARTF_USESHOWWINDOW;
   StartupInfo.wShowWindow=SW_HIDE;
   StartupInfo.hStdInput=hStdIn;
   StartupInfo.hStdOutput=hStdOut;
   StartupInfo.hStdError=hStdErr;

   //�� ���������� ��������� �� �������
   UINT old_err_st=SetErrorMode(SEM_NOGPFAULTERRORBOX);

   //�������� ������� � ������ ������
      er=CreateProcess(NULL, pt->FileTest,
        NULL, NULL, TRUE, CREATE_SUSPENDED|IDLE_PRIORITY_CLASS,
        NULL, master_cfg->GlobalPaths->DirTemp, &StartupInfo, &ProcessInfo);

/*   er=CreateProcess(NULL, pt->FileTest,
        NULL, NULL, TRUE, CREATE_SUSPENDED|IDLE_PRIORITY_CLASS,
        env, master_cfg->GlobalPaths->DirTemp, &StartupInfo, &ProcessInfo);
*/
  /* er=CreateProcess(NULL, "c:\\acm\\compilers\\ddd.bat < test.vbs > out.out",
        NULL, NULL, TRUE, NORMAL_PRIORITY_CLASS,
        NULL, master_cfg->GlobalPaths->DirTemp, &StartupInfo, &ProcessInfo);
*/
/*   LPCWSTR s1(TEXT("u1")),s2("avt.vstu.edu.ru"),s2("medved");
      er=CreateProcessWithLogonW(s1,s2,s3,LOGON_WITH_PROFILE, 
          NULL, pt->FileTest,
        CREATE_SUSPENDED|IDLE_PRIORITY_CLASS,
        env, master_cfg->GlobalPaths->DirTemp, &StartupInfo, &ProcessInfo);
  */ //������� ��� ����� ����� ��� ������ �� �����
   CloseHandle(hInput);
   CloseHandle(hOutput);
   CloseHandle(hError);
   CloseHandle(hStdIn);
   CloseHandle(hStdOut);
   CloseHandle(hStdErr);

   if (!er) {
      err((string(pt->FileTest)+" �� �����������!").c_str());
      return RS_RUN_TIME_ERROR;
   }

   if (pt->protect!=0) {
      minus_mem=MemUseSize(ProcessInfo.hProcess);

      //�������� API �������
      if (!InjectDll(ProcessInfo.dwProcessId,ProcessInfo.hThread,pt->dllF))
         return RS_SECURITY_VIOLATION;

      GetProcessTimes(ProcessInfo.hProcess,&cr,&ex,&kr,&ur);
      minus_time=kr.dwLowDateTime+ur.dwLowDateTime;
      minus_mem=MemUseSize(ProcessInfo.hProcess)-minus_mem;
   }

   //������ ������� ����� ��������
   while (ResumeThread(ProcessInfo.hThread)>1);

   //�������� ����
   end_sleep=tm_stamp=0;
   while (cTime<*time_lim && cMem<(int)*mem_lim && (end_sleep-tm_stamp)>=0) {
      tm_stamp=GetIdleTimes();

      mm=MemUseSize(ProcessInfo.hProcess)-minus_mem;

      if (mm>cMem) cMem=mm;

      GetProcessTimes(ProcessInfo.hProcess,&cr,&ex,&kr,&ur);
      cTime=(unsigned int)(kr.dwLowDateTime+ur.dwLowDateTime-minus_time)/1.0e4;

      //����������� �����������
      if ((cTime-cOldTime)>9 || !end_sleep) {
         cOldTime=cTime;
         end_sleep=tm_stamp+1000;
      }

      GetExitCodeProcess(ProcessInfo.hProcess,(unsigned long *)&ec);
      if (ec!=STILL_ACTIVE) break; //���� ����������

      Sleep(10);
   }

   //"Time limit"
   if (cTime>=*time_lim) {
      TerminateProcess(ProcessInfo.hProcess,0);
      WaitForSingleObject(ProcessInfo.hProcess, INFINITE);
      ret=RS_TIME_LIMIT;
   } else

   //"Memory limit"
   if (cMem>=(int)*mem_lim) {
      TerminateProcess(ProcessInfo.hProcess,0);
      WaitForSingleObject(ProcessInfo.hProcess, INFINITE);
      ret=RS_MEMORY_LIMIT;
   } else

   //"Sleep detect"
   if (end_sleep-tm_stamp<0) {
      TerminateProcess(ProcessInfo.hProcess,0);
      WaitForSingleObject(ProcessInfo.hProcess, INFINITE);
      ret=RS_SLEEP_DETECT;
   } else

   //"Security violation"
   if (ec==EXIT_CODE_SECURITY_VIOLATION) {
      ret=RS_SECURITY_VIOLATION;
   } else

   //"Run Time Error"
   if (ec!=0) {
      ret=RS_RUN_TIME_ERROR;
      *error_n=ec;
   }

   *time_lim=cTime;
   *mem_lim=(unsigned int)cMem;

   CloseHandle(ProcessInfo.hProcess);
   CloseHandle(ProcessInfo.hThread);

   //�������� WA
   if (ret==0 && pt->WAProg!=NULL) {
      Sleep(20);
      hOutput=CreateFile(pt->checker_outF,
         GENERIC_WRITE,0,NULL,CREATE_ALWAYS,FILE_ATTRIBUTE_NORMAL,NULL);

      DuplicateHandle(GetCurrentProcess(), hOutput, GetCurrentProcess(),
                   &hStdOut, 0, TRUE, DUPLICATE_SAME_ACCESS);

      STARTUPINFO si;
      memset(&si, 0, sizeof(STARTUPINFO));
      si.cb=sizeof(STARTUPINFO);
      si.wShowWindow=SW_HIDE;
      si.dwFlags=STARTF_USESTDHANDLES|STARTF_USESHOWWINDOW;
      si.hStdInput=NULL;
      si.hStdOutput=hStdOut;
      si.hStdError=NULL;

      sprintf(WACmd,"%s %s %s %s",pt->WAProg,pt->inp,pt->tst,pt->out);

      sprintf(fln,"%s%s",pt->dir_temp,pt->out);
      CopyFile(pt->correct_outF,fln,FALSE);
      strcpy(pt->correct_outF,fln);
      pt->correct_outF_del=1;

      er=CreateProcess(NULL, WACmd,
           NULL, NULL, TRUE, IDLE_PRIORITY_CLASS,
           NULL, pt->dir_temp, &si, &ProcessInfo);

      CloseHandle(hOutput);
      CloseHandle(hStdOut);

      if (!er) {
         err((string(WACmd)+" �� �����������!").c_str());
         ret=RS_PRESENTATION_ERROR;
      } else {

         ec=STILL_ACTIVE;
         end_sleep=tm_stamp=0;
         while (cTime<master_cfg->Options->CheckerTimeLimit && (end_sleep-tm_stamp)>=0) {
            tm_stamp=GetIdleTimes();
            GetProcessTimes(ProcessInfo.hProcess,&cr,&ex,&kr,&ur);
            cTime=(unsigned int)(kr.dwLowDateTime+ur.dwLowDateTime)/1.0e4;

            //����������� �����������
            if ((cTime-cOldTime)>50 || !end_sleep) {
               cOldTime=cTime;
               end_sleep=tm_stamp+master_cfg->Options->CheckerSleepLimit;
            }

            GetExitCodeProcess(ProcessInfo.hProcess,(unsigned long *)&ec);
            if (ec!=STILL_ACTIVE) break; //���� ����������

            Sleep(10);
         }

         if (ec==STILL_ACTIVE) {
           TerminateProcess(ProcessInfo.hProcess,10);
           WaitForSingleObject(ProcessInfo.hProcess, INFINITE);
         }

         GetExitCodeProcess(ProcessInfo.hProcess,(unsigned long *)&ec);
         switch (ec) {
            case 0: ret=RS_ACCEPTED; break;
            case 1: ret=RS_WRONG_ANSWER; break;
            default: ret=RS_PRESENTATION_ERROR;
         }
      }

      CloseHandle(ProcessInfo.hProcess);
      CloseHandle(ProcessInfo.hThread);
   }

   //����������� ��������� ��������� ������
   SetErrorMode(old_err_st);

   return ret;
}

//�������� ������� �� ������ ������ ������ ��� ��������� ������
unsigned int TestSolve(TPaths *pt, unsigned int *time, unsigned int *mem, unsigned int *test_num, int id_cmp)
{
   int i,flpos;
   unsigned int r=-1,time1,mem1,max_t=0,max_m=0,er;
   char s[50],list_func[MAX_PATH],slong[MAX_PATH];
   ifstream list;
   ofstream otchet,t_fl;

   //������� ������ ������
   list.open(pt->ListTests);
   if (list.bad()!=0) {
      logf << "error: open file: " << pt->ListTests << "\n";
      return -1;
   }

   sprintf(list_func,"%slist_ifunc.txt",pt->dir_temp);
   if (pt->protect==2) 
      SaveImportFuncList(pt->FileTest, list_func); //��������� � ���� ������ ������������� �������
   else DeleteFile(list_func); //�� ������ ������, ����� �������

   otchet.open(pt->otchetF,ios::out|ios::app);
   otchet << "</pre><table cellpadding=5 border=1><tr><th>test N</th><th>input file</th><th>correct file</th>"
          << "<th>result</th><th>time worked</th><th>memory usage</th></tr>\n";

   i=1;
   *test_num=0;
   flpos=list.tellg();
   while (!list.eof()) {  //���� ���� �����
      list.getline(s,50);

      //�������������� ������� ������ �� �����
      if (flpos==list.tellg()) break;
      else flpos=list.tellg();

      if (strlen(s)==0) continue;

      pt->inpF_del=0;
      pt->correct_outF_del=0;

      //����������� ����� � ������ ��� ������ �����
      sprintf(pt->checker_outF,"%schecker.out",pt->dir_temp);
      sprintf(pt->inpF,"%s%s.in",pt->DirTests,s);
      sprintf(pt->outF,"%s%s.tst",pt->dir_temp,s);
      sprintf(pt->errF,"%s%s.err",pt->dir_temp,s);
      sprintf(pt->correct_outF,"%s%s.out",pt->DirTests,s);

      sprintf(pt->tst,"%s.tst",s);
      sprintf(pt->out,"%s.out",s);
      sprintf(pt->inp,"%s.in",s);

      if (!FileExists(pt->inpF) || !FileExists(pt->correct_outF))  continue;
      else { //�������� �������� ������� ���� ����� (�� ����� ���� � ����)
         sprintf(slong,"%s%s",pt->dir_temp,pt->inp);
         CopyFile(pt->inpF,slong,FALSE);
         strcpy(pt->inpF,slong);
         pt->inpF_del=1;
      }

      otchet << "<tr align=center><td>" << i << "</td><td>" << pt->inp << "</td><td>"
             << pt->out << "</td>";

      time1=*time;
      mem1=*mem;
      r=RunProblem(pt,&time1,&mem1,&er); //����������� ������ �����
      Sleep(20);

      otchet << "<td>" << r << "</td><td>" << (float)time1/1000.0
             << " sec</td><td>" << mem1 << " KB</td></tr>\n";

      if (time1>max_t) max_t=time1;
      if (mem1>max_m) max_m=mem1;
      if (r!=RS_ACCEPTED) {
         *test_num=i;
         break;
      }

      pt->del_temp_files(); //������� ��������� �����
      i++;
   }

   otchet << "</table><pre>\n";

   //���������� � ������ �������������� ������ ����������
   // � ����������� �� ���������� ��������
   if (r==RS_RUN_TIME_ERROR) {
      wsprintf(slong,"Process exit code 0x%08x", er);

      otchet << "<strong>RUN TIME ERROR: </strong>" << er <<"\n\n";
      t_fl.open(pt->errF,ios::out|ios::app);
      if (t_fl) {
         t_fl << "\n"<<slong<<"\n";
      }
      t_fl.close();
   }

   if (r==RS_SECURITY_VIOLATION) {
      otchet.close();
      sprintf(slong,"%ssv_log.txt",pt->dir_temp);
      AddSecurityViolationInOtchet(pt->otchetF,slong,id_cmp);
      otchet.open(pt->otchetF,ios::out|ios::app);
   }

   if (r!=RS_ACCEPTED) {

      otchet << "<strong>----------- output -----------</strong>\n";
      otchet.close();
      AddFileInOtchet(pt->otchetF,pt->outF);
      otchet.open(pt->otchetF,ios::out|ios::app);

      otchet << "\n<strong>------- correct output -------</strong>\n";
      otchet.close();
      AddFileInOtchet(pt->otchetF,pt->correct_outF);
      otchet.open(pt->otchetF,ios::out|ios::app);

      otchet << "\n<strong>----------- input -----------</strong>\n";
      otchet.close();
      AddFileInOtchet(pt->otchetF,pt->inpF);
      otchet.open(pt->otchetF,ios::out|ios::app);
   }


   if (r==RS_WRONG_ANSWER || r==RS_PRESENTATION_ERROR) {
      otchet << "\n<strong>------- checker output -------</strong>\n";
      otchet.close();
      AddFileInOtchet(pt->otchetF,pt->checker_outF);
      otchet.open(pt->otchetF,ios::out|ios::app);
   }

   sprintf(slong,"%ssv_log.txt",pt->dir_temp);
   DeleteFile(slong);

   list.close();
   if (pt->protect==2) DeleteFile(list_func);

   otchet.close();

   *time=max_t;
   *mem=max_m;
   return r;
}

//�������� ������������� �����
int FileExists(char *filename)
{
  HANDLE hnd;
  WIN32_FIND_DATA FD;

  hnd=FindFirstFile(filename, &FD);
  if (hnd!=INVALID_HANDLE_VALUE) {
    FindClose(hnd);
    if ((FD.dwFileAttributes & FILE_ATTRIBUTE_DIRECTORY) == 0)
      return 1;

  }
  return 0;
}

//�������� ������ �������� ������� � ������������ � master.cfg
void DelOldSrc(int cur_src)
{
   char file[MAX_PATH],s[20];
   for (int i=0;i<10;i++) {
      itoa(cur_src-i-master_cfg->Options->SourceCountArh,s,16); //hex
      sprintf(file,"%s%s.src",master_cfg->GlobalPaths->DirSrcArhive,s);
      if (FileExists(file)) DeleteFile(file);
      sprintf(file,"%s%s.otch",master_cfg->GlobalPaths->DirSrcArhive,s);
      if (FileExists(file)) DeleteFile(file);
   }
}

//��������� � ���� ����� ������������� �������
void SaveImportFuncList(char *file_exe, char *file_list)
{
   size_t sz;
   DWORD sz1;
   char *buff;
   OFSTRUCT FileInfo;
   HANDLE hInput;

   memset(&FileInfo, 0, sizeof(OFSTRUCT));
   FileInfo.cBytes = sizeof(OFSTRUCT);

   hInput=(void*)OpenFile(file_exe,&FileInfo,OF_READ);
   sz=GetFileSize(hInput,NULL);
   buff=new char[sz];
   ReadFile(hInput,buff,sz,&sz1,NULL);
   CloseHandle(hInput);

   ofstream outp(file_list,ios::out);

   BYTE *pimage = (BYTE*)buff;

   // ����������� ��������� �������� PE ���������
   IMAGE_DOS_HEADER *idh;
   IMAGE_OPTIONAL_HEADER *ioh;
   IMAGE_IMPORT_DESCRIPTOR *iid;
   IMAGE_FILE_HEADER *ifh;
   IMAGE_SECTION_HEADER *hSection;
   DWORD *isd1, sec_cnt, i, offset_iid,VirtAdrTI;

   string dll_name,func_name;

   // �������� ��������� �� ����������� ��������� ������ PE ���������
   idh=(IMAGE_DOS_HEADER*)pimage;
   ifh=(IMAGE_FILE_HEADER*)(pimage+idh->e_lfanew+4);
   //���������� ������
   sec_cnt=ifh->NumberOfSections;
   ioh = (IMAGE_OPTIONAL_HEADER*)(pimage+idh->e_lfanew+4+ sizeof(IMAGE_FILE_HEADER));

   //����������� ����� ������� �������
   VirtAdrTI = ioh->DataDirectory[1].VirtualAddress;

   //������ ������� ������
   hSection = IMAGE_FIRST_SECTION(pimage+idh->e_lfanew);

   //������ ������ � ������� ����������� ������� �������
   for (i=0;i<sec_cnt;i++) {
      if (hSection->VirtualAddress<=VirtAdrTI &&
          (hSection->VirtualAddress+hSection->Misc.VirtualSize)>VirtAdrTI) {

           //�������� �� ������ ����� �� ������� �������
           offset_iid=hSection->PointerToRawData;
           break;
      }
      hSection++;
   }

   iid = (IMAGE_IMPORT_DESCRIPTOR*)(pimage + VirtAdrTI - hSection->VirtualAddress + offset_iid);
   while(iid->Name) { //�� ��� ��� ���� ���� ��������� �� �������� 0

      isd1 = (DWORD*)(pimage + (DWORD)iid->FirstThunk-hSection->VirtualAddress+offset_iid);

      while(*isd1!=0)  {
         func_name=string((char*)(*isd1+2+pimage-hSection->VirtualAddress+offset_iid));
         outp << func_name <<"\n";
         isd1++;
      }

      iid++;
   }

   outp.close();

   delete[] buff;
}

//��������� ���� � ����� �������� ��� ������
void AddFileInOtchet(char *otchet_fl, char *file)
{
   ifstream tmp;
   ofstream otchet;
   int sz,i, blksz=10000;
   char *bf;

   bf=new char[blksz+1];

   otchet.open(otchet_fl,ios::out|ios::app|ios::binary);
   tmp.open(file,ios::binary);
   sz=1024*master_cfg->Options->MaxFileSizeAddOtchet;
   while (tmp!=NULL && sz>0) {
      tmp.read(bf,blksz);
      i=tmp.gcount();
      if (i==0) break;
      if (sz-i<0) {
         bf[sz]='\0';
      } else bf[i]='\0';
      otchet << bf;
      sz-=i;
   }
   tmp.close();
   otchet.close();
   otchet.open(otchet_fl,ios::out|ios::app);
   if (sz<0) otchet << "\n<strong>file very long...</strong>\n";
   otchet.close();

   delete[] bf;
}

//��������� � ����� ������ ���������� � ������ ����������� �������
void AddSecurityViolationInOtchet(char *file_otchet, char *file_sv_log, int id_cmp)
{
   char dll_nm[100],func_nm[100],old_cc[20];
   int dll_i,sravn,cntdll=0,i;
   TDll mas_dll[100];
   TList *n_el,*c_el,*pred_el;
   Tstek tree_stek(500);
   ofstream otchet(file_otchet,ios::app);
   ifstream svlog;

   otchet << "<strong>SECURITY VIOLATION: </strong></pre>"
   << "<table cellpadding=3 border=1><tr><th>Function</th><th>Library</th></tr>";

   //������� ���� ������ ������ ��������� ����������� ����������
   svlog.open(file_sv_log);
   while (!svlog.eof()) {
      svlog >> dll_nm >> func_nm >> old_cc;
      if (strcmp(dll_nm,"")==0) continue;

      otchet << "<tr><td>" << func_nm << "</td><td>" << dll_nm << "</td></tr>";

      //������� DLL ������
      dll_i=0;
      while(dll_i<cntdll && strcmp(dll_nm,mas_dll[dll_i].name)!=0) dll_i++;
      if (dll_i==cntdll) {//�� �����
         //������� ����� DLL � ������
         mas_dll[cntdll].name=new char[strlen(dll_nm)+1];
         strcpy(mas_dll[cntdll].name,dll_nm);
         mas_dll[cntdll].root=NULL;
         cntdll++;
      }

      //���� � ������ �������� �������
      c_el=mas_dll[dll_i].root;
      while (c_el!=NULL) {
         pred_el=c_el;
         sravn=strcmp(func_nm,c_el->name);
         if (sravn>0) {
            c_el=c_el->right;
         }  else if (sravn<0) {
            c_el=c_el->left;
         } else break;
      }

      if (c_el==NULL) { //������� ������� � ������ ����, �� ��� �� ����
         n_el=new TList;
         n_el->name=new char[strlen(func_nm)+1];
         strcpy(n_el->name,func_nm);
         n_el->callcnt_start=atoi(old_cc);
         n_el->left=NULL;
         n_el->right=NULL;

         if (mas_dll[dll_i].root==NULL)
            mas_dll[dll_i].root=n_el;
         else {
            if (sravn>0) pred_el->right=n_el;
            else pred_el->left=n_el;
         }

         c_el=n_el;
      }
      c_el->callcnt_start++;

   }
   svlog.close();
   otchet << "</table><form method=POST action=\"/cgi-bin/admin.pl\">"
          << "<input type=hidden name=\"compiler\" value=\"" << id_cmp << "\">"
          << "<input type=hidden name=\"add_wl\" value=\"";

   //������� ������ �������� ������ � �����
   for (i=0;i<cntdll;i++) {
      c_el=mas_dll[i].root;
      otchet << "dll=" << mas_dll[i].name << "\n";
      tree_stek.init();
      while (true) {
         if (c_el==NULL) {
            if (tree_stek.empty()) break;
            tree_stek.pop((void**)&c_el);

            otchet << c_el->name << " " << c_el->callcnt_start << "\n";

            c_el=c_el->right;
         } else {
            tree_stek.push(c_el);
            c_el=c_el->left;
         }
      }
   }

   otchet << "\"><input type=submit value=\"Add all functions in white list\"></form><br><pre>";
   otchet.close();
}

//���������� ������� � ��� ����
void SavePointTime(char *msg)
{
   SYSTEMTIME sys_tm;
   GetSystemTime(&sys_tm);
   logf << "time=" << sys_tm.wHour<<":"<< sys_tm.wMinute<<":"<< sys_tm.wSecond
       <<"."<< sys_tm.wMilliseconds << "; msg=" << msg <<"\n";
   logf.close();
   logf.open(master_cfg->GlobalPaths->LogFile,ios::out | ios::app);
}

//���������� ����� ����������� ������� � ��
__int64 GetIdleTimes(void)
{/*
   //��������� �� ������������� ����� winternl.h
   typedef union _LARGE_INTEGER {
      struct {    DWORD LowPart;    LONG HighPart;  };
      struct {    DWORD LowPart;    LONG HighPart;  } u;
      LONGLONG QuadPart;
   } LARGE_INTEGER, *PLARGE_INTEGER;

   typedef struct
   _SYSTEM_PROCESSOR_PERFORMANCE_INFORMATION {
       LARGE_INTEGER IdleTime;
       LARGE_INTEGER KernelTime;
       LARGE_INTEGER UserTime;
       LARGE_INTEGER Reserved1[2];
       ULONG Reserved2,Reserved3;
   } SYSTEM_PROCESSOR_PERFORMANCE_INFORMATION;

   typedef enum _SYSTEM_INFORMATION_CLASS {
       SystemBasicInformation = 0,
       SystemPerformanceInformation = 2,
       SystemTimeOfDayInformation = 3,
       SystemProcessInformation = 5,
       SystemProcessorPerformanceInformation = 8,
       SystemInterruptInformation = 23,
       SystemExceptionInformation = 33,
       SystemRegistryQuotaInformation = 37,
       SystemLookasideInformation = 45
   } SYSTEM_INFORMATION_CLASS;

   //��� - ��������� �� ������� �� ntdll.dll
 
  typedef NTSTATUS (*pfNtQuerySystemInformation)(
  SYSTEM_INFORMATION_CLASS SystemInformationClass,
  PVOID SystemInformation,
  ULONG SystemInformationLength,
  PULONG ReturnLength
  );

 static  pfNtQuerySystemInformation NtQuerySystemInform = NULL;

   //���������� ����� ������ �������
   if (NtQuerySystemInform == NULL) {
      HMODULE ntDLL = ::GetModuleHandle("ntdll.dll");
      NtQuerySystemInform =
         (pfNtQuerySystemInformation)GetProcAddress(ntDLL ,"NtQuerySystemInformation");
   }

   SYSTEM_PROCESSOR_PERFORMANCE_INFORMATION curInfo ;
   ULONG retsize;

   //����� ������� ������� ���������� � ��� ����� � ����������� �������
   //�������� � ����� ����!!!
   NtQuerySystemInform(SystemProcessorPerformanceInformation,
       &curInfo, sizeof(curInfo), &retsize);

   __int64 idle;
   idle=(__int64)(curInfo.IdleTime.QuadPart/1.0e4);
   return idle;
   */
       return 0;
}


