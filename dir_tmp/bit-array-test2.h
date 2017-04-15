#include <iostream>

using namespace std;

void test1(void)
{
  BitArray a(100);
  a[1]=a[17]=a[19]=1;
  cout << a << endl;
  BitArray b(3);
  cout << b << endl;
}

void test2(void)
{
  BitArray a(1000);
  for(int i=0; i<1000; i++) 
    if (i % 2 == 0 || i % 5 ==0)
      a[i]=1;
  cout << a << endl;
  for(int i=0; i<1000; i++) 
    if (i % 2 == 0 || i % 5 ==0)
      a[i]=0;
  cout << a << endl;
  for(int i=0; i<1000; i++) 
     a[i]=1;
  cout << a << endl;
  for(int i=0; i<1000; i++) 
    if (i % 7 == 0)
      a[i]=0;
  cout << a << endl;
}

void test3(void)
{
  BitArray a(1000);
  for(int i=0; i<1000; i++) 
    if (i % 2 == 0 || i % 5 ==0)
      a[i]=1;
  cout << a << endl;
  BitArray *c;
  {
    BitArray b(a);
    c  = new BitArray(a);
    a[1]=1-a[1]; a[2]=1-a[2]; a[3]=1-a[3];
    b[13]=1-b[13];
    (*c)[15]=1-(*c)[15];
    cout << a << endl << b << endl << *c << endl;
  }
  delete c;
  for (int i=0; i<1000; i++) cout << a[i];
  cout << endl;
}  

void test4(void)
{
 BitArray *b = new BitArray(6000000);
 for(int i=0; i<6000000; i++) 
   (*b)[i]=i%2;
 delete b;
 cout << "ok" << endl;
}

void test5(void)
{
  BitArray *b = new BitArray(6000000);
  delete b;
  for (int i=0; i<50; i++)
  {
    b = new BitArray(5500000);
    delete b;
  }
  cout << "ok" << endl;
}

void test6(void)
{
  BitArray a(1000);
  for(int i=0; i<1000; i++) 
    if (i % 2 == 0 || i % 5 ==0)
      a[i]=1;
  {
    BitArray b(100);
    for (int i=0; i<100; i++) b[i]=1;
    b = a;
    cout << b << endl;
    for (int i=0; i<1000; i++) b[i]=0;
  }
  cout << a << endl; 
}

void test7(void)
{
  BitArray b(3500000);
  BitArray c(3500000);
  for (int i=0; i<30; i++)
  {
    c = b; b = c;
  }
  cout << "ok" << endl;
}

void test8(void)
{
  BitArray a(1000);
  for(int i=0; i<1000; i++) 
    if (i % 2 == 0 || i % 5 ==0)
      a[i]=1;
  BitArray b = a;
  if (a==b) cout << "EQ"; else cout << "NEQ"; cout << endl;
  if (a!=b) cout << "EQ"; else cout << "NEQ"; cout << endl;
  BitArray c(100);
  for(int i=0; i<100; i++) c[i]=a[i];
  if (a==c) cout << "EQ"; else cout << "NEQ"; cout << endl;
  if (a!=c) cout << "EQ"; else cout << "NEQ"; cout << endl;
}

void test9(void)
{
  BitArray a(1000), b(1000);
  for(int i=0; i<1000; i++) 
    if (i % 2 == 0 || i % 5 ==0)
      a[i]=1; 
    else
      b[i]=1;
  BitArray c = a & b; 
  cout << c << endl << a << endl << b << endl;
  c = a | b; 
  cout << c << endl << a << endl << b << endl;
  c = ~a;
  cout << c << endl << a << endl;
  BitArray d(10);
  d[9]=1; d[6]=1;
  a = a & d;
  cout << a << endl << d << endl;
  b = b | d;
  cout << b << endl << d << endl;
  d = ~d;
  cout << d << endl;
}

void test10(void)
{
  BitArray a(100);
  a=a; a=a; a=a;
  cout << a << endl;
}

int main(void)
{
  char s[256];
  cin.getline(s,256); cin >> ws;
//  cout << s;
  
  int testnum;
  cin >> testnum;

  switch (testnum)
  {
    case 1: test1(); break;
    case 2: test2(); break;
    case 3: test3(); break;
    case 4: test4(); break;
    case 5: test5(); break;
    case 6: test6(); break;
    case 7: test7(); break;
    case 8: test8(); break;
    case 9: test9(); break;
    case 10: test10(); break;
  }
  return 0;
}
