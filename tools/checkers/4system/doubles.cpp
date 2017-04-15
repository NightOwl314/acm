#include <fstream>
#include <iostream>
#include <string>
#include <cstdlib>
#include <cmath>

using namespace std;

const double EPS=0.01005;

void pe(const char *en, const char *ru) {
  cout << "PE: " << en << endl;
  cout << "PE: " << ru << endl;
  exit(2);
}

void wa(const char *en, const char *ru) {
  cout << "WA: " << en << endl;
  cout << "WA: " << ru << endl;
  exit(1);
}


int main(int argc, char *argv[])
{
   ifstream f1(argv[2]),f2(argv[3]);
   double x1,x2;

   while (f2 >> x2) {
      if (!(f1 >> x1)) {
        wa("a number was expected", "ожидалось число");
      }      
      if (fabs(x1 - x2) > EPS) {
        wa("the numbers are different", "числа не совпадают");
      }
   }

   string s;
   if (f1 >> s) {
     pe("extra data in output", "лишние данные в выводе");
   }

   cout << "Accepted\n";
   return 0;
}