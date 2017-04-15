//---------------------------------------------------------------------------
#include<iostream.h>
#include <fstream.h>
#include <vcl.h>
#pragma hdrstop

//---------------------------------------------------------------------------

#pragma argsused

//--------------------------------------------------------------------------
struct faculltys
   {
   char FACILITY[5];
   int    ENTRIES;
   float  UTIL;
   float  AVE_TIME;
   int AVAILABLE;
   int OWNER;
   int PEND;
   int INTER;
   int RETRY;
   int DELAY;
   short int state;
   };

struct faculltys_chek
   {
   char FACILITY[5];
   int    ENTRIES;
   float  UTIL_min;
   float  UTIL_max;
   };


//------------------------------------------------------------------
int main(int argc, char* argv[])
{

ifstream in("1.in");  // Поток in будем использовать для чтения
//ifstream in(argv[1]),exx(argv[2]);
ifstream exx("1.out");
//ofstream out; // Поток out будем использовать для записи
   int a[6];
   int fk1;
   int fk2;
   char buff[100];

   char s1[]="START_TIME";
   char s2[]="FACILITY";



 faculltys *a1;     //  1  данные пользователя
 faculltys_chek *a2;       // 2 эталон


   while (! in.eof())
   {
      bool f1;
    //  int k1=0;

      in.getline(buff,80);//  getline(buff,83);
      if (strstr(buff,s1)!=NULL)
      {
       for (int k=0; k<6; k++)  {
         in>>a[k];
         if (k==3) fk1=a[k];
         //cout<<a[k]<<'\n';
                                 }
      }

      if (strstr(buff,s2)!=NULL)
      {
         a1=new faculltys[fk1];  //выделяем память под устройства
         for (int i=0; i<fk1; i++)
         {
         in>>a1[i].FACILITY;
         in>>a1[i].ENTRIES;
         in>>a1[i].UTIL;
         in>>a1[i].AVE_TIME;
         in>>a1[i].AVAILABLE;
         in>>a1[i].OWNER;
         in>>a1[i].PEND;
         in>>a1[i].INTER;
         in>>a1[i].RETRY;
         in>>a1[i].DELAY;
         }

}  // конец if

}
in.close();

 // конец while

 exx>>fk2;
 a2=new faculltys_chek[fk2];  //выделяем память под устройства
 int c=0;
 while(!exx.eof())     //      (c<fk2)
 {
  exx>>a2[c].FACILITY;
  exx>>a2[c].UTIL_min;
  exx>>a2[c].UTIL_max;
 c++;
 }

exx.close();


if(fk1!=fk2) return 1;     // проверяем кол-во устройств
 bool i1;
 for (int i=0; i<fk2; i++)
 {
  for (int j=0; j<fk2; j++)
    if ((strcmp (a2[i].FACILITY,a1[j].FACILITY )==0 )&& (a1[j].state!=1)&& (a1[j].state!=2))
           {
              a1[j].state=1;
              if ((((a2[i].UTIL_min)/100) <= a1[j].UTIL) && (((a2[i].UTIL_max)/100) >= a1[j].UTIL )) //проверяем названия устройств
              a1[j].state=2;
              break;
            }
 }

for (int i=0; i<fk1; i++)
   {
    if (a1[i].state!=2)
    cout<<a1[i].FACILITY<<"     "<<a1[i].ENTRIES<<"     "<<a1[i].UTIL<<"     "<<a1[i].AVE_TIME<<"     "<<a1[i].AVAILABLE<<"     "<<a1[i].OWNER<<"     "<<a1[i].PEND<<"     "<<
    a1[i].INTER<<"     "<<a1[i].RETRY<<"     "<<a1[i].DELAY<<"     "<<a1[i].state<<'\n';'\n';
    continue;
   }
for (int i=0; i<fk1; i++)
 if (a1[i].state!=2)
       return 1;

//проверка второй задачи
int summa=0;

for (int i=0; i<fk1; i++)
{
if (strstr(a1[i].FACILITY,"PC1")) summa=summa+a1[i].ENTRIES;
if (strstr(a1[i].FACILITY,"PC2")) summa=summa+a1[i].ENTRIES;
if (strstr(a1[i].FACILITY,"PC3")) summa=summa+a1[i].ENTRIES;
if (strstr(a1[i].FACILITY,"PC4")) summa=summa+a1[i].ENTRIES;
}
summa=summa/2;
bool b_summa;
for (int i=0; i<fk1; i++)
{
if ((strstr(a1[i].FACILITY,"FS") && (a1[i].ENTRIES>summa-4 || a1[i].ENTRIES>summa+4 )))
 b_summa=true;
}
 if (b_summa!=true)
 cout<<"no";  //return 1 ;
 else cout<<"Yes";
 return 0;
}

//---------------------------------------------------------------------------
