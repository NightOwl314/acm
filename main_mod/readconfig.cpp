#define _CRT_SECURE_NO_DEPRECATE

#include <windows.h>

#include "..\common_cpp\result_id.h"
#include "readconfig.h"

TConfig::TConfig()
{
   GlobalPaths = new TGlobalPaths;
   ProblemPaths = new TProblemPaths;
   DataBase = new TDB;
   Options = new TOptions;

   GlobalPaths->DirTemp = new char[STRSZ];
   GlobalPaths->DirTempSrc = new char[STRSZ];
   GlobalPaths->DirSrcArhive = new char[STRSZ];
   GlobalPaths->DirProblems = new char[STRSZ];
   GlobalPaths->CompilCfg = new char[STRSZ];
   GlobalPaths->Test_protectDll = new char[STRSZ];
   GlobalPaths->LogFile = new char[STRSZ];

   ProblemPaths->Tests = new char[STRSZ];
   ProblemPaths->Preliminary = new char[STRSZ];
   ProblemPaths->WrongAnswerPrg = new char[STRSZ];
   ProblemPaths->ListTests = new char[STRSZ];
   ProblemPaths->ListPoints = new char[STRSZ];
   ProblemPaths->ListPreliminary = new char[STRSZ];

   DataBase->dbname = new char[STRSZ];
   DataBase->user = new char[STRSZ];
   DataBase->password = new char[STRSZ];

   Options->BestSourceFormula = new char[STRSZ];
   Options->DelAccessUsersGroups = new char[STRSZ];
   Options->cnt_del_sids=0;
   Options->del_sids=NULL;

   compilers=NULL;
   CompilCnt=0;
}

TConfig::~TConfig()
{
   delete[] GlobalPaths->DirTemp;
   delete[] GlobalPaths->DirTempSrc;
   delete[] GlobalPaths->DirSrcArhive;
   delete[] GlobalPaths->DirProblems;
   delete[] GlobalPaths->CompilCfg;
   delete[] GlobalPaths->Test_protectDll;
   delete[] GlobalPaths->LogFile;

   delete[] ProblemPaths->Tests;
   delete[] ProblemPaths->Preliminary;
   delete[] ProblemPaths->WrongAnswerPrg;
   delete[] ProblemPaths->ListTests;
   delete[] ProblemPaths->ListPoints;
   delete[] ProblemPaths->ListPreliminary;

   delete[] DataBase->dbname;
   delete[] DataBase->user;
   delete[] DataBase->password;

   delete[] Options->BestSourceFormula;
   delete[] Options->DelAccessUsersGroups;
	for (int d=0;d<Options->cnt_del_sids;d++) 
		if (Options->del_sids[d].Sid) 
			delete[] (char*)(Options->del_sids[d].Sid);
   if (Options->del_sids!=NULL) delete[] Options->del_sids;

   delete GlobalPaths;
   delete ProblemPaths;
   delete DataBase;

   if (compilers!=NULL) {
      for (int i=0;i<CompilCnt;i++) {
         delete[] compilers[i].FileIn;
         delete[] compilers[i].FileOut;
         delete[] compilers[i].FileObj;
         delete[] compilers[i].WhiteListFile;
         delete[] compilers[i].CompilScript;
         delete[] compilers[i].CompilParam;
         delete[] compilers[i].RunCmd;
      }
      delete[] compilers;
   }
}

void TConfig::AddSlesh(char *s) const
{
   int ln=strlen(s);
   if (s[ln-1]!='\\') {
      s[ln]='\\';
      s[ln+1]='\0';
   }
}

