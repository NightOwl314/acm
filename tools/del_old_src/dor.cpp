#include <iostream>
#include <cstring>

using namespace std;

int main() {
  int x;
  char s[100];
  while (cin >> x) {
    sprintf(s,"del /Q c:\\acm\\dir_src\\%05x.otch",x);
    system(s);
  }
  return 0;
}