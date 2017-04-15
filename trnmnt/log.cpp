#include "log.h"

CLog::CLog(int l)
{
   limit_level = l;
   return;
}

CLog::CLog()
{
   limit_level = 0;
   return;
}

CLog::~CLog()
{
   return;
}

void CLog::Write(int l, char *s, int d)
{
   if(l > limit_level) return;

   for(int i = 0; i < d; i++)
      *this << ' ';

   if(s) *this << s;
   else *this << str;

   *str = 0;
   
   if(l < 3)
   {
      GetSystemTime(&tm);
      sprintf_s(str, "   %02d.%02d %02d:%02d:%02d.%03d", tm.wDay, tm.wMonth, tm.wHour, tm.wMinute, tm.wSecond, tm.wMilliseconds);
      *this << str;
   }

   *this << std::endl;
   return;
}

void CLog::SetLevel(int l)
{
   limit_level = l;
}

 CLog logfile(0);