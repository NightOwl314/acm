#include <windows.h>
#include <string.h>
#include <stdio.h>

char s[256];

STARTUPINFO si;
PROCESS_INFORMATION pi;

int main(int, char* argv[]) {
  char *c = argv[0] + strlen(argv[0]) - 1;
  while (*c!='.') c--; *c=0;
  while (*c!='\\') c--; c++;
//  sprintf(s,"c:\\programs\\java\\bin\\java.exe -Djava.security.manager p_%s",c);
  sprintf(s,"c:\\programs\\java\\bin\\java.exe p_%s",c);

  si.cb = sizeof(si);
//  CreateProcess(NULL,"c:\\programs\\java\\bin\\java.exe -Djava.security.manager jrun",NULL,NULL,true,0,NULL,NULL,&si,&pi);
  CreateProcess(NULL,s,NULL,NULL,true,0,NULL,NULL,&si,&pi);

 WaitForSingleObject(pi.hProcess, INFINITE);
 DWORD code;
 GetExitCodeProcess(pi.hProcess,&code);

 return code;

}