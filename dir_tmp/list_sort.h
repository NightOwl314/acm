#include <cstdlib>
#include <iostream>
#include <algorithm>

using namespace std;

#pragma pack(1)

struct Elem 
{
  int key;
  Elem *next;
};

Elem* listsort(Elem * list);

const NMAX = 100000;
int b[NMAX];
Elem a[NMAX];

int main() {
  //��������� ������� ��������� - ����� ��������� � �������� ��� srand
  int n, bc;
  cin >> n >> bc;
  srand (bc);
  for (int i=0; i<n; i++) {
    a[i].key = rand()*rand();
    b[i]=a[i].key;
    a[i].next = a+i+1;
  }
  a[n-1].next = NULL;

  sort(b,b+n); //���������� �����������
  Elem *res = listsort(a); //���������� ��������
  for (int i=0; i<n; i++,res=res->next)
    if (res->key!=b[i]) {cout << "-1"; return 0; } //�������� �����
  if (res!=NULL) {cout << "PE"; return 0;} //������ �� ����������� NULL
  //��� �������� ������� ������ � ��������� �����
  cout << b[0] << " " << b[n-1] << endl;
  return 0;
}

#define main main666
