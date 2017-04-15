
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
   char *Preliminary;
   char *WrongAnswerPrg;
   char *ListTests;
   char *ListPoints;
   char *ListPreliminary;
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
   char *DelAccessUsersGroups;
   int cnt_del_sids;
   SID_AND_ATTRIBUTES *del_sids;
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
   int  MinLenComStr;
};

class TConfig
{
   private:
      TCompiler *compilers;
      int CompilCnt;
      void AddSlesh(char *s) const;
      void ReadCompilers(const char *filename);
	  void ParseSIDs(void);

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
   char *DirTests; //каталог в котором лежат тесты
   char *DirPreliminary; //каталог в котором лежат тесты из условия
   char *FileTest; //полное имя файла тестируемой программы
   char *FileInteract; //полное имя файла программы жюри, взаимодействующей с интерактивной задачей
   char *WAProg;  //полное имя файла программы проверки вывода
   char *tst;  //имя файла вывода полученного от проверяемой программы
   char *out;  //имя файла вывода из каталога с тестами
   char *inp;  //имя файла ввода из каталога с тестами
   char *WLFile;  //полное имя файла белого списка

   char *dir_temp; //каталог для всех временных файлов создаваемых при проверке

   char *inpF;  //полное имя файла ввода
   int inpF_del;  //удалить входной файл (ранее была сделана копия)

   char *outF;  //полное имя файла вывода
   char *errF;  //полное имя файла ошибок

   char *compil_outF;  //полное имя файла вывода компилятора
   char *checker_outF;  //полное имя файла вывода чекера
   char *correct_outF;  //полное имя файла правильного вывода
   int correct_outF_del;  //удалить файл правильного вывода (ранее была сделана копия)

   char *dllF;  //полное имя файла либы
   char *ListTests;  //полное имя файла списка тестов
   char *ListPoints; //полное имя файла c баллами за тесты    
   char *ListPreliminary; //полное имя файла списка тестов из условия
   char *otchetF;  //полное имя файла отчета

   char *summary_report; //полное имя файла с отчетом для системы оценивания SCHOOL

   char *plagiat_text; //отчет работы модуля анализа плагиата
   int protect; //режим работы защиты
   short debug_protect; //если 1, то после нарушения безопасности выполнение проги продолжится
   int id_uniq; //уникальный идентификатор для поддержки работы нескольких серверов

   TPaths(void);
   ~TPaths();
   void del_temp_files(int del_compil_out=0);
   char* get_report_name(int id_rpt);
};


#endif
