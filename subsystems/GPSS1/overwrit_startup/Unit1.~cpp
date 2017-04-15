//---------------------------------------------------------------------------
#include <fstream.h>
#include <vcl.h>
#pragma hdrstop

//---------------------------------------------------------------------------

#pragma argsused
int main(int argc, char* argv[])
{
/*
открываем файл startup дл€ записи, и измен€ем первую строчку
*/

ofstream out("startup.gps"); // ѕоток out будем использовать дл€ записи
//char s1[]="@MODEL.MDL";
char *s1=argv[1];
char s2[]="continue";
char s3[]="end";
out<<s1;
out<<"\n";
out<<s2;
out<<"\n";
out<<s3;
out<<"\n";
out.close();
return 0;
}
//---------------------------------------------------------------------------