#define GLOBALPATHS "global paths"
#define PROBLEMPATHS "problem paths"
#define DATABASE "database"
#define OPTIONS "options"
void TConfig::Read(const char *filename)
{
   char s[20];

   GetPrivateProfileString(GLOBALPATHS,"DirTemp",NULL,GlobalPaths->DirTemp,STRSZ,filename);
   AddSlesh(GlobalPaths->DirTemp);

   GetPrivateProfileString(GLOBALPATHS,"DirTempSrc",NULL,GlobalPaths->DirTempSrc,STRSZ,filename);
   AddSlesh(GlobalPaths->DirTempSrc);

   GetPrivateProfileString(GLOBALPATHS,"DirSrcArhive",NULL,GlobalPaths->DirSrcArhive,STRSZ,filename);
   AddSlesh(GlobalPaths->DirSrcArhive);

   GetPrivateProfileString(GLOBALPATHS,"DirProblems",NULL,GlobalPaths->DirProblems,STRSZ,filename);
   AddSlesh(GlobalPaths->DirProblems);

   GetPrivateProfileString(GLOBALPATHS,"CompilCfg",NULL,GlobalPaths->CompilCfg,STRSZ,filename);
   GetPrivateProfileString(GLOBALPATHS,"Test_protectDll",NULL,GlobalPaths->Test_protectDll,STRSZ,filename);
   GetPrivateProfileString(GLOBALPATHS,"LogFile",NULL,GlobalPaths->LogFile,STRSZ,filename);

   GetPrivateProfileString(PROBLEMPATHS,"Tests",NULL,ProblemPaths->Tests,STRSZ,filename);
   AddSlesh(ProblemPaths->Tests);
   GetPrivateProfileString(PROBLEMPATHS,"Preliminary",NULL,ProblemPaths->Preliminary,STRSZ,filename);
   AddSlesh(ProblemPaths->Preliminary);

   GetPrivateProfileString(PROBLEMPATHS,"WrongAnswerPrg",NULL,ProblemPaths->WrongAnswerPrg,STRSZ,filename);
   GetPrivateProfileString(PROBLEMPATHS,"ListTests",NULL,ProblemPaths->ListTests,STRSZ,filename);
   GetPrivateProfileString(PROBLEMPATHS,"ListPoints",NULL,ProblemPaths->ListPoints,STRSZ,filename);
   GetPrivateProfileString(PROBLEMPATHS,"ListPreliminary",NULL,ProblemPaths->ListPreliminary,STRSZ,filename);

   GetPrivateProfileString(DATABASE,"dbname",NULL,DataBase->dbname,STRSZ,filename);
   GetPrivateProfileString(DATABASE,"user",NULL,DataBase->user,STRSZ,filename);
   GetPrivateProfileString(DATABASE,"password",NULL,DataBase->password,STRSZ,filename);


   GetPrivateProfileString(OPTIONS,"SourceCountArh",NULL,s,20,filename);
   Options->SourceCountArh=atoi(s);

   GetPrivateProfileString(OPTIONS,"MaxFileSizeAddOtchet",NULL,s,20,filename);
   Options->MaxFileSizeAddOtchet=atoi(s);

   GetPrivateProfileString(OPTIONS,"WriteExLog",NULL,s,20,filename);
   Options->WriteExLog=atoi(s);

   GetPrivateProfileString(OPTIONS,"BestSourceFormula",NULL,Options->BestSourceFormula,STRSZ,filename);

   GetPrivateProfileString(OPTIONS,"CheckerTimeLimit",NULL,s,20,filename);
   Options->CheckerTimeLimit=atoi(s);

   GetPrivateProfileString(OPTIONS,"CheckerSleepLimit",NULL,s,20,filename);
   Options->CheckerSleepLimit=atoi(s);

   GetPrivateProfileString(OPTIONS,"DelAccessUsersGroups",NULL,Options->DelAccessUsersGroups,STRSZ,filename);
   ParseSIDs();
   
   ReadCompilers(GlobalPaths->CompilCfg);
}

void TConfig::ReadCompilers(const char *filename)
{
   int bfsz=16384,i;
   char *buff=new char[bfsz], *x, s[20];

   //������� ��� ������ ����� ������������ ������������
   GetPrivateProfileString(NULL,NULL,NULL,buff,bfsz,filename);
   x=buff;
   while (x[0]!=0) {
      x+=strlen(x)+1;
      CompilCnt++;
   }

   compilers = new TCompiler[CompilCnt];
   x=buff;
   i=0;
   while (x[0]!=0) {
      compilers[i].FileIn = new char[STRSZ];
      compilers[i].FileOut = new char[STRSZ];
      compilers[i].FileObj = new char[STRSZ];
      compilers[i].WhiteListFile = new char[STRSZ];
//    compilers[i].CompilCmd = new char[STRSZ];
      compilers[i].CompilScript = new char[STRSZ];
      compilers[i].CompilParam = new char[STRSZ];
      compilers[i].RunCmd = new char[STRSZ];

      GetPrivateProfileString(x,"id",NULL,s,20,filename);
      compilers[i].id=atoi(s);
      GetPrivateProfileString(x,"AdjMemory",NULL,s,20,filename);
      compilers[i].AdjMemory=atoi(s);
      GetPrivateProfileString(x,"AdjTime",NULL,s,20,filename);
      compilers[i].AdjTime=atoi(s);
      GetPrivateProfileString(x,"ProtectMode",NULL,s,20,filename);
      compilers[i].ProtectMode=atoi(s);
      GetPrivateProfileString(x,"MinLenComStr",NULL,s,20,filename);
      compilers[i].MinLenComStr=atoi(s);

      GetPrivateProfileString(x,"FileIn",NULL,compilers[i].FileIn,STRSZ,filename);
      GetPrivateProfileString(x,"FileOut",NULL,compilers[i].FileOut,STRSZ,filename);
      GetPrivateProfileString(x,"FileObj",NULL,compilers[i].FileObj,STRSZ,filename);
      GetPrivateProfileString(x,"WhiteListFile",NULL,compilers[i].WhiteListFile,STRSZ,filename);
//      GetPrivateProfileString(x,"CompilCmd",NULL,compilers[i].CompilCmd,STRSZ,filename);
      GetPrivateProfileString(x,"CompilScript",NULL,compilers[i].CompilScript,STRSZ,filename);
      GetPrivateProfileString(x,"CompilParam",NULL,compilers[i].CompilParam,STRSZ,filename);
      GetPrivateProfileString(x,"RunCmd",NULL,compilers[i].RunCmd,STRSZ,filename);

      x+=strlen(x)+1;
      i++;
   }

   delete[] buff;
}

