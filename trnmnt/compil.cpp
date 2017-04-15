#include "compil.h"

VCCompilers Compilers;

CCompiler::CCompiler()
{
   return;
}

CCompiler::~CCompiler()
{
   return;
}

int ReadCompilers(char *filename)
{
   int stat = 0;

   int bfsz = 16384;
   char *buff = new char[bfsz], *x, s[20];
   CCompiler *compiler;

   ZeroMemory(buff, bfsz);
   //получим все секции файла конфигурации компиляторов
   GetPrivateProfileString(NULL, NULL, NULL, buff, bfsz, filename);

   x = buff;
   while(*x)
   {
      compiler = new CCompiler();

      GetPrivateProfileString(x,"id",NULL,s,20,filename);
      compiler->id=atoi(s);
      GetPrivateProfileString(x,"AdjMemory",NULL,s,20,filename);
      compiler->AdjMemory=atoi(s);
      GetPrivateProfileString(x,"AdjTime",NULL,s,20,filename);
      compiler->AdjTime=atoi(s);
      GetPrivateProfileString(x,"ProtectMode",NULL,s,20,filename);
      compiler->ProtectMode=atoi(s);

      GetPrivateProfileString(x,"FileIn",NULL,compiler->FileIn,MAX_STR_LEN,filename);
      GetPrivateProfileString(x,"FileOut",NULL,compiler->FileOut,MAX_STR_LEN,filename);
      GetPrivateProfileString(x,"FileObj",NULL,compiler->FileObj,MAX_STR_LEN,filename);
      GetPrivateProfileString(x,"WhiteListFile",NULL,compiler->WhiteListFile,MAX_STR_LEN,filename);
      //GetPrivateProfileString(x,"CompilCmd",NULL,compiler->CompilCmd,MAX_STR_LEN,filename);
      GetPrivateProfileString(x,"CompilScript",NULL,compiler->CompilScript,MAX_STR_LEN,filename);
      GetPrivateProfileString(x,"CompilParam",NULL,compiler->CompilParam,MAX_STR_LEN,filename);
      GetPrivateProfileString(x,"RunCmd",NULL,compiler->RunCmd,MAX_STR_LEN,filename);

      Compilers.push_back(compiler);
      x += strlen(x) + 1;
   }

   delete[] buff;

   return stat;
}