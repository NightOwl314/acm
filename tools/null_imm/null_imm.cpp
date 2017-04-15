#include<fstream.h>
#include<iostream.h>
#include "hde.h"

char buffer[1024*1024];

int main(int argc, char * argv[])
{
   cout << "Null imm32, disp32, rel32 v0.01" << endl;

   ifstream in(argv[1],ios::binary);
   ofstream out(argv[2],ios::binary);
   int offset=0,sz=0,clen=1,max_ln=0,min_ln=100,cmd_cnt=0,null_cnt=0;
   HDE_STRUCT hde_s;
   
   
   sz=in.readsome(buffer,1024*1024);
   cout << "Size: " << sz << endl;

   while (offset<sz) {
      clen=hde_disasm(buffer+offset, &hde_s);
      if (hde_s.imm32_ || hde_s.disp32 || hde_s.rel32) {
         memset(buffer+offset+clen-4,0,4);
         null_cnt++;
      }

      if (clen>max_ln) max_ln=clen;
      if (clen<min_ln) min_ln=clen;
      cmd_cnt++;
      
      offset+=clen;
   }
   
   out.write(buffer,sz);
   
   in.close();
   out.close();

   cout << "Commands: " << cmd_cnt << endl;
   if (cmd_cnt>0) {
      cout << "Max length: " << max_ln << ";  Min length: " << min_ln << ";  Avg length: " << 1.0*sz/cmd_cnt << endl;
      cout << "Nulls: " << null_cnt << endl;
   }


   return 0;
}