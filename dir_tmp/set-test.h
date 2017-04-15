#include <iostream>

using namespace std;

void test1(void)
{
  Set<int> a;
  for (int i=50; i>=0; i--) a+=i;
  for (int i=0; i<=50; i+=2) a-=i;
  for (int i=0; i<=50; i+=3) a-=i;
  cout << a << endl;
  Set<int> b = ((a + 999)+9999) - 89;
  cout << b.size() << endl;
  cout << b.exists(1) << b.exists(2)
    << b.exists(3) << b.exists(4)
    << b.exists(5) << endl;
  Set<int> *c = new Set<int>;
  *c +=1; *c +=5; *c +=6;
  cout << c->size() << endl;
  cout << c->size() << endl;
  cout << a-*c << endl;
  *c += 1111;
  cout << a+*c << endl;
  delete c;
}

//правильность основных операций на случайных данных
void test2(void)
{
  Set<unsigned char> a;
  cout << "ѕровер€ем вставку элементов и exists()" << endl;
  for(int i=0; i<100; i++) if ((i % 12)<4) a+=i;
  for(unsigned char c=0; c!=0xff; c++)
    if (a.exists(c)) cout << "1"; else cout << "0";
  cout << endl;

  Set<unsigned char> b;
  cout << "ѕровер€ем вставку элементов и exists()" << endl;
  for(int i=0; i<100; i++) if ((i % 9)<3) b+=i;
  for(unsigned char c=0; c!=0xff; c++)
    if (b.exists(c)) cout << "1"; else cout << "0";
  cout << endl;

  Set<unsigned char> d(a+b);
  cout << "ѕровер€ем объединение и конструктор копий" << endl;
  for(unsigned char c=0; c!=0xff; c++)
    if (d.exists(c)) cout << "1"; else cout << "0";
  cout << endl;

  cout << "ѕровер€ем разность и присваивание" << endl;
//  for(unsigned char c=0; c!=0xff; c++)
//    if (b.exists(c))
//      d -= c;

  d = a-b;
  for(unsigned char c=0; c!=0xff; c++)
    if (d.exists(c)) cout << "1"; else cout << "0";
  cout << endl;

}

//вставка и удаление элементов
void test3(void)
{
  Set<int> *a = new Set<int>;
  (*a)+=1; (*a)+=2;
  (*a)-=2; (*a)-=1; (*a)-=1; (*a)+=4;
  (*a)+=1; (*a)+=2;
  (*a)-=2;
  delete a;
  cout << "ok" << endl;
}

//проверка на эффективность работы с пам€тью
void test4(void)
{
  Set<int> a;
  for(int k=0;k<500;k++)
  {
    for(int i=0; i<1000; i++) a+=i;
    for(int i=0; i<1000; i++) a-=i;
  }
  cout << "ok" << endl;
}

//проверка деструктора на утечки пам€ти
void test5(void)
{
  Set<int> *a;  
  for(int k=0;k<1000;k++)
  {
    a = new Set<int>;
    for(int i=0; i<1000; i++) (*a)+=i;
    delete a;
  }
 cout << "ok" << endl;
}

//проверка корректности использовани€ произвольных типов в качестве элементов
int num;
struct Test
{
  int n;
  int *a;
  Test(){n=num++; a = new int[25000];}
  Test(const Test &t){n=t.n; a = new int[25000]; memcpy(a,t.a,25000);}
  ~Test(){delete[] a; }
  bool operator < (const Test &r) const {return n<r.n;}
  bool operator == (const Test &r) const {return n==r.n;}
  Test& operator = (const Test &r) {
    if (this==&r) return *this; 
    delete [] a;
    n=r.n; a = new int[25000]; memcpy(a,r.a,25000);
    return *this;
  }
};
void test6(void)
{
  Set<Test> *a;
  for(int k=0;k<50;k++)
  {
    a = new Set<Test>;
    (*a) += Test();
    (*a) += Test();
    delete a;
  }
  cout << "ok" << endl;
}

//присваивание
void test7(void)
{
  //корректность операции присваивани€
  Set<int> a,b;
  for(int i=0; i<20000; i++) a+=i;
  for(int k=0;k<50;k++)
  {
    b=a;
  }
  b=b;
  for(int i=0; i<20000; i++) if(b.exists(i)) cout << "1"; else cout << "0";
  cout << endl;
}

void test8(void)
{
 //частный случай - данные упор€дочены изначально
 Set<int> a;
 for(int i=0; i<30000; i++) a+=i;
 for(int i=0; i<29999; i++) a-=i;
 if (a.exists(29998)) cout <<"1"; else cout << "0";
 if (a.exists(29999)) cout <<"1"; else cout << "0";
}

void test9(void)
{
}

void test10(void)
{
}

int main(void)
{
  #ifdef __STD_SET__
    cout << "»спользование STL не допускаетс€ | Using of STL is forbidden";
    return 2;
  #endif

  #ifdef _STLP_SET
    cout << "»спользование STL не допускаетс€ | Using of STL is forbidden";
    return 2;
  #endif

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
