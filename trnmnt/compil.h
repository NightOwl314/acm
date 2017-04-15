#ifndef compil_h_
#define compil_h_

#include "trnmnt.h"

class CCompiler
{
public:
   CCompiler();
   ~CCompiler();

   INTEGER  id;

   char FileIn[MAX_STR_LEN];
   char FileOut[MAX_STR_LEN];
   char FileObj[MAX_STR_LEN];
   char WhiteListFile[MAX_STR_LEN];
   char CompilScript[MAX_STR_LEN];
   char CompilParam[MAX_STR_LEN];
   char RunCmd[MAX_STR_LEN];
   int  AdjMemory;
   int  AdjTime;
   int  ProtectMode;
};

typedef vector<CCompiler*> VCCompilers;

extern VCCompilers Compilers;

int ReadCompilers(char *filename);

#endif