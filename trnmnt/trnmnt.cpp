#include "trnmnt.h"
#include "compil.h"
#include "db_util.h"
#include "play.h"
#include <assert.h>


char PlayDir[MAX_STR_LEN];
char TestPlayDir[MAX_STR_LEN];
char USER[MAX_STR_SHORT_LEN];
char PASSWORD[MAX_STR_SHORT_LEN];
char GameFolder[MAX_STR_SHORT_LEN];
char LogFileName[MAX_STR_LEN];
bool DeleteLog = true;
char CompilOutDir[MAX_STR_LEN];
char trnmntlog[MAX_STR_LEN];

const char cfg_file[] = "c:\\acm\\trnmnt\\trnmnt.cfg";

char CompilerCFG[MAX_STR_LEN];
char section[] = "Custom";
char dbfile[MAX_STR_LEN];
char dbuser[MAX_STR_SHORT_LEN];
char dbpass[MAX_STR_SHORT_LEN];

DWORD FreezTime = 1000;
int dbglevel = 5;

int TournamentInit()
{
   int stat = 0;
   char tmp[MAX_STR_SHORT_LEN];
   size_t l = 0;

   stat = stat || 0 == GetPrivateProfileString(section, "DataBase",    "", dbfile,      MAX_STR_LEN,       cfg_file);
   stat = stat || 0 == GetPrivateProfileString(section, "dbuser",      "", dbuser,      MAX_STR_SHORT_LEN, cfg_file);
   stat = stat || 0 == GetPrivateProfileString(section, "dbpassword",  "", dbpass,      MAX_STR_SHORT_LEN, cfg_file);
   stat = stat || 0 == GetPrivateProfileString(section, "PlayDir",     "", PlayDir,     MAX_STR_LEN,       cfg_file);
   stat = stat || 0 == GetPrivateProfileString(section, "TestPlayDir", "", TestPlayDir, MAX_STR_LEN,       cfg_file);
   stat = stat || 0 == GetPrivateProfileString(section, "user",        "", USER,        MAX_STR_SHORT_LEN, cfg_file);
   stat = stat || 0 == GetPrivateProfileString(section, "password",    "", PASSWORD,    MAX_STR_SHORT_LEN, cfg_file);
   stat = stat || 0 == GetPrivateProfileString(section, "GameFolder",  "", GameFolder,  MAX_STR_SHORT_LEN, cfg_file);
   stat = stat || 0 == GetPrivateProfileString(section, "CompilerCFG", "", CompilerCFG, MAX_STR_LEN,       cfg_file);
   stat = stat || 0 == GetPrivateProfileString(section, "LogFile",     "", LogFileName, MAX_STR_LEN,       cfg_file);
   stat = stat || 0 == GetPrivateProfileString(section, "CompilOutDir","", CompilOutDir,MAX_STR_LEN,       cfg_file);
   stat = stat || 0 == GetPrivateProfileString(section, "trnmntlog",   "", trnmntlog,   MAX_STR_LEN,       cfg_file);

   stat = stat || 0 == GetPrivateProfileString(section, "deletelog",   "", tmp,         MAX_STR_SHORT_LEN, cfg_file);
   DeleteLog = (bool)strcmp(tmp, "NO");
   stat = stat || 0 == GetPrivateProfileString(section, "FreezTime",   "1000", tmp,     MAX_STR_SHORT_LEN, cfg_file);
   FreezTime = atoi(tmp);
   stat = stat || 0 == GetPrivateProfileString(section, "dbglvl",      "5",tmp,         MAX_STR_SHORT_LEN, cfg_file);
   dbglevel = atoi(tmp);

   if(stat) return stat;

   l = strlen(PlayDir);
   PlayDir[l++] = '\\';
   PlayDir[l++] = '\0';

   l = strlen(TestPlayDir);
   TestPlayDir[l++] = '\\';
   TestPlayDir[l++] = '\0';

   l = strlen(CompilOutDir);
   CompilOutDir[l++] = '\\';
   CompilOutDir[l++] = '\0';

   return ReadCompilers(CompilerCFG);
}

void TournamentDeInit()
{
   for(VCCompilers::iterator it = Compilers.begin(); it != Compilers.end(); it++)
      delete *it;
}


int NeedQuit()
{
	return false;
   static int k = 0; 
   k++;
   return k > 10000;
}

//================================================================
int WINAPI WinMain(HINSTANCE hInst, HINSTANCE hPrevInst, LPSTR CmdLine, int nCmdShow)
{
   if(TournamentInit())
   {
      return 0;
   }
   logfile.open(trnmntlog, ios::out | ios::app);
   logfile.SetLevel(dbglevel);
   sprintf_s(logfile.str, "Начало работы сервера");
   logfile.Write(0);
   //соединение с БД
   if(!DB->Connect(dbfile, dbuser, dbpass)) do
   {
      sprintf_s(logfile.str, "\n\nНачат новый цикл проверки");
      logfile.Write(7);
      //проверить вновь поступившие решения
      //у которых gm_slv.test_result = -1
      check_new();
      
      if(NeedQuit())
      {
         sprintf_s(logfile.str, "Отключение от базы данных");
         logfile.Write(2);
         DB->Disconnect();
         break;
      }
      //проверим все назначенные партии игр
      //playing.state = game_state_forplay
      check_playing(GameFolder);

      //проверка завершившихся турниров
      
      if(NeedQuit())
      {
         sprintf_s(logfile.str, "Отключение от базы данных");
         logfile.Write(2);
         DB->Disconnect();
         break;
      }
      Sleep(FreezTime);
   } while(true);
   else
   {
      sprintf_s(logfile.str, "Ошибка при подключении к базе данных");
      logfile.Write(0);
   }
   
   sprintf_s(logfile.str, "Завершение работы сервера");
   logfile.Write(0);
   
   TournamentDeInit();

   return 0;
}
//================================================================



char *trim(char *s, char *str)
{
   char *ch = strchr(s, 0);
   char s_tmp[] = " \t\r\n";
   if(!str) str = s_tmp;
   ch--;
   while((ch >= s) && *ch && strchr(str, *ch))
   {
      *ch = 0;
       ch--;
   }
   return ch;
}

void StrCopy(char *dest, char *src, int len)
{
   strncpy_s(dest, len, src, len);
   dest[len-1] = 0;
}

//замена всех вхождений подстроки str_find в строку str_src на строку str_new
void StrReplace(char *str_src, char *str_find, char *str_new)
{
   size_t pos;
   string src, fnd(str_find), nw(str_new), bf;

   while(1)
   {
      src = string(str_src);
      pos = src.find(fnd);
      if(pos == -1) break;
      bf = src.substr(0,pos) + nw + src.substr(pos+fnd.length());
      strcpy_s(str_src, MAX_STR_LEN-1, bf.c_str());
   }
}

//проверка существования файла
int FileExists(char *filename)
{
  HANDLE hnd;
  WIN32_FIND_DATA FD;

  hnd = FindFirstFile(filename, &FD);
  if(hnd != INVALID_HANDLE_VALUE)
  {
     FindClose(hnd);
     if((FD.dwFileAttributes & FILE_ATTRIBUTE_DIRECTORY) == 0)
        return 1;
  }
  return 0;
}

int ErrWinAPI()
{
   UINT err = GetLastError();
   sprintf_s(logfile.str, "Ошибка WinAPI #%u", err);
   logfile.Write(0);
   return err;
}
