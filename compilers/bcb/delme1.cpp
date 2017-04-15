//---------------------------------------------------------------------------

#pragma hdrstop
#include <iostream>
#include <string.h>
#include "Strutils.hpp"
using namespace std;
#include <stdio.h>
//---------------------------------------------------------------------------

#pragma argsused
int main(void)
{
       AnsiString stacker[100];
       int i,g,len;
       AnsiString mark;
       char ch[25];
       i=0;
       bool ender=false;

       while (cin.getline(ch,25))
                {
                stacker[i]=ch;
                if (stacker[i]=="\\0")
                        {
                        ender=true;
                        break;
                        }
       i++;
       mark=stacker[i-1];
                mark.Delete(1,mark.Length()-1);
                len=stacker[i-1].Length();
                if (stacker[i]=="")
                stacker[i-1].Delete(len-1,2);
                else
                stacker[i-1].Delete(len-2,4);

       for(g=0;g<i;g++)
                {
                
                if (mark=='-')
                        for(len=0;len<i;len++)
                                {
                                if (stacker[len]==stacker[i-1]) stacker[len]='\0';
                                }
                if (mark=='+')
                        for(len=0;len<i;len++)
                                {
                                if (len==(i-1)) continue;
                                if (stacker[len]==stacker[i-1]) stacker[g]='\0';
                                }
                }

      for(len = 0; len < i; len ++)
                {
                        for(g = 0; g < i; g ++)
                                {
                                if ((stacker[g]!='\0') && (stacker[len]!='\0'))
                                if(StrToInt(stacker[g]) > StrToInt(stacker[len]))
                                        {
                                         mark = stacker[len];
                                        stacker[len] = stacker[g];
                                        stacker[g] = mark;
                                        }
                                }
                }

       }

       if (ender==true)
                {
                len=0;
                for(g=0;g<i;g++)
                {
                if (stacker[g]!='\0') len++;
                }
                cout<<len<<endl;
                for(g=0;g<i;g++)
                        {
                        cout<<stacker[g]+' ';
                        }
                }

       return 0;
}
//---------------------------------------------------------------------------
