//---------------------------------------------------------------------------
#include<iostream.h>
#include <fstream.h>
#include<stdlib.h>
#include<string.h>
#include <vcl.h>
#pragma hdrstop

//---------------------------------------------------------------------------

#pragma argsused
struct ss
{
char str[30];
};
const int k=3; //число generate в программе

int main(int argc, char* argv[])

{
char s1[]="     generate 30,8,,10";
char s2[]="     generate 600";
char s3[]="     generate 500";
ss ms[k];
int state1, state=0;

ifstream in(argv[1]);  // ѕоток in будем использовать дл€ чтени€
ofstream out(argv[2]); // ѕоток out будем использовать дл€ записи
state1=atoi(argv[3]); //третий параметр указывает какой посчету перезаписывать generate 1 или 2

 if (state1==0)
{
 strcpy(ms[0].str,s1);
 strcpy(ms[1].str,s2);
 strcpy(ms[2].str,s3);
}
 if (state1==1)
{
 strcpy(ms[0].str,s2);
 strcpy(ms[1].str,s1);
 strcpy(ms[2].str,s3);
}
//ifstream in("model.mdl");  // ѕоток in будем использовать дл€ чтени€
//ofstream out("model2.mdl"); // ѕоток out будем использовать дл€ записи

char serch[]="generate";

char buff[40];

while (! in.eof())
{
   in.getline(buff ,30);//  getline(buff,83);
      if ((strstr(buff,serch)!=NULL) && (state<k))
          {
            strncpy(ms[state].str,buff,3);
            strcpy(buff,ms[state].str);
            state++;
          }
out<<buff;
out<<"\n";
}
in.close();
out.close();
return 0;
}
//---------------------------------------------------------------------------
