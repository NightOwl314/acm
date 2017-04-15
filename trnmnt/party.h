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

   IDENTITY id;//��
   IDENTITY id_trnmnt;
   char strid[27];
   char exefile[MAX_STR_LEN];//����������� ����
   char srcfile[MAX_STR_LEN];
   char compilout[MAX_STR_LEN];
   char id_s[32];
   CCompiler *compil;
   DWORD exitcode;
   char buf[szBuf+2];   

   //�����������
   CPartipiant(){return;}

   int Run(HANDLE hToken = 0);//���������
   int Stop();//����������

   virtual int GiveData(char *buf) = 0;//�������� ������

   //����������
   ~CPartipiant(){return;}
protected:
   bool IsRunning();
};

class CChecker : public CPartipiant
{
public:

   int GetData(DWORD dt = 3000) ;//�������� ������
   int GiveData(char *buf);//�������� ������
};

class CPlayer : public CPartipiant
{
public:
   INTEGER number;
   INTEGER rank;//����� � ����
   INTEGER points;//��������� �����
   INTEGER test_result;//��������� ������������ �����
   INTEGER count_err, count_ok;

   TLimits lmts;//��������� �� �����������
   TLimits cur_lmts;

   //HANDLE hjob;
   int status;//���������

   int Run(HANDLE hToken = 0);//���������
   int GetData(DWORD dt = 1000) ;//�������� ������
   int GiveData(char *buf);//�������� ������
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