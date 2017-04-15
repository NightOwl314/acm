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

//ifstream in("2.in");  // ����� in ����� ������������ ��� ������
ifstream in(argv[1]),exx(argv[2]);
char *e_u=(argv[3]);
//char *e_u="e";
//ifstream exx("2.out");

   int a[6];
   int fk1;
   int fk2;
   char buff[100];

   char s1[]="START_TIME";
   char s2[]="FACILITY";



 faculltys *a1;     //  1  ������ ������������
 faculltys_chek *a2;       // 2 ������


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
         a1=new faculltys[fk1];  //�������� ������ ��� ����������
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

}  // ����� if

}
in.close();

 // ����� while


//ifstream exx("1.out");
// ifstream exx(argv[3]);
 exx>>fk2;
 a2=new faculltys_chek[fk2];  //�������� ������ ��� ����������
 int c=0;
 while(!exx.eof())     //      (c<fk2)
 {
  exx>>a2[c].FACILITY;
  exx>>a2[c].UTIL_min;
  exx>>a2[c].UTIL_max;
 c++;
 }

exx.close();

/*
for (int q=0; q<fk1; q++)
   {
    cout<<a1[q].FACILITY<<"     "<<a1[q].ENTRIES<<"     "<<a1[q].UTIL<<"     "<<a1[q].AVE_TIME<<"     "<<a1[q].AVAILABLE<<"     "<<a1[q].OWNER<<"     "<<a1[q].PEND<<"     "<<
    a1[q].INTER<<"     "<<a1[q].RETRY<<"     "<<a1[q].DELAY<<"     "<<a1[q].state<<'\n';'\n';
   }

  for (int i=0; i<fk2; i++)
   {
    cout<<a2[i].FACILITY<<"     "<<a2[i].UTIL_min <<"   "<<a2[i].UTIL_max <<'\n';
   }
*/

if(fk1!=fk2) return 1;     // ��������� ���-�� ���������
 bool i1;

if ((strcmp(e_u,"u")==0)||(strcmp(e_u,"U")==0))
  {
 for (int i=0; i<fk2; i++)
 {
  for (int j=0; j<fk2; j++)
    if ((strcmp (a2[i].FACILITY,a1[j].FACILITY )==0 )&& (a1[j].state!=1)&& (a1[j].state!=2))
           {
              a1[j].state=1;
              if ((((a2[i].UTIL_min)/100) <= a1[j].UTIL) && (((a2[i].UTIL_max)/100) >= a1[j].UTIL )) //��������� �������� ���������
              a1[j].state=2;
              break;
            }
 }
}//end if e_u


if ((strcmp(e_u,"e")==0)||(strcmp(e_u,"E")==0))
  {
 for (int i=0; i<fk2; i++)
 {
  for (int j=0; j<fk2; j++)
    if ((strcmp (a2[i].FACILITY,a1[j].FACILITY )==0 )&& (a1[j].state!=1)&& (a1[j].state!=2))
           {
              a1[j].state=1;
              if ((a2[i].UTIL_min <= a1[j].ENTRIES) && (a2[i].UTIL_max >= a1[j].ENTRIES)) //��������� �������� ���������
              a1[j].state=2;
              break;
            }
 }
}//end if e_u


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

 return 0;
}

//---------------------------------------------------------------------------
