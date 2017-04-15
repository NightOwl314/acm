#include <cstdio>

int main(int argc, char* argv[]) {
  freopen(argv[1], "rt", stdin);
  freopen(argv[2], "wt", stdout);
  char prev = 0;
  for(;;) {
    int c = getchar();
    if (c == EOF) break;
    if (c >= 'A' && c <= 'Z') {
      c += -'A' + 'a';
    }
    if (c <= ' ') {
      c = ' ';
    }
    if (c == ' ' && prev == ' ') {
      // nothing
    } else {
      putchar(c);
    }
    prev = c;
  }
  return 0;
}
