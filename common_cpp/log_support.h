
#ifndef logsupportH
#define logsupportH

#include <fstream>
#include "..\common_cpp\shared_types.h"

using namespace std;

class TLogFile : public ofstream {
   private:
      char *func_name;
      int level_log;
      int status_error;
      Tstek *stek_call;
      void init(void);

   public:
      TLogFile():ofstream(){init();}
      TLogFile(const char *fl):ofstream(fl){init();}
      ~TLogFile();
      void SetLevelLog(int lv);
      void SetFunc(const char *);
      TLogFile &ApiErr(const char *f);
      TLogFile &ln(int n=0);
      TLogFile &err(void);
      TLogFile &operator<<(ostream& (*pf)(ostream&));

      TLogFile &operator<<(const char *s);
      TLogFile &operator<<(int i);

   ostream friend &fb(ostream &stream);
   ostream friend &fe(ostream &stream);
   ostream friend &t(ostream &stream);
};

ostream &fb(ostream &stream);
ostream &fe(ostream &stream);
ostream &t(ostream &stream);

#endif