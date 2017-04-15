#include "party.h"

#ifdef UNICODE
   #undef UNICODE
#endif

#include <Windows.h>
#include "trnmnt.h"
#include "log.h"

CPlayer::~CPlayer()
{
   DeleteFiles();
}

CPlayer::CPlayer()
{
   number = 0;
   rank = 0;
   points = 0;
   test_result = 0;
   count_err = 0;
   count_ok = 0;
   status = st_ok;

   ZeroMemory(&cur_lmts, sizeof(cur_lmts));
   ZeroMemory(&lmts, sizeof(lmts));
}

int CPartipiant::Run(HANDLE hToken)
{
   int stat = 0;
   HANDLE hInR, hInW, hOutR, hOutW;
   SECURITY_ATTRIBUTES saAttr;

   extern char USER[MAX_STR_SHORT_LEN];
   extern char PASSWORD[MAX_STR_SHORT_LEN];

   saAttr.nLength = sizeof(SECURITY_ATTRIBUTES);
   saAttr.bInheritHandle = TRUE;
   saAttr.lpSecurityDescriptor = NULL;

   //принимающий пайп
   stat = !CreatePipe(&hOutR, &hOutW, &saAttr, 0) || !DuplicateHandle(GetCurrentProcess(), hOutR, GetCurrentProcess(), &hStdout, 0, FALSE, DUPLICATE_SAME_ACCESS);
   if(stat) ErrWinAPI();

   //передающий пайп
   if(!stat)
   {
      stat = !CreatePipe(&hInR, &hInW, &saAttr, 0) || !DuplicateHandle(GetCurrentProcess(), hInW, GetCurrentProcess(), &hStdin, 0, FALSE, DUPLICATE_SAME_ACCESS);
      if(stat)  ErrWinAPI();
   }

   CloseHandle(hOutR);
   CloseHandle(hInW);

   if(stat) return stat;

   ZeroMemory(&piProcInfo, sizeof(PROCESS_INFORMATION));
   ZeroMemory(&siStartInfo, sizeof(STARTUPINFO) );

   siStartInfo.cb = sizeof(STARTUPINFO);
   siStartInfo.hStdOutput = hOutW;
   //siStartInfo.hStdError = hOutW;
   siStartInfo.hStdInput  = hInR;
   siStartInfo.dwFlags |= STARTF_USESTDHANDLES |STARTF_USESHOWWINDOW;
/*
   stat = !CreateProcessWithLogonW
  (
  //LPCWSTR lpUsername,
  (LPCWSTR)USER,
  //LPCWSTR lpDomain,
  NULL,
  //LPCWSTR lpPassword,
  (LPCWSTR)PASSWORD,
  //DWORD dwLogonFlags,
  0,
  //LPCWSTR lpApplicationName,
  (LPCWSTR)exefile,
  //LPWSTR lpCommandLine,
  NULL,
  //DWORD dwCreationFlags,
  0,
  //LPVOID lpEnvironment,
  NULL,
  //LPCWSTR lpCurrentDirectory,
  NULL,
  //LPSTARTUPINFOW lpStartupInfo,
  (LPSTARTUPINFOW)&siStartInfo,
  //LPPROCESS_INFORMATION lpProcessInfo
  &piProcInfo
);
*/   
   stat = !CreateProcess(exefile,
      NULL,          // command line
      NULL,          // process security attributes
      NULL,          // primary thread security attributes
      TRUE,          // handles are inherited
      0,             // creation flags
      NULL,          // use parent's environment
      NULL,          // use parent's current directory
      &siStartInfo,  // STARTUPINFO pointer
      &piProcInfo);  // receives PROCESS_INFORMATION

      
   //CloseHandle(piProcInfo.hProcess);
   //CloseHandle(piProcInfo.hThread);
   if(stat) ErrWinAPI();
   return stat;
}

bool CPartipiant::IsRunning()
{
   if(FALSE == GetExitCodeProcess(piProcInfo.hProcess, &exitcode))
      return false;
   return (STILL_ACTIVE == exitcode);
}

