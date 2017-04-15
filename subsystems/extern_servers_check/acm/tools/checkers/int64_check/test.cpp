
#include <fstream.h>

int main(int argc, char *argv[])
{
   ifstream f1(argv[2]),f2(argv[3]);
   __int64 x1,x2;

   while (!f2.eof()) {
      f1 >> x1;
      f2 >> x2;
      if (x1!=x2) return 1;
   }
   return 0;
}