// sql_tester.cpp : Defines the entry point for the console application.
//

#include "stdafx.h"
#include <iostream>
#include <fstream>
#include "string.h"
#include "windows.h"
//#include "process.h"

#define OTL_ORA9I // Compile OTL 4.0/OCI9i
#include "otlv4.h" // include the OTL 4.0 header file

using namespace std;

#include "readConfig.cpp"

//#define my_debug

otl_connect db; // connect object


void check_str(char *str_src, char *str_find, char *str_new);
char *check_tab(char *out_str, char *in_str, char *id_temp, char *scheme);


int main(int argc, char* argv[])
{
//**********************************************************

if (argc >= 3) {

	char admin_str[128]={0};
	char user_str[128]={0};
	char scheme[128]={0};
	char user_query[2048]={0};
	char teacher_query[2048]={0};
	char drop[256]={0};
	char id[64]={0};
	char start[2048]={0};
	char start_query[4096]={0};
	char tables[1024]={0};

    char tst[256];
	char psw[256];

	fstream out; 
	out.open(argv[2], ios::in);
	out.getline(psw,256);
	out.close();

	char str[1024]={0};
	out.open(psw, ios::in);
//****

	while ( out.getline(str,1024) ) {
		strcat(start_query,str);
		strcat(start_query,"\n");
	};
	out.close();
	fstream vhod;
	strcat(psw,".stt");
    vhod.open(psw, ios::in);
//****
	char str2[1024]={0};
	char * __GUID__ = "it's guid string --------------------";
	while (vhod.getline(str2,1024) && strcmp(str2,__GUID__))
	{
		strcat(start,str2);
		strcat(start,"\n");
	}
    vhod.getline(admin_str,128);
	vhod.getline(user_str,128);
	vhod.getline(scheme,128);
    vhod.getline(drop,256);
	vhod.close();
/*	
	out.open(psw, ios::out);
	out << start << endl;
	out.close();
*/
	CReadTask input(argv[1]);
	char id_temp[128]={0};
	strcpy(id_temp,input.getParam("id"));
	fstream f_temp;
	char temp[2048]={0};
	char temp2[2048]={0};
	f_temp.open(argv[3], ios::out);

	f_temp << start << endl;
	strcpy(temp,input.getParam("tables"));
	check_tab(temp2,temp,id_temp,scheme);
	f_temp << temp2 << endl;
    strcpy(temp,input.getParam("teacher"));
	f_temp << temp << endl;
	f_temp << start_query << endl;
	//***
    strcpy(temp,input.getParam("user_end"));
	f_temp << temp << endl;
	//***
	strcpy(temp,input.getParam("execsql"));
	f_temp << temp << endl;
	strcpy(temp,input.getParam("execsql"));
	check_str(temp,id_temp,"");
	f_temp << temp << endl;
	f_temp << "exit" << endl;
	f_temp.close();
	strcpy(teacher_query,input.getParam("query"));
    strcpy(user_query,teacher_query);
	check_str(user_query,id_temp,"");


	f_temp.open(argv[1],ios::out);
	f_temp << "+--------------------+" << endl;
	f_temp << "   ÇÀÏÐÎÑ ÍÀ ÂÀØ ÊÎÄ" << endl;
	f_temp << "+--------------------+" << endl << endl;
	f_temp << user_query << endl << endl;
	f_temp << "+--------------------+" << endl;
	f_temp.close();


    strcpy(temp,"sqlplus ");
	strcat(temp,admin_str);
    strcat(temp," @");
	strcat(temp,argv[3]);
	if (strstr(input.getParam("log"),"1")!=NULL) {strcat(temp," > 1.log");}

//*****************************

	fstream bat;
	bat.open("1.bat", ios::out);
	bat << "@echo off" << endl;
	bat << temp << endl;
	//bat << "DEL "<< "1.end" << endl;
	bat << "DEL "<< psw << endl;
	bat << "DEL "<< "1.bat" << endl;

	bat.close();

//*******************
  STARTUPINFO si;
  PROCESS_INFORMATION pi;

	if(CreateProcess(NULL, "1.bat", NULL, NULL,
        FALSE, 0, NULL, NULL, &si, &pi))
	{
		if(WaitForSingleObject(pi.hProcess, 
            INFINITE) != WAIT_FAILED)
		{}
		CloseHandle(pi.hProcess);
        CloseHandle(pi.hThread);
	}
//*****************

	char test_answer[8192] = {0};
	char right_answer[8192] = {0};
	char answer[128] = {0};

	otl_connect::otl_initialize(); // initialize OCI environment
	try{
		char str[128];
		db.rlogon(user_str // connect to Oracle
		      	);
		otl_stream s(
			1, // buffer size needs to be set to 1 in this case
		"begin "
		"  creator.cmp_selection( "
		"	:sql1<char[1024],in>,	:sql2<char[1024],in>,	"
		"	:sql3<char[8192],out>,	:sql4<char[8192],out>,	"
		"	:sql5<char[1024],out>,	:sql6<int,in>			"
		"	); "
        "end;",
        db // connect object
        );

	    s << user_query;
		s << teacher_query;
		s << 0;
		s >> test_answer;
		s >> right_answer;
		s >> answer;
}
  catch(otl_exception& p){ // intercept OTL exceptions
  cout<<p.msg<<endl; // print out error message
  cout<<p.stm_text<<endl; // print out SQL that caused the error
  cout<<p.var_info<<endl; // print out the variable that caused the error
 }
	db.logoff(); // disconnect from Oracle*/
		    

try{
	db.rlogon( // connect to Oracle
			admin_str);
	otl_cursor::direct_exec
       (
         db,
         drop//,
        ); // drop user
	}
  catch(otl_exception& p){ // intercept OTL exceptions
  cout<<p.msg<<endl; // print out error message
  cout<<p.stm_text<<endl; // print out SQL that caused the error
  cout<<p.var_info<<endl; // print out the variable that caused the error
 }
	db.logoff(); // disconnect from Oracle*/
	
	fstream out3(argv[3],ios::out);
	out3 << "+-----------------------+" << endl;
	out3 << "   ÍÀ ÏÐÀÂÈËÜÍÛÕ ÄÀÍÍÛÕ" << endl;
	out3 << "+-----------------------+" << endl;
	out3 << right_answer << endl;
	out3 << "+-----------------------+" << endl;
	out3 << "      ÍÀ ÂÀØÈÕ ÄÀÍÍÛÕ" << endl;
	out3 << "+-----------------------+" << endl;
	out3 << test_answer << endl;
    out3 << "+-----------------------+" << endl;
	out3.close();



	cout << answer;
//****************

//********************
	return strcmp(answer,"OK")?1:0;
}
return 13;
}

void check_str(char *str_src, char *str_find, char *str_new)
{
   int pos;
   string src,fnd(str_find),nw(str_new),bf;
   while(1) {
      src=string(str_src);
      pos=src.find(fnd);
      if (pos==-1) break;
      bf=src.substr(0,pos)+nw+src.substr(pos+fnd.length());
      strcpy(str_src,bf.c_str());
   }
}

char *check_tab(char *out_str, char *in_str, char *id_temp, char *scheme)
{
	char *s;
	s = strtok(in_str, ",");
	while(s)
	{
	//â s - î÷åðåäíîå íóæíîå
    strcat(out_str,"create table ");
	strcat(out_str,s);
	strcat(out_str," as select * from ");
	strcat(out_str,scheme);
	strcat(out_str,".");
	strcat(out_str,s);
	strcat(out_str,";");
	strcat(out_str,"\n");

	strcat(out_str,"create table ");
	strcat(out_str,s);
	strcat(out_str,id_temp);
	strcat(out_str," as select * from ");
	strcat(out_str,scheme);
	strcat(out_str,".");
	strcat(out_str,s);
	strcat(out_str,";");
	strcat(out_str,"\n");

	s = strtok(NULL, ",");
	}
	return out_str;
}