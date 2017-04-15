//---------------------------------------------------------------------------

#pragma hdrstop
#include <fstream.h>
#include <iostream.h>
#include <strstream.h>
#include <time.h>
//---------------------------------------------------------------------------

#pragma argsused
int main(int argc, char* argv[])
{
   int n_case, params_cnt, digits_cnt, freq_get,total_params;
   double p_err,err_prm,ver=1,izb=10e100,izb_et;
   char *s= new char[100000];
   int i,ln,rez=0;
   unsigned int X,X1,*y;
   time_t tm1=time(NULL),tm0=0;

   ifstream in(argv[1]),tst(argv[2]);

   in >> n_case >> params_cnt >> digits_cnt >> freq_get >> p_err
      >> total_params >> err_prm >> izb_et;


   for (i=0;i<14;i++)
      tst.getline(s,100000);

   for (i=0;i<20;i++) s[i]=rand()%256;

   i=0;
   while (!tst.eof() && i<20) {
      y=(unsigned int*)(s+i);
      tst >> *y;
      i+=4;
   }

   X=0x2a1d04ea;
   for (i=0;i<20;i+=4) {
      y=(unsigned int*)(s+i);
      X1=*y;
      *y=*y^(X*1437524181+734342197);
      X=X1;
   }

   tm0=*((time_t*)s);
   ver=*((double*)(s+4));
   izb=*((double*)(s+12));

   if (tm1-tm0>60 || tm1-tm0<0) {
      cout << "time error " << endl;
      rez=2;
   }
   if (ver>err_prm || ver<0) {
      cout << "probability error" << endl;
      rez=1;
   }
   if (izb_et!=-1 && (izb>izb_et || izb<0)) {
      cout << "superfluity error" << endl;
      rez=1;
   }
   delete[] s;
   return rez;
}
//---------------------------------------------------------------------------
