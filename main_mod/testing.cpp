//---------------------------------------------------------------------------

const bool DetailedReport = true;

#define _WIN32_WINNT 0x0501
#define _CRT_SECURE_NO_DEPRECATE

#include <windows.h>
#include <cstring>
#include <string>
#include <fstream>
#include <iomanip>
#include <cstdio>
#include <math.h>
#include <set>
#include <sstream>
#include "..\common_cpp\result_id.h"
#include "testing.h"
#include "main_mod.h"
using namespace std;
//---------------------------------------------------------------------------

__int64 CPUSpeed;

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

//������ ������ ��� �������� ������������ ������
void CheckWA(TPaths *pt, int &ret, int run_checker){
   unsigned int ec,cOldTime=0,cTimeI=0;
   double cTime=0.0,cTimeCPU=0.0;
   __int64 tm_stamp,end_sleep;
   HANDLE hOutput, hStdOut;
   char WACmd[400],fln[MAX_PATH];
   BOOL er;
   PROCESS_INFORMATION ProcessInfo; //����������� �������� CreateProcess   
   STARTUPINFO StartupInfo;
   FILETIME cr,ex,kr,ur;

   if (ret==RS_ACCEPTED && pt->WAProg!=NULL && run_checker) {
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
           NULL, NULL, TRUE, NORMAL_PRIORITY_CLASS,
           NULL, pt->dir_temp, &si, &ProcessInfo);

      CloseHandle(hOutput);
      CloseHandle(hStdOut);

      if (!er) {
         err((string(WACmd)+" �� �����������!").c_str());
         ret=RS_PRESENTATION_ERROR;
      } else {

         ec=STILL_ACTIVE;
         end_sleep=tm_stamp=0;
		   cTimeI=0;
         while (cTimeI<master_cfg->Options->CheckerTimeLimit && (end_sleep-tm_stamp)>=0) {
            tm_stamp=GetIdleTimes();
            GetProcessTimes(ProcessInfo.hProcess,&cr,&ex,&kr,&ur);
            cTimeI=(unsigned int)(kr.dwLowDateTime+ur.dwLowDateTime)/1.0e4;

            //����������� �����������
            if ((cTimeI-cOldTime)>50 || !end_sleep) {
               cOldTime=cTimeI;
               end_sleep=tm_stamp+master_cfg->Options->CheckerSleepLimit;
            }

            GetExitCodeProcess(ProcessInfo.hProcess,(unsigned long *)&ec);
            if (ec!=STILL_ACTIVE) break; //���� ����������

            Sleep(10);
         }

         if (ec==STILL_ACTIVE) {
           TerminateProcess(ProcessInfo.hProcess,10);
           WaitForSingleObject(ProcessInfo.hProcess, INFINITE);
		   err(("����������� ������: \""+string(WACmd)+"\"").c_str());
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
int RunProblem(TPaths *pt, double *time_lim, unsigned int *mem_lim, unsigned int *error_n, int run_checker, int id_cmp)
{
   unsigned int ec,cOldTime=0,cTimeI=0;
   double cTime=0.0,cTimeCPU=0.0;
   __int64 tm_stamp,end_sleep;
   FILETIME cr,ex,kr,ur;
   int ret=RS_ACCEPTED,cMem=0;
   BOOL er;
   char WACmd[400],fln[MAX_PATH];
   char env[MAX_PATH*3], *ienv;
   HANDLE hjob=NULL,hToken,hToken1;
   PROCESS_INFORMATION ProcessInfo; //����������� �������� CreateProcess   
   OFSTRUCT FileInfo;
   HANDLE hInput,hOutput,hError;
   HANDLE hStdOut=NULL,hStdIn=NULL,hStdErr=NULL;
   STARTUPINFO StartupInfo;
   UINT old_err_st=0;
   JOBOBJECT_EXTENDED_LIMIT_INFORMATION jli;
   JOBOBJECT_SECURITY_LIMIT_INFORMATION jsec;
   JOBOBJECT_BASIC_ACCOUNTING_INFORMATION jac;
   JOBOBJECT_BASIC_UI_RESTRICTIONS jui;
   __int64 time_start,time_finish;

   *error_n=0;

   //���������� ���������, ������������ � .DLL
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
	  ienv = ienv + strlen(ienv) + 1;
	  sprintf(ienv, "NLS_LANG=RUSSIAN_RUSSIA.CL8MSWIN1251");
   }

   //�������� �������, � ������� ����� ��������� �������
   hjob = CreateJobObject(NULL,NULL);
   if (hjob==NULL) {
      err("�� ������� ������� �������");
	  ret=RS_RUN_TIME_ERROR;
      *error_n=1000;
   }
  
   if (ret==RS_ACCEPTED) {
   memset(&FileInfo, 0, sizeof(OFSTRUCT));
   FileInfo.cBytes = sizeof(OFSTRUCT);

   //������� ���� �����
   hInput=(void*)OpenFile(pt->inpF,&FileInfo,OF_READ);

   //�������� ���� ������
   hOutput=CreateFile(pt->outF,GENERIC_WRITE,0,NULL,CREATE_ALWAYS,FILE_ATTRIBUTE_NORMAL,NULL);

   //�������� ���� ������
   hError=CreateFile(pt->errF,GENERIC_WRITE,0,NULL,CREATE_ALWAYS,FILE_ATTRIBUTE_NORMAL,NULL);


   //�������� ��������� ��� �������� � ����������� �������
   DuplicateHandle(GetCurrentProcess(), hOutput, GetCurrentProcess(),
                   &hStdOut, 0, TRUE, DUPLICATE_SAME_ACCESS);
   DuplicateHandle(GetCurrentProcess(), hInput, GetCurrentProcess(),
                   &hStdIn, 0, TRUE, DUPLICATE_SAME_ACCESS);
   DuplicateHandle(GetCurrentProcess(), hError, GetCurrentProcess(),
                   &hStdErr, 0, TRUE, DUPLICATE_SAME_ACCESS);

   memset(&StartupInfo, 0, sizeof(STARTUPINFO));
   StartupInfo.cb=sizeof(STARTUPINFO);
   StartupInfo.dwFlags=STARTF_USESTDHANDLES|STARTF_USESHOWWINDOW|CREATE_BREAKAWAY_FROM_JOB;
   StartupInfo.wShowWindow=SW_HIDE;
   StartupInfo.hStdInput=hStdIn;
   StartupInfo.hStdOutput=hStdOut;
   StartupInfo.hStdError=hStdErr;

   //�� ���������� ��������� �� �������
   old_err_st=SetErrorMode(SEM_NOGPFAULTERRORBOX);

   //�������� ������� � ������ ������
   /*er=CreateProcess(NULL, pt->FileTest,
        NULL, NULL, TRUE, CREATE_SUSPENDED|IDLE_PRIORITY_CLASS,
        env, master_cfg->GlobalPaths->DirTemp, &StartupInfo, &ProcessInfo);*/


    er=CreateProcess(NULL, pt->FileTest,
        NULL, NULL, TRUE, CREATE_SUSPENDED|IDLE_PRIORITY_CLASS,
        NULL, master_cfg->GlobalPaths->DirTemp, &StartupInfo, &ProcessInfo);


   //������� ��� ����� ����� ��� ������ �� �����
   CloseHandle(hInput);
   CloseHandle(hOutput);
   CloseHandle(hError);
   CloseHandle(hStdIn);
   CloseHandle(hStdOut);
   CloseHandle(hStdErr);

   
   if (!er) {
      err((string(pt->FileTest)+" �� �����������!").c_str());
      ret=RS_RUN_TIME_ERROR;
	  *error_n=1001;
   }
   }

   if (ret==RS_ACCEPTED) {
   //������������� ����������� �� ���������� ������� �� ������� � ������
   memset(&jli,0,sizeof(jli));
   jli.BasicLimitInformation.LimitFlags = 
	   JOB_OBJECT_LIMIT_JOB_TIME |
	   JOB_OBJECT_LIMIT_PROCESS_TIME |
	   JOB_OBJECT_LIMIT_JOB_MEMORY |
	   JOB_OBJECT_LIMIT_PROCESS_MEMORY |
       JOB_OBJECT_LIMIT_KILL_ON_JOB_CLOSE;
	   //JOB_OBJECT_LIMIT_PRIORITY_CLASS;

   //����������� �� �������
   jli.BasicLimitInformation.PerJobUserTimeLimit.QuadPart = (__int64)((*time_lim)*1E+7);
   jli.BasicLimitInformation.PerProcessUserTimeLimit.QuadPart = (__int64)((*time_lim)*1E+7);

   //����������� �� ������
   jli.JobMemoryLimit = (*mem_lim)*1024;
   jli.ProcessMemoryLimit = (*mem_lim)*1024;
   //jli.JobMemoryLimit = 400000000;
   //jli.ProcessMemoryLimit = 400000000;
   

   er=SetInformationJobObject(hjob,JobObjectExtendedLimitInformation,&jli,sizeof(jli));
   if (!er) {
	   err("�� ������� ���������� ����������� ������� � ������ ��� �������");
	   ret=RS_RUN_TIME_ERROR;
	   *error_n=1002;
   }
   }

   if (ret==RS_ACCEPTED) {
   //������������� ����������� �� ���������� ������� �� ���������������� ���������
   memset(&jui,0,sizeof(jui));
   jui.UIRestrictionsClass=JOB_OBJECT_UILIMIT_ALL; //������ ��� �����������
   
   er=SetInformationJobObject(hjob,JobObjectBasicUIRestrictions,&jui,sizeof(jui));
   if (!er) {
	   err("�� ������� ���������� ����������� �� ���������������� ���������");
	   ret=RS_RUN_TIME_ERROR;
	   *error_n=1004;
   }
   }

   //if (ret==RS_ACCEPTED) {
   if (false) {
	  //������������ ����� �� ������ �������� ��������� ����������
	  OpenProcessToken(GetCurrentProcess(),TOKEN_ALL_ACCESS,&hToken);
	  er=CreateRestrictedToken(hToken,0,
		  master_cfg->Options->cnt_del_sids,master_cfg->Options->del_sids,
		  0,NULL,
		  0,NULL,
		  &hToken1);

	  jsec.SecurityLimitFlags = 0 //JOB_OBJECT_SECURITY_NO_ADMIN 
		  | JOB_OBJECT_SECURITY_ONLY_TOKEN;
	  jsec.JobToken=hToken1;
	  jsec.PrivilegesToDelete=NULL;
	  jsec.SidsToDisable=NULL;
	  jsec.RestrictedSids=NULL;
	  er=SetInformationJobObject(hjob,JobObjectSecurityLimitInformation,&jsec,sizeof(jsec));
	  CloseHandle(hToken);
	  CloseHandle(hToken1);
	  if (!er) {
         err("�� ������� ��������� ������ ����������� � �������");
         ret=RS_RUN_TIME_ERROR;
	     *error_n=1005;
	  }
   }

  //if (ret==RS_ACCEPTED) {
  { 
  //������� ������� � �������
  
      // !!!���������� ������� ��� ��������� Windows 2008 R2 SP1 - �� ����� � ��� ����� ��������, � �� ������ - ������!!!
	  if (id_cmp != 4 && id_cmp != 11) {
		  er = AssignProcessToJobObject(hjob, ProcessInfo.hProcess);
		  if (!er) {
			  err("�� ������� �������� ������� � �������");
			  ret = RS_RUN_TIME_ERROR;
			  *error_n = 1003;
		  }
	  }

   }

/*
   if (pt->protect!=0) {

      //�������� API �������
//      if (!InjectDll(ProcessInfo.dwProcessId,ProcessInfo.hThread,pt->dllF))
         //return RS_SECURITY_VIOLATION;
   }
*/

   if (ret==RS_ACCEPTED) {
   //������ ������� ����� ��������
   ResumeThread(ProcessInfo.hThread);
   
   //������ ������ ����������
   time_start=TimeStamp();

   //���, ���� ���������� ������� � �������
   DWORD wait_res = WaitForSingleObject(ProcessInfo.hProcess,(DWORD)((*time_lim)*3000.0));
   time_finish=TimeStamp();
   if(wait_res==WAIT_TIMEOUT) {
	   //��-��������, ������� ���� � ������ (��� ������� ����� ����� ����) - ��������� ���
	   TerminateProcess(ProcessInfo.hProcess,0);
       WaitForSingleObject(ProcessInfo.hProcess,INFINITE);
	   ret = RS_SLEEP_DETECT;
   }

   GetExitCodeProcess(ProcessInfo.hProcess,(unsigned long *)&ec);
  
   //�������� ���������� � ���������� ��������
   //������
   er=QueryInformationJobObject(hjob,JobObjectExtendedLimitInformation,&jli,sizeof(jli),NULL);
   if(!er) {
	  err("�� ������� �������� ���������� �� ������������� ������ ��� ���������� �������");
	  ret=RS_RUN_TIME_ERROR;
	  *error_n=1006;
   } else {
      cMem = jli.PeakProcessMemoryUsed / 1024;
   }

   //�����   
   memset(&jac,0,sizeof(jac));
   er=QueryInformationJobObject(hjob,JobObjectBasicAccountingInformation,&jac,sizeof(jac),NULL);
   if(!er) {
	  err("�� ������� �������� ���������� � ������� ���������� �������");
	  ret=RS_RUN_TIME_ERROR;
	  *error_n=1007;
   } else {
      cTime=(double)(jac.TotalKernelTime.QuadPart+jac.TotalUserTime.QuadPart)/1.0E+7;
      cTimeCPU=(double)(time_finish-time_start)/CPUSpeed;
      if (cTime<0.1 && fabs(cTime-cTimeCPU)<0.015) cTime=cTimeCPU;
   }

 /*  
   //"Sleep detect"
   if(wait_res==WAIT_TIMEOUT) {
     ret = RS_SLEEP_DETECT;
   } else
*/
   //"Time limit"
   if (cTime>=*time_lim) {
      ret=RS_TIME_LIMIT;
   } else
    
   //"Memory limit"
   if (cMem>=(int)*mem_lim-16) {
      ret=RS_MEMORY_LIMIT;
   } else
/*
   //"Security violation"
   if (ec==EXIT_CODE_SECURITY_VIOLATION) {
      ret=RS_SECURITY_VIOLATION;
   } else
*/
   //"Run Time Error"
   if (ec!=0) {
      ret=RS_RUN_TIME_ERROR;
      *error_n=ec;
   }

   }

   *time_lim=cTime;
   *mem_lim=(unsigned int)cMem;

   if (ProcessInfo.hProcess) CloseHandle(ProcessInfo.hProcess);
   if (ProcessInfo.hThread) CloseHandle(ProcessInfo.hThread);
   if (hjob) CloseHandle(hjob);

   CheckWA(pt, ret, run_checker);

   //����������� ��������� ��������� ������
   SetErrorMode(old_err_st);

   return ret;
}

//������� ��������� ���������, ����������� ������������� ��������������,
//��������� ����������� �������, ��������� �� ����� ����� ������������ ��������,
//���������� ��������� ��������
int RunInteractProblem(TPaths *pt, double *time_lim, unsigned int *mem_lim, unsigned int *error_n, int run_checker)
{
   unsigned int ec,cOldTime=0,cTimeI=0;
   double cTime=0.0,cTimeCPU=0.0;
   __int64 tm_stamp,end_sleep;
   FILETIME cr,ex,kr,ur;
   int ret=RS_ACCEPTED,cMem=0;
   BOOL er;
   char env[MAX_PATH*3], *ienv;
   char jurycmd[MAX_PATH*2]; //��������� ������ ��� ������� ��������� ����
   HANDLE hjob=NULL,hToken,hToken1;
   PROCESS_INFORMATION ProcessInfo; //����������� �������� CreateProcess   
   PROCESS_INFORMATION InteractProcessInfo;
   OFSTRUCT FileInfo;
   STARTUPINFO StartupInfo;
   STARTUPINFO InteractStartupInfo;
   UINT old_err_st=0;
   JOBOBJECT_EXTENDED_LIMIT_INFORMATION jli;
   JOBOBJECT_SECURITY_LIMIT_INFORMATION jsec;
   JOBOBJECT_BASIC_ACCOUNTING_INFORMATION jac;
   JOBOBJECT_BASIC_UI_RESTRICTIONS jui;
   __int64 time_start,time_finish;
   HANDLE hError, hStdErr;
   SECURITY_ATTRIBUTES sa;

   *error_n=0;

   //���������� ���������, ������������ � .DLL
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

   //�������� �������, � ������� ����� ��������� �������
   hjob = CreateJobObject(NULL,NULL);
   if (hjob==NULL) {
      err("�� ������� ������� �������");
	  ret=RS_RUN_TIME_ERROR;
      *error_n=1000;
   }

   if (ret==RS_ACCEPTED) {
   memset(&FileInfo, 0, sizeof(OFSTRUCT));
   FileInfo.cBytes = sizeof(OFSTRUCT);

   //...����� ��������� ��� �� ���� - ����� ���������� � ��������� ������ ��������� ���� (����� ����� ��� ������)
   //������� ���� �����
   //hInput=(void*)OpenFile(pt->inpF,&FileInfo,OF_READ);
   //�������� ���� ������
   //hOutput=CreateFile(pt->outF,GENERIC_WRITE,0,NULL,CREATE_ALWAYS,FILE_ATTRIBUTE_NORMAL,NULL);
   //�������� ���� ������
   hError=CreateFile(pt->errF,GENERIC_WRITE,0,NULL,CREATE_ALWAYS,FILE_ATTRIBUTE_NORMAL,NULL);

   //...����������, ���������� ������� �� ����, ����� ������ ������
   //�������� ��������� ��� �������� � ����������� �������
   //DuplicateHandle(GetCurrentProcess(), hOutput, GetCurrentProcess(),
   //                &hStdOut, 0, TRUE, DUPLICATE_SAME_ACCESS);
   //DuplicateHandle(GetCurrentProcess(), hInput, GetCurrentProcess(),
   //                &hStdIn, 0, TRUE, DUPLICATE_SAME_ACCESS);
   DuplicateHandle(GetCurrentProcess(), hError, GetCurrentProcess(),
                   &hStdErr, 0, TRUE, DUPLICATE_SAME_ACCESS);

  //������ �����, ������� ������ ����� ��������� ���� �� ������ ��������� ��������
   sa.nLength= sizeof(SECURITY_ATTRIBUTES);
   sa.lpSecurityDescriptor = NULL;
   sa.bInheritHandle = TRUE;
   HANDLE hJuryOut, hStudInp;
   if (!CreatePipe(&hStudInp,&hJuryOut,&sa,0))
     err("������ ��� �������� ������");

   //������ �����, ������� ������ ����� ��������� �������� �� ������ ��������� ����
   sa.nLength= sizeof(SECURITY_ATTRIBUTES);
   sa.lpSecurityDescriptor = NULL;
   sa.bInheritHandle = TRUE;
   HANDLE hJuryInp, hStudOut;
   CreatePipe(&hJuryInp,&hStudOut,&sa,0);

   //������� ���������� ��� ������ �������� ������� ��������
   memset(&StartupInfo, 0, sizeof(STARTUPINFO));
   StartupInfo.cb=sizeof(STARTUPINFO);
   StartupInfo.dwFlags=STARTF_USESTDHANDLES|STARTF_USESHOWWINDOW|CREATE_BREAKAWAY_FROM_JOB;
   StartupInfo.wShowWindow=SW_HIDE;
   //����� ������ ��� ��������� ��������
   StartupInfo.hStdInput=hStudInp;
   StartupInfo.hStdOutput=hStudOut;
   StartupInfo.hStdError=hStdErr;
   
   //������� ���������� ��� ������ �������� ����, ������������ �������������� � ���������� ��������
   memset(&InteractStartupInfo, 0, sizeof(STARTUPINFO));
   InteractStartupInfo.cb=sizeof(STARTUPINFO);
   InteractStartupInfo.dwFlags=STARTF_USESTDHANDLES|STARTF_USESHOWWINDOW|CREATE_BREAKAWAY_FROM_JOB;
   InteractStartupInfo.wShowWindow=SW_HIDE;
   //����� ������ ��� ��������� ��������
   InteractStartupInfo.hStdInput=hJuryInp;
   InteractStartupInfo.hStdOutput=hJuryOut;   
   //��������� ��������� ������ ��� ������� ��������� ����
   sprintf(jurycmd,"%s %s %s %s",pt->FileInteract,pt->inpF,pt->outF,pt->checker_outF);

   //�� ���������� ��������� �� �������
   old_err_st=SetErrorMode(SEM_NOGPFAULTERRORBOX);

   /*er=CreateProcess(NULL, pt->FileTest,
        NULL, NULL, TRUE, CREATE_SUSPENDED|IDLE_PRIORITY_CLASS,
        env, master_cfg->GlobalPaths->DirTemp, &StartupInfo, &ProcessInfo);*/

   //�������� ������� �������� � ������ ������
    er=CreateProcess(NULL, pt->FileTest,
        NULL, NULL, TRUE, CREATE_SUSPENDED|IDLE_PRIORITY_CLASS,
        NULL, master_cfg->GlobalPaths->DirTemp, &StartupInfo, &ProcessInfo);

   //������� ��� ����� ����� ��� ������ �� �����
   CloseHandle(hError);
   CloseHandle(hStdErr);

   if (!er) {
      err((string(pt->FileTest)+" �� �����������!").c_str());
      ret=RS_RUN_TIME_ERROR;
	  *error_n=1001;
   }
   else {
     //�������� ������� ����
     er=CreateProcess(NULL, jurycmd,
        NULL, NULL, TRUE, CREATE_SUSPENDED|IDLE_PRIORITY_CLASS,
        NULL, master_cfg->GlobalPaths->DirTemp, &InteractStartupInfo, &InteractProcessInfo);
	 if (!er) {
      err((string(pt->FileInteract)+" �� �����������!").c_str());
      ret=RS_RUN_TIME_ERROR;
	  *error_n=1001;
	  //��������� ������� ��������, ��� ��� � ��� ������ �����������������
      TerminateProcess(ProcessInfo.hProcess,0);
     }
   }

  }

  if (ret==RS_ACCEPTED) {
   //������������� ����������� �� ���������� ������� �� ������� � ������
   memset(&jli,0,sizeof(jli));
   jli.BasicLimitInformation.LimitFlags = 
	   JOB_OBJECT_LIMIT_JOB_TIME |
	   JOB_OBJECT_LIMIT_PROCESS_TIME |
	   JOB_OBJECT_LIMIT_JOB_MEMORY |
	   JOB_OBJECT_LIMIT_PROCESS_MEMORY |
       JOB_OBJECT_LIMIT_KILL_ON_JOB_CLOSE;
	   //JOB_OBJECT_LIMIT_PRIORITY_CLASS;

   //����������� �� �������
   jli.BasicLimitInformation.PerJobUserTimeLimit.QuadPart = (__int64)((*time_lim)*1E+7);
   jli.BasicLimitInformation.PerProcessUserTimeLimit.QuadPart = (__int64)((*time_lim)*1E+7);

   //����������� �� ������
   jli.JobMemoryLimit = (*mem_lim)*1024;
   jli.ProcessMemoryLimit = (*mem_lim)*1024;
   
   er=SetInformationJobObject(hjob,JobObjectExtendedLimitInformation,&jli,sizeof(jli));
   if (!er) {
	   err("�� ������� ���������� ����������� ������� � ������ ��� �������");
	   ret=RS_RUN_TIME_ERROR;
	   *error_n=1002;
   }
  }

  if (ret==RS_ACCEPTED) {
   //������������� ����������� �� ���������� ������� �� ���������������� ���������
   memset(&jui,0,sizeof(jui));
   jui.UIRestrictionsClass=JOB_OBJECT_UILIMIT_ALL; //������ ��� �����������
   
   er=SetInformationJobObject(hjob,JobObjectBasicUIRestrictions,&jui,sizeof(jui));
   if (!er) {
	   err("�� ������� ���������� ����������� �� ���������������� ���������");
	   //ret=RS_RUN_TIME_ERROR; //��� �� ����� ������� - �� ����� �������� ���������
	   //*error_n=1004;
   }
  }

   if (ret==RS_ACCEPTED) {   
	  //������������ ����� �� ������ �������� ��������� ����������
	  OpenProcessToken(GetCurrentProcess(),TOKEN_ALL_ACCESS,&hToken);
	  er=CreateRestrictedToken(hToken,0,
		  master_cfg->Options->cnt_del_sids,master_cfg->Options->del_sids,
		  0,NULL,
		  0,NULL,
		  &hToken1);

	  jsec.SecurityLimitFlags = 0 //JOB_OBJECT_SECURITY_NO_ADMIN 
		  | JOB_OBJECT_SECURITY_ONLY_TOKEN;
	  jsec.JobToken=hToken1;
	  jsec.PrivilegesToDelete=NULL;
	  jsec.SidsToDisable=NULL;
	  jsec.RestrictedSids=NULL;
	  er=SetInformationJobObject(hjob,JobObjectSecurityLimitInformation,&jsec,sizeof(jsec));
	  CloseHandle(hToken);
	  CloseHandle(hToken1);
	  if (!er) {
         err("�� ������� ��������� ������ ����������� � �������");
         //ret=RS_RUN_TIME_ERROR; �� ����� windows ����� �� ��������, ������� �� ����� �������� ���������
	     //*error_n=1005;
	  }
   }

  if (ret==RS_ACCEPTED) {
   //������� ������� � �������
   er=AssignProcessToJobObject(hjob,ProcessInfo.hProcess);
   if (!er) {
      err("�� ������� �������� ������� � �������");
	  ret=RS_RUN_TIME_ERROR;
	  *error_n=1003;
   }
  }
 
/*
   if (pt->protect!=0) {

      //�������� API �������
//      if (!InjectDll(ProcessInfo.dwProcessId,ProcessInfo.hThread,pt->dllF))
         //return RS_SECURITY_VIOLATION;
   }
*/

  if (ret==RS_ACCEPTED) {

   //������ ������� ����� �������� ��������
   ResumeThread(ProcessInfo.hThread);

   //������ ������� ����� �������� ����
   ResumeThread(InteractProcessInfo.hThread);   
   
   //������ ������ ����������
   time_start=TimeStamp();

   //���, ���� ���������� ������� � �������
   DWORD wait_res = WaitForSingleObject(ProcessInfo.hProcess,(DWORD)((*time_lim)*2000.0));
   time_finish=TimeStamp();
   if(wait_res==WAIT_TIMEOUT) {
	   //��-��������, ������� ���� � ������ (��� ������� ����� ����� ����) - ��������� ���
	   TerminateProcess(ProcessInfo.hProcess,0);
       WaitForSingleObject(ProcessInfo.hProcess,INFINITE);	   
	   ret = RS_SLEEP_DETECT;
   }

   GetExitCodeProcess(ProcessInfo.hProcess,(unsigned long *)&ec);   

   //������� ���������� �������� ����
   wait_res = WaitForSingleObject(InteractProcessInfo.hProcess,(DWORD)(1000.0));
   if(wait_res==WAIT_TIMEOUT) {
       //������������� ��������� ������� ����
       TerminateProcess(InteractProcessInfo.hProcess,0);
       WaitForSingleObject(InteractProcessInfo.hProcess,INFINITE);
   }   
  
   //�������� ���������� � ���������� ��������
   //������
   er=QueryInformationJobObject(hjob,JobObjectExtendedLimitInformation,&jli,sizeof(jli),NULL);
   if(!er) {
	  err("�� ������� �������� ���������� �� ������������� ������ ��� ���������� �������");
	  ret=RS_RUN_TIME_ERROR;
	  *error_n=1006;
   } else {
      cMem = jli.PeakProcessMemoryUsed / 1024;
   }

   //�����
   memset(&jac,0,sizeof(jac));
   er=QueryInformationJobObject(hjob,JobObjectBasicAccountingInformation,&jac,sizeof(jac),NULL);
   if(!er) {
	  err("�� ������� �������� ���������� � ������� ���������� �������");
	  ret=RS_RUN_TIME_ERROR;
	  *error_n=1007;
   } else {
      cTime=(double)(jac.TotalKernelTime.QuadPart+jac.TotalUserTime.QuadPart)/1.0E+7;
      cTimeCPU=(double)(time_finish-time_start)/CPUSpeed;
      if (cTime<0.1 && fabs(cTime-cTimeCPU)<0.015) cTime=cTimeCPU;
   }

  //"Time limit"
   if (cTime>=*time_lim) {
      ret=RS_TIME_LIMIT;
   } else
    
   //"Memory limit"
   if (cMem>=(int)*mem_lim-16) {
      ret=RS_MEMORY_LIMIT;
   } else

	   /*
   //"Security violation"
   if (ec==EXIT_CODE_SECURITY_VIOLATION) {
      ret=RS_SECURITY_VIOLATION;
   } else
*/

   //"Run Time Error"
   if (ec!=0) {
      ret=RS_RUN_TIME_ERROR;
      *error_n=ec;
   }

  }

   *time_lim=cTime;
   *mem_lim=(unsigned int)cMem;

   if (ProcessInfo.hProcess) CloseHandle(ProcessInfo.hProcess);
   if (ProcessInfo.hThread) CloseHandle(ProcessInfo.hThread);
   if (InteractProcessInfo.hProcess) CloseHandle(InteractProcessInfo.hProcess);
   if (InteractProcessInfo.hThread) CloseHandle(InteractProcessInfo.hThread);
   if (hjob) CloseHandle(hjob);

   CheckWA(pt, ret, run_checker);

   //����������� ��������� ��������� ������
   SetErrorMode(old_err_st);

   return ret;
}

const char *shortResultById(int r) {
	if (r == RS_ACCEPTED) return "+";
	if (r == RS_WRONG_ANSWER) return "�������� �����";
    if (r == RS_PRESENTATION_ERROR) return "������ �������������";
	if (r == RS_RUN_TIME_ERROR) return "������ ����������";
    if (r == RS_TIME_LIMIT) return "������ �������";
    if (r == RS_MEMORY_LIMIT) return "������ ������";
	if (r == RS_SECURITY_VIOLATION) return "��������� ������������";
    if (r == RS_COMPILATION_ERROR) return "������ ����������";
	if (r ==  RS_SLEEP_DETECT) return "���������� �����������";
    return "������ ������";
}


//�������� ������� �� ������ ������ ������ ��� ��������� ������
//@param points - �����, ������� ������� ������ ������.
//@param hardlevel - ������� ��������� ������ (���� hardlevel �� ������� problems)
//@param preliminary - true, ���� ��������� �� ������ �� �������
unsigned int TestSolve(TPaths *pt, double *time, unsigned int *mem, unsigned int *test_num, int id_cmp, int &points, int hardlevel, bool preliminary)
{
   int i,flpos;
   unsigned int r=-1,r1,mem1,mem2,max_m=0,er;
   unsigned int first_wrong_result = -1; //��������� �� ������ �� ��������� �����
   double time1,time2,max_t=0.0;
   char s[50],list_func[MAX_PATH],slong[MAX_PATH];
   ifstream list;
   ifstream pointsList; //�������� ������ �� ������ (�� �������� �������)
   int assessment_system;
   set<int> passed_tests;   
   set<int> not_passed_tests;   
   ofstream otchet,t_fl;

   //������� ������ ������
   if (!preliminary) {
     list.open(pt->ListTests);
   } else {
     list.open(pt->ListPreliminary);
   }
   if (list.bad()!=0) {
      logfl << "error: open file: " << pt->ListTests << endl;
      return -1;
   }

   if (preliminary) {
     assessment_system = ASSESM_ACM;
   } else {
     //������� ���� � ��������� ������ �� �����
     //� ����������� �� ��� ������� ���������� ������� ���������� - ACM ��� SCHOOL
     pointsList.open(pt->ListPoints);
     if (pointsList.good()) {
  	   assessment_system = ASSESM_SCHOOL;       
     } else {
         assessment_system = ASSESM_ACM;
     }   
   }

   sprintf(list_func,"%slist_ifunc.txt",pt->dir_temp);
   if (pt->protect==2) 
      SaveImportFuncList(pt->FileTest, list_func); //��������� � ���� ������ ������������� �������
   else DeleteFile(list_func); //�� ������ ������, ����� �������

   otchet.open(pt->otchetF,ios::out|ios::app);
   otchet << "</pre>";
   if (preliminary) {
     otchet << "���������� �������� �� ������ �� �������:<br>";
   } else {
     otchet << "���������� ��������:<br>";
   }
   otchet << "<table cellpadding=5 border=1><tr><th>���� �</th><th>������� ����</th><th>���� � ������ �������</th>"
          << "<th>���������</th><th>����� ������</th><th>������</th></tr>\n";

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
      if (!preliminary) {
        sprintf(pt->inpF,"%s%s.in",pt->DirTests,s);
      } else {
        sprintf(pt->inpF,"%s%s.in",pt->DirPreliminary,s);
      }
      sprintf(pt->outF,"%s%s.tst",pt->dir_temp,s);
      sprintf(pt->errF,"%s%s.err",pt->dir_temp,s);
      if (!preliminary) {
        sprintf(pt->correct_outF,"%s%s.out",pt->DirTests,s);
      } else {
        sprintf(pt->correct_outF,"%s%s.out",pt->DirPreliminary,s);
      }

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
      
      
      time2=0.1;
	  
	  //don't know why 5, but if write less, BUGS will be (problem 77, for example)
      for (int ck=0;ck<5;ck++) {
         time1=*time;
         mem1=*mem;
		 //����������� ������ �����
		 if (pt->FileInteract[0]==0)
           r1=RunProblem(pt,&time1,&mem1,&er,!ck,id_cmp); 
		 else
           r1=RunInteractProblem(pt,&time1,&mem1,&er,!ck); 

         if (!ck) r=r1;
         Sleep(20);
         if (time1>0.1) break;
      
         if (time1<time2 && time1>1.0E-9) {
            time2=time1;
            mem2=mem1;
         }
      }
      if (time1<=0.1 && time2<0.1) {
         time1=time2; 
         mem1=mem2;
      }

      otchet << "<td>" << shortResultById(r) << "</td><td>" << setprecision(3) << fixed << time1
             << " sec</td><td>" << mem1 << " KB</td></tr>\n";

      if (time1>max_t) max_t=time1;
      if (mem1>max_m) max_m=mem1;
      if (r!=RS_ACCEPTED) {	     
		 not_passed_tests.insert(i);
		 //����� ������ � ����� ������� - ������� ������ ����� ������
		 //if (assessment_system == ASSESM_ACM) {
	   if (DetailedReport) {
             otchet << "<tr><td colspan=6>\n<pre>";		 
           }
		 //}
		 if (*test_num == 0) {
		   //���������� �� ������� ������ ������ ����� ������� �� ���������� �����  � ��������� ��� ��������
           *test_num=i;		   
		   first_wrong_result = r;
		 }		 
	  } else {
		  // r == RS_ACCEPTED
		  passed_tests.insert(i);
	  }      

   //���������� � ������ �������������� ������ ����������
   // � ����������� �� ���������� ��������
   if (r==RS_RUN_TIME_ERROR) {
      wsprintf(slong,"Process exit code 0x%08x", er);

      otchet << "<strong>RUNTIME ERROR: </strong>" << er <<"\n\n";
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

   if (r!=RS_ACCEPTED /*&& assessment_system == ASSESM_ACM*/) {

   if (DetailedReport) {
      otchet << "\n<strong>----------- ������� ������: -----------</strong>\n";
      otchet.close();
      AddFileInOtchet(pt->otchetF,pt->inpF);
      otchet.open(pt->otchetF,ios::out|ios::app);
	   
	  otchet << "<strong>----------- ����� ���������: -----------</strong>\n";
      otchet.close();
      AddFileInOtchet(pt->otchetF,pt->outF);
      otchet.open(pt->otchetF,ios::out|ios::app);
    }

	  //DEBUG
	  /*
      otchet << "\n<strong>------- ���������� �����: -------</strong>\n";
      otchet.close();
      AddFileInOtchet(pt->otchetF,pt->correct_outF);
      otchet.open(pt->otchetF,ios::out|ios::app);
      */
   }

 if (DetailedReport) {
   if ((r==RS_WRONG_ANSWER || r==RS_PRESENTATION_ERROR)) {	  
	  otchet << "\n<strong>------- ��������� ��������� ��������: -------</strong>\n";
      otchet.close();
      AddFileInOtchet(pt->otchetF,pt->checker_outF);
      otchet.open(pt->otchetF,ios::out|ios::app);	  
   }
 }

   if (r != RS_ACCEPTED /*&& assessment_system == ASSESM_ACM*/ ) {
     //���-�� ������ � ����� - ������� ������ � html-�������
     if (DetailedReport) {
       otchet << "</pre></td></tr>\n";
     }
   }

    pt->del_temp_files(); //������� ��������� �����        

	if (assessment_system == ASSESM_ACM && r != RS_ACCEPTED) {
		  //� ������� ACM ��������� �� ������� �� ���������� �����
          break;
	}

   i++;
  } //����� ����� while �� ������

   otchet << "</table><pre>\n";

   sprintf(slong,"%ssv_log.txt",pt->dir_temp);
   DeleteFile(slong);

   list.close();
   if (pt->protect==2) DeleteFile(list_func);

   otchet.close();

   *time=max_t;
   *mem=max_m;
   
   if (assessment_system == ASSESM_ACM && r == RS_ACCEPTED) {
	   points = hardlevel;
   }

   if (assessment_system == ASSESM_SCHOOL) {	
	   //���� ������ ������ ���� �� ���� ����, ������ ������ "�������� �����" � ��������� �����
	   if (passed_tests.size() == 0) {
         return first_wrong_result; // ������ ������ ��� ������� �� ���������� ����� (�.�. ������ ��� �������)
	   }
	   if (not_passed_tests.size() == 0) {
		    r = RS_ACCEPTED;
	   } else {
	        r = RS_PARTIALLY_ACCEPTED;
	   }
	   //��������� ������ ������ � ����������� �����
	   points = 0;
	   string s;	 
	   while (getline(pointsList, s)) {
		 stringstream ss(s);		          
         int pointsForGroup;
		 ss >> pointsForGroup;
         bool passed = true; //������ ������ ��������?
		 int testnum;
		 while ((ss >> testnum) && passed) {
			 if (passed_tests.count(testnum) == 0) {
                passed = false; //���� �� �������
			 }
		 }
		 if (passed){
			 points += pointsForGroup;
		 }
	   }	   	   
   }

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
/*   size_t sz;
   DWORD sz1;
   char *buff;
   OFSTRUCT FileInfo;
   HANDLE hInput;

   memset(&FileInfo, 0, sizeof(OFSTRUCT));
   FileInfo.cBytes = sizeof(OFSTRUCT);

   hInput=(HANDLE)OpenFile(file_exe,&FileInfo,OF_READ);
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
   */
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
   while (tmp && sz>0) {
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
   logfl << "time=" << sys_tm.wHour<<":"<< sys_tm.wMinute<<":"<< sys_tm.wSecond
       <<"."<< sys_tm.wMilliseconds << "; msg=" << msg <<"\n";
   logfl.close();
   logfl.open(master_cfg->GlobalPaths->LogFile,ios::out | ios::app);
}

//���������� ����� ����������� ������� � ��
__int64 GetIdleTimes(void)
{
   /*
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
   typedef DWORD (*pfNtQuerySystemInformation) (
      IN DWORD SystemInformationClass,
      OUT PVOID SystemInformation,
      IN ULONG SystemInformationLength,
      OUT PULONG ReturnLength OPTIONAL
      );

   static pfNtQuerySystemInformation NtQuerySystemInformation = NULL;

   //���������� ����� ������ �������
   if (NtQuerySystemInformation == NULL) {
      HMODULE ntDLL = ::GetModuleHandle("ntdll.dll");
      NtQuerySystemInformation =
         (pfNtQuerySystemInformation)GetProcAddress(ntDLL ,"NtQuerySystemInformation");
   }

   SYSTEM_PROCESSOR_PERFORMANCE_INFORMATION curInfo ;
   ULONG retsize;

   //����� ������� ������� ���������� � ��� ����� � ����������� �������
   //�������� � ����� ����!!!
   NtQuerySystemInformation(SystemProcessorPerformanceInformation,
       &curInfo, sizeof(curInfo), &retsize);

   __int64 idle;
   idle=(__int64)(curInfo.IdleTime.QuadPart/1.0e4);
   return idle;
   */
	FILETIME t_idle,t_kernal,t_user;
	GetSystemTimes(&t_idle,&t_kernal,&t_user);
	__int64 idle=(__int64(t_idle.dwLowDateTime)|(__int64(t_idle.dwHighDateTime)<<32))/10000;
   return idle;
 
}


__declspec(naked) __int64 TimeStamp()
{
__asm {
      rdtsc
      ret
   }
}

__int64 GetCPUSpeed(void)
{
    __int64 StartTicks, EndTicks;
    int     timeStart, timeStop;

    timeStart = GetTickCount();
    while(1)
    {
        timeStop = GetTickCount();
        if((timeStop-timeStart) > 1)
        {
            StartTicks = TimeStamp();
            break;
        }
    }
    timeStart = timeStop;
    while(1)
    {
        timeStop = GetTickCount();
        if((timeStop-timeStart) > 150)
        {
            EndTicks = TimeStamp();
            break;
        }
    }
    return 1000*(EndTicks-StartTicks)/(timeStop-timeStart);
}