int CPartipiant::Stop()
{
   int stat = 0;

   //if(hStdout) CloseHandle(hStdout);
   //if(hStdin)  CloseHandle(hStdin);
   if(IsRunning())
   {
      TerminateProcess(piProcInfo.hProcess, 0);
      WaitForSingleObject(piProcInfo.hProcess, 1000);
   }

   return stat;
}

bool CPlayer::IsRunning()
{
   if(FALSE == GetExitCodeProcess(piProcInfo.hProcess, &exitcode))
      return false;

   if(exitcode && (STILL_ACTIVE != exitcode))
      SetStatus(st_run_time_error);

   return (STILL_ACTIVE == exitcode);
}

int CPlayer::Run(HANDLE hToken)
{
   int stat = 0;
   CPartipiant::Run(hToken);   
   return stat;
}

int CPlayer::GetData(DWORD dt)
{
   int stat = 0;
   BOOL ok = true;
   unsigned long dwRead = 0, k = 0;
   DWORD t1, t2;

   //while(SuspendThread());
   ZeroMemory(buf, szBuf);
   t1 = t2 = GetTickCount();
   for( ; t2 - t1 <= dt; )
   {
      if((PeekNamedPipe(hStdout, NULL, 0, NULL, &dwRead, NULL) == TRUE) && (dwRead > 0))
      {      
         dwRead = 0;
         ok = ReadFile(hStdout, buf+2+k, 1, &dwRead, NULL);//!!! +2
         if((FALSE == ok) || !dwRead) break;
         k += dwRead;
         if(buf[2+k-1] == '\n') break;//!!! +2
         dwRead = 0;
      } else Sleep(10);
      t2 = GetTickCount();
      if(k > 1000)
      {
         SetStatus(st_buffer_overflow);
         return 0;
      }
   }
   t2 = GetTickCount();
   cur_lmts.max_tm_move = t2 - t1;
   trim(buf+2);//!!! +2

   sprintf_s(logfile.str, "Получен ход от игрока [%s]", buf+2);//!!! +2
   logfile.Write(9);

   buf[strlen(buf+2)+2] = '\n';//!!! +2
   buf[strlen(buf+2)+2] = 0;

   return stat;
}

int CPlayer::GiveData(char *buf)
{
   int stat = 0;
   unsigned long dwWritten;

   if(!IsRunning()) return -1;
   trim(buf);
   sprintf_s(logfile.str, "Передем данные игроку [%s]", buf);
   logfile.Write(9);

   buf[strlen(buf)] = '\n';
   buf[strlen(buf)] = 0;
   if(!WriteFile(hStdin, buf, (DWORD)strlen(buf), &dwWritten, NULL)) ErrWinAPI();

   return stat;
}

void CPlayer::SetStatus(int st)
{
   if(st <= st_min_error) return;
   if(st >= st_max_error) return;
   if(st <= status) return;
   status = st;
}

int CPlayer::UpdateStatus(TLimits *limits)
{
   int stat = 0;
   /* Пересчиттываем текущие */
   cur_lmts.max_move++;//сделан ход
   cur_lmts.max_tm_game += cur_lmts.max_tm_move;//время на всю игру
   cur_lmts.max_mem = 10;

   /* обновляем ограничения */
   if(cur_lmts.max_tm_move > lmts.max_tm_move)
      lmts.max_tm_move = cur_lmts.max_tm_move;
   if(cur_lmts.max_mem > lmts.max_mem)
      lmts.max_mem = cur_lmts.max_mem;
   lmts.max_tm_game = cur_lmts.max_tm_game;
   lmts.max_move = cur_lmts.max_move;

   /* проверяем ограничения */
   if(limits->max_tm_move && lmts.max_tm_move > limits->max_tm_move)
      SetStatus(st_time_limit_move);
   if(limits->max_tm_game && lmts.max_tm_game > limits->max_tm_game)
      SetStatus(st_time_limit_game);
   if(limits->max_mem && lmts.max_mem > limits->max_mem)
      SetStatus(st_memory_limit);
   if(limits->max_move && lmts.max_move > limits->max_move)
      SetStatus(st_move_limit);

   if(!IsRunning() && exitcode) SetStatus(st_run_time_error);

   buf[0] = status;
   buf[1] = ' ';
   
   return stat;
}

