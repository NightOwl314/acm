#include <fstream.h>
#include <math.h>

const double EPS=0.01005;

int main(int, char *argv[])
{
   ifstream f1(argv[2]),f2(argv[3]);
   double x1,x2;

   while (!f2.eof()) {
      f1 >> x1;
      f2 >> x2;
      if (fabs(x1-x2)>EPS) return 1;
   }
   return 0;
}