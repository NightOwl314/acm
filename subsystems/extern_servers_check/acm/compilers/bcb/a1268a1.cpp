//---------------------------------------------------------------------------
//#include <vcl.h>

//#pragma hdrstop

#include <iostream.h>
#include <stdlib.h>
#include <windows.h>

//#include "matemat.h"
//---------------------------------------------------------------------------

#pragma argsused


//   int prs[10000];
    unsigned int /*bf[10000],k1,*/kk,xx;
/*   int k;
   int i,cnt,j,hh;
   int n,y,x,ofs;
  */

/*
lint stpm(lint x, lint n, lint m)
{
   lint a0,ai;
   bool nc;

   ai=w1;
   a0=x;
   while (true) {
      nc=(n.mod2()==w1);
      n=n.div2();
      if (nc) {
         ai=(ai*a0)%m;
         if (n==w0) break;
      }
      a0=(a0*a0)%m;
   }

   return ai;
}
*/
unsigned int stpm(unsigned int a, unsigned int b, unsigned int m);

int main(int argc, char* argv[])
{  /*
   ofstream output("1268_log1.out");

   prs[0]=2;
   cnt=0;
   for (i=3;i<=65536;i++) {
      k=0;
      for (j=0;j<=cnt;j++)
         if (i % prs[j] ==0) {
            k=1;
            break;
         }
      if (k==0) {
         cnt++;
         prs[cnt]=i;
      }
   }

   for (i=1;i<=cnt;i++) {
      y=0;
      for (j=prs[i]-1;j>=2;j--) {
         x=1;
//         k1=j;
         do {
//            bf[x]=k1;
            x++;
            k1=stpm(j,x,prs[i]);
            if (k1==j) break;
            if (x>prs[i]) break;
//            hh=1;
//            while ((hh<=x-1)&&(k1!=bf[hh])) hh++;
         } while (true);

         if (x==prs[i]) {
            break;
         }
      }
      output << prs[i] << "  " << j << "\n";
      cout << prs[i] << "\n\n";

   }
*/

/*
   ifstream input("1268_log1.out");
   ofstream outpas("1268_gn.pas");
   outpas << "var n,i,m,p:longint;\n";
   outpas << "begin\n";
   outpas << "read(n);\n";
   outpas << "for i:=1 to n do begin\n";
   outpas << "read(m);\n";
   outpas << "case m of\n";

   x=0;
   while (!input.eof()) {
      x++;
      if ((x%300)==0) {
          outpas << "end;\n";
          outpas << "case m of\n";
      }
      input >> xx >> k1;
      outpas << xx << ":p:=" << k1 <<";\n";
   }

   outpas << "end;\n";
   outpas << "writeln(p);\n";
   outpas << "end;\n";
   outpas << "end.\n";
  */
   cin >> xx >> kk;
   cout << xx+kk;
   kk=0;

   int i,n=1000,memsz=0,j;
   char **mas;

   mas=new char*[n];
   for (i=0;i<n;i++) {
      mas[i]=new char[100+i];
      memsz+=100+i;
   }

   for (j=0;j<10000;j++)
   for (i=0;i<n;i++)
      mas[i][0]=(char)random(100);

   for (i=0;i<n;i++)
      delete[] mas[i];
   delete[] mas;
//   stpm(1,1,1);
   return 0;
}
//---------------------------------------------------------------------------
