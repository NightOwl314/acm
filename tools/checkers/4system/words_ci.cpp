//comapring by words, case-insensitive (only for English!)

#include <locale>
#include <fstream>
#include <iostream>
#include <string>
#include <cstdlib>

using namespace std;

static locale loc;

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

void makeUpper(string &s) {
  for(int i = 0; i < s.size(); i++) {
    s[i] = toupper(s[i],loc);
  }
}


int main(int argc, char *argv[])
{
   ifstream f1(argv[2]),f2(argv[3]);
   string x1,x2;

   while (f2 >> x2) {
      if (!(f1 >> x1)) {
        wa("a lexem was expected", "ожидалась лексема");
      }      
      makeUpper(x1);
      makeUpper(x2);
      if (x1 != x2) {
        wa("the lexems are different", "лексемы не совпадают");
      }
   }

   string s;
   if (f1 >> s) {
     pe("extra data in output", "лишние данные в выводе");
   }

   cout << "Accepted\n";
   return 0;
}