void CPlayer::DeleteFiles(char *dir)
{
   if(dir)
   {
      char fl[MAX_STR_LEN];

      sprintf_s(fl, "%s%s", dir, compil->FileIn);
      StrReplace(fl, REPLACE_ID, id_s);
      if(FileExists(fl)) DeleteFile(fl);

      sprintf_s(fl, "%s%s", dir, compil->FileObj);
      StrReplace(fl, REPLACE_ID, id_s);
      if(FileExists(fl)) DeleteFile(fl);

      sprintf_s(fl, "%s%s", dir, compil->FileOut);
      StrReplace(fl, REPLACE_ID, id_s);
      if(FileExists(fl)) DeleteFile(fl);
   }

   if(FileExists(srcfile)) DeleteFile(srcfile);
   if(FileExists(exefile)) DeleteFile(exefile);
   //if(FileExists(compilout)) DeleteFile(compilout);
}

int CPlayer::Compile(char *dir)
{
   int stat = 0;
   char compil_scr[MAX_STR_LEN], 
        compil_prm[MAX_STR_LEN],
        query_str[MAX_STR_LEN];
   SHELLEXECUTEINFO se;

   strcpy_s(compil_scr, compil->CompilScript);
   strcpy_s(compil_prm, compil->CompilParam);
   StrReplace(compil_prm, REPLACE_ID, id_s);
   strcpy_s(query_str, compil_prm);

   sprintf_s(compilout, "%scompil%d.out", CompilOutDir, id);
   sprintf_s(compil_prm, "%s >\"%s\"", query_str, compilout);

   memset(&se,0,sizeof(SHELLEXECUTEINFO));
   se.cbSize = sizeof(SHELLEXECUTEINFO);
   se.hwnd = NULL;
   se.lpVerb = NULL;//"open";
   se.lpFile = compil_scr;
   se.lpParameters =compil_prm;
   se.lpDirectory = dir;
   se.fMask = SEE_MASK_NOCLOSEPROCESS;
   if(ShellExecuteEx(&se))
   {
      WaitForSingleObject(se.hProcess, INFINITE);
      CloseHandle(se.hProcess);
   }

   //проверим наличие выходного файла
   sprintf_s(exefile, "%s%s", dir, compil->FileOut);
   StrReplace(exefile, REPLACE_ID, id_s);
   //sprintf(obj_file,"%s%s",master_cfg->GlobalPaths->DirTemp,compil->FileObj);
   //StrReplace(obj_file,REPLACE_ID,s);
   if (!FileExists(exefile))
   {
      SetStatus(st_compilation_error);
   }

   return stat;
}

int CChecker::GetData(DWORD dt)
{
   int stat = 0;
   BOOL ok = true;
   unsigned long dwRead = 0, k = 0;
   DWORD t1, t2;
   t1 = t2 = GetTickCount();
   ZeroMemory(buf, szBuf);
   for( ; t2 - t1 <= dt; )
   {
      if((PeekNamedPipe(hStdout, NULL, 0, NULL, &dwRead, NULL) == TRUE) && (dwRead > 0))
      {    
         ok = ReadFile(hStdout, buf+k, 1, &dwRead, NULL);
         if((FALSE == ok) || !dwRead) break;
         k += dwRead;
         if(buf[k-1] == '\n') break;
         dwRead = 0;
      }
      t2 = GetTickCount();
   }
   trim(buf);
   sprintf_s(logfile.str, "Получены данные от чекера [%s]", buf);
   logfile.Write(9);

   buf[strlen(buf)] = '\n';
   buf[strlen(buf)] = 0;

   return stat;
}

int CChecker::GiveData(char *buf)
{
   int stat = 0;
   unsigned long dwWritten;

   if(!IsRunning()) return -1;
   trim(buf);
   sprintf_s(logfile.str, "Передаем данные чекеру [%s]", buf);
   logfile.Write(9);
   buf[strlen(buf)] = '\n';
   buf[strlen(buf)] = 0;

   if(!WriteFile(hStdin, buf, (DWORD)strlen(buf), &dwWritten, NULL)) ErrWinAPI();

   return stat;
}