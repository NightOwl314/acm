
#include <cstring>
#include <windows.h>
#include <iomanip>
#include "..\common_cpp\log_support.h"

using namespace std;

void TLogFile::init(void)
{
   stek_call=new Tstek(1000);
}

TLogFile::~TLogFile()
{
   delete stek_call;
}


void TLogFile::SetLevelLog(int lv)
{
   level_log=lv;
}

void TLogFile::SetFunc(const char *fn)
{
   func_name=new char[strlen(fn)+1];
   strcpy(func_name,fn);
   stek_call->push(func_name);

   status_error=0;
}

ostream &fb(ostream &stream)
{
   TLogFile *lf=(TLogFile*)&stream;
   *lf << "[" << lf->func_name << "] START \n";
   return *lf;
}

ostream &fe(ostream &stream)
{
   TLogFile *lf=(TLogFile*)&stream;
   lf->stek_call->pop((void**)&lf->func_name);
   *lf << "[" << lf->func_name << "] END \n";
   delete[] lf->func_name;
   return *lf;
}

ostream &t(ostream &stream)
{
   SYSTEMTIME sys_tm;
   GetLocalTime(&sys_tm);
   TLogFile *lf=(TLogFile*)&stream;

   *lf << setfill('0') << "["
              << setw(2) << sys_tm.wDay <<   "."
              << setw(2) << sys_tm.wMonth <<   "."
              << setw(4) << sys_tm.wYear <<   " "
              << setw(2) << sys_tm.wHour <<   ":"
              << setw(2) << sys_tm.wMinute << ":"
              << setw(2) << sys_tm.wSecond << "."
              << setw(3) << sys_tm.wMilliseconds << "] ";

   return *lf;
}

TLogFile &TLogFile::err(void)
{
   status_error=1;
   if (level_log) ln();
   *this << "*** " << t << " ERROR in [" << (char *)stek_call->ptr() << "]: ";
   return *this;
}

TLogFile &TLogFile::ApiErr(const char *f)
{
   err() << "  CALL [" << f << "] GetLastError=" << GetLastError() << "\n";
   return *this;
}

TLogFile &TLogFile::ln(int n)
{
   for (int i=0;i<stek_call->Size()+n-1;i++)
      *this << "   ";
   return *this;
}

TLogFile &TLogFile::operator<<(const char *s)
{
   if (level_log || status_error) {
      ofstream::operator<<(s);
      if (strstr(s,"\n")) {
         flush();
         if (status_error) status_error=0;
      }
   }

   return *this;
}

TLogFile &TLogFile::operator<<(int i)
{
   if (level_log || status_error) {
      ofstream::operator<<(i);
   }

   return *this;
}

TLogFile &TLogFile::operator<<(ostream& (*pf)(ostream&))
{
   ofstream::operator<<(pf);
   return *this;
}