TCompiler* TConfig::CompilerId(int id)
{
   int i;
   for (i=0;i<CompilCnt;i++) {
      if (compilers[i].id==id) return &compilers[i];
   }
   return NULL;
}

void TConfig::ParseSIDs(void)
{
	int i,cnt=1,j,er,ln;
	char name[255];
    DWORD sbSid,sbDomain;
	SID_NAME_USE snu;
	PSID sid;
	char nmDomain[255];

	for (int d=0;d<Options->cnt_del_sids;d++) 
		if (Options->del_sids[d].Sid) 
			delete[] (char*)(Options->del_sids[d].Sid);
	if (Options->del_sids) delete[] Options->del_sids;
    
	ln=strlen(Options->DelAccessUsersGroups);
	for (i=0;i<ln;i++)
		if (Options->DelAccessUsersGroups[i]==';') cnt++;
	Options->cnt_del_sids=cnt;
	Options->del_sids=new SID_AND_ATTRIBUTES[cnt];

	cnt=0;
	j=0;
	for (i=0;i<=strlen(Options->DelAccessUsersGroups);i++) {
		name[j]=Options->DelAccessUsersGroups[i];
		if (name[j]==';' || name[j]=='\0') {
			name[j]=0;
			sbSid=0;
			sbDomain=255;

            LookupAccountName(0,name,0,&sbSid,0,&sbDomain,&snu);
			if (sbSid>0) {
			sid=new char[sbSid];
	        er=LookupAccountName(0,name,sid,&sbSid,nmDomain,&sbDomain,&snu);
	        Options->del_sids[cnt].Sid=sid;
			} else {
				Options->del_sids[cnt].Sid=NULL;
			}
	        Options->del_sids[cnt].Attributes=0;
			cnt++;
			j=-1;
		}
		j++;
	}
}

TPaths::TPaths(void)
{
   DirTests=new char[MAX_PATH];
   DirPreliminary=new char[MAX_PATH];
   FileTest=new char[MAX_PATH];
   FileInteract=new char[MAX_PATH];
   WAProg=new char[MAX_PATH];
   tst=new char[MAX_PATH];
   out=new char[MAX_PATH];
   inp=new char[MAX_PATH];
   WLFile=new char[MAX_PATH];
   dir_temp=new char[MAX_PATH];
   inpF=new char[MAX_PATH];
   outF=new char[MAX_PATH];
   errF=new char[MAX_PATH];
   compil_outF=new char[MAX_PATH];
   checker_outF=new char[MAX_PATH];
   correct_outF=new char[MAX_PATH];
   dllF=new char[MAX_PATH];
   ListTests=new char[MAX_PATH];
   ListPoints=new char[MAX_PATH];
   ListPreliminary=new char[MAX_PATH];
   otchetF=new char[MAX_PATH];
   plagiat_text=new char[MAX_PATH];
   summary_report=new char[MAX_PATH];

   inpF_del=0;
   correct_outF_del=0;
}

TPaths::~TPaths()
{
   delete[] DirTests;
   delete[] DirPreliminary;
   delete[] FileTest;
   delete[] FileInteract;
   delete[] WAProg;
   delete[] tst;
   delete[] out;
   delete[] inp;
   delete[] WLFile;
   delete[] dir_temp;
   delete[] inpF;
   delete[] outF;
   delete[] errF;
   delete[] compil_outF;
   delete[] checker_outF;
   delete[] correct_outF;
   delete[] dllF;
   delete[] ListTests;
   delete[] ListPoints;
   delete[] ListPreliminary;
   delete[] otchetF;
   delete[] plagiat_text;
   delete[] summary_report;
}

void TPaths::del_temp_files(int del_compil_out)
{
   DeleteFile(outF);
   outF[0]=0;

   DeleteFile(errF);
   errF[0]=0;

   DeleteFile(checker_outF);
   checker_outF[0]=0;

   if (inpF_del) {
      DeleteFile(inpF);
      inpF[0]=0;
   }

   if (correct_outF_del) {
      DeleteFile(correct_outF);
      correct_outF[0]=0;
   }

   if (del_compil_out) {
      DeleteFile(compil_outF);
      compil_outF[0]=0;
   }
}

char* TPaths::get_report_name(int id_rpt)
{
   char *rez=NULL;
   switch (id_rpt) {
      case RPT_COMPILER_OUTPUT:
         rez=compil_outF; break;

      case RPT_INPUT:
         rez=inpF; break;

      case RPT_TEST_OUTPUT:
         rez=outF; break;

      case RPT_CORRECT_OUTPUT:
         rez=correct_outF; break;

      case RPT_TEST_ERROR:
         rez=errF; break;

      case RPT_CHECKER_OUTPUT:
         rez=checker_outF; break;

      case RPT_PLAGIAT_OUTPUT:
         rez=plagiat_text; break;
      
      case RPT_SUMMARY_REPORT:      
         //rez=summary_report; break; //�� ����������� :)
		 rez = otchetF; break;
   }
   return rez;
}
