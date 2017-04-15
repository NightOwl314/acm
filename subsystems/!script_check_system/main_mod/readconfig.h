
#ifndef readconfigH
#define readconfigH

#define STRSZ 300

struct TGlobalPaths {
   char *DirTemp;
   char *DirTempSrc;
   char *DirSrcArhive;
   char *DirProblems;
   char *CompilCfg;
   char *Test_protectDll;
   char *LogFile;
};

struct TProblemPaths {
   char *Tests;
   char *WrongAnswerPrg;
   char *ListTests;
};

struct TDB {
   char *dbname;
   char *user;
   char *password;
};      

struct TOptions {
   int SourceCountArh;
   int MaxFileSizeAddOtchet;
   int WriteExLog;
   char *BestSourceFormula;
   unsigned int CheckerTimeLimit;
   unsigned int CheckerSleepLimit;
};

struct TCompiler {
   int id;
   char *FileIn;
   char *FileOut;
   char *FileObj;
   char *WhiteListFile;
   char *CompilScript;
   char *CompilParam;
   char *RunCmd;
   int  AdjMemory;
   int  AdjTime;
   int  ProtectMode;
};

class TConfig
{
   private:
      TCompiler *compilers;
      int CompilCnt;
      void AddSlesh(char *s) const;
      void ReadCompilers(const char *filename);

   public:
      TGlobalPaths *GlobalPaths;
      TProblemPaths *ProblemPaths;
      TDB *DataBase;
      TOptions *Options;

      TConfig();
      ~TConfig();
      void Read(const char *filename);
      TCompiler* CompilerId(int id);
};


class TPaths{
public:
   char *DirTests; //������� � ������� ����� �����
   char *FileTest; //������ ��� ����� ����������� ���������
   char *WAProg;  //������ ��� ����� ��������� �������� ������
   char *tst;  //��� ����� ������ ����������� �� ����������� ���������
   char *out;  //��� ����� ������ �� �������� � �������
   char *inp;  //��� ����� ����� �� �������� � �������
   char *WLFile;  //������ ��� ����� ������ ������

   char *dir_temp; //������� ��� ���� ��������� ������ ����������� ��� ��������

   char *inpF;  //������ ��� ����� �����
   int inpF_del;  //������� ������� ���� (����� ���� ������� �����)

   char *outF;  //������ ��� ����� ������
   char *errF;  //������ ��� ����� ������

   char *compil_outF;  //������ ��� ����� ������ �����������
   char *checker_outF;  //������ ��� ����� ������ ������
   char *correct_outF;  //������ ��� ����� ����������� ������
   int correct_outF_del;  //������� ���� ����������� ������ (����� ���� ������� �����)

   char *dllF;  //������ ��� ����� ����
   char *ListTests;  //������ ��� ����� ������ ������
   char *otchetF;  //������ ��� ����� ������

   char *plagiat_text; //����� ������ ������ ������� ��������
   int protect; //����� ������ ������
   short debug_protect; //���� 1, �� ����� ��������� ������������ ���������� ����� �����������
   int id_uniq; //���������� ������������� ��� ��������� ������ ���������� ��������

   TPaths(void);
   ~TPaths();
   void del_temp_files(int del_compil_out=0);
   char* get_report_name(int id_rpt);
};


#endif