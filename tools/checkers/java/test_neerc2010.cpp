#include <cstdlib>
#include <cstdio>

using namespace std;

int main(int, char* argv[]) {
  char curdir[256];
  sprintf(curdir,argv[0]);
  char *p;
  for (p=curdir; *p!=0; p++);
  for (;*p!='\\' && *p!='/';p--);
  *p=0;
   
  char s[256];  
  sprintf(s,"java -Xss64m -Duser.language=en -Duser.region=US -classpath \"%s;%s\\..\\..\\tools\\checkers\\java\\testlib4j.jar\" Check %s %s %s",curdir,curdir,argv[1],argv[2],argv[3]);
  printf("%s\n",s);
  return system(s);
}
