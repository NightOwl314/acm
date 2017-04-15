#ifndef party_h_
#define party_h_

#include "trnmnt.h"
#include "compil.h"

class CPartipiant
{
public:
   HANDLE hStdout, hStdin, hStderr;
   HANDLE hProcessToken;
   STARTUPINFO siStartInfo;
   PROCESS_INFORMATION piProcInfo;

   IDENTITY id;//ИД
   IDENTITY id_trnmnt;
   char strid[27];
   char exefile[MAX_STR_LEN];//исполняемый файл
   char srcfile[MAX_STR_LEN];
   char compilout[MAX_STR_LEN];
   char id_s[32];
   CCompiler *compil;
   DWORD exitcode;
   char buf[szBuf+2];   

   //конструктор
   CPartipiant(){return;}

   int Run(HANDLE hToken = 0);//запустить
   int Stop();//остановить

   virtual int GiveData(char *buf) = 0;//передать данные

   //деструктор
   ~CPartipiant(){return;}
protected:
   bool IsRunning();
};

class CChecker : public CPartipiant
{
public:

   int GetData(DWORD dt = 3000) ;//получить данные
   int GiveData(char *buf);//передать данные
};

class CPlayer : public CPartipiant
{
public:
   INTEGER number;
   INTEGER rank;//место в игре
   INTEGER points;//набранные быллы
   INTEGER test_result;//результат контрольного теста
   INTEGER count_err, count_ok;

   TLimits lmts;//параметры по ограничеиям
   TLimits cur_lmts;

   //HANDLE hjob;
   int status;//состояние

   int Run(HANDLE hToken = 0);//запустить
   int GetData(DWORD dt = 1000) ;//получить данные
   int GiveData(char *buf);//передать данные
   int UpdateStatus(TLimits *lmts);
   int Compile(char *dir);
   void SetStatus(int st);
   void DeleteFiles(char *dir = NULL);

   CPlayer();
   ~CPlayer();
private:
   bool IsRunning();
};

typedef vector<CPlayer*> VCPlayers;

#endif