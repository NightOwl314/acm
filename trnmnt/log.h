#ifndef log_h_
#define log_h_

#include <fstream>
#include <windows.h>

class CLog : public std::ofstream
{
private:
   int limit_level;
   SYSTEMTIME tm;

public:
   char str[300];
   CLog();
   CLog(int l);
   ~CLog();
   void Write(int l, char *s = NULL, int d = 0);
   void SetLevel(int l);
};

extern CLog logfile;
#endif