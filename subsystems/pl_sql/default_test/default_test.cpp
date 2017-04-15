// default_test.cpp : Defines the entry point for the console application.
//

#include "stdafx.h"
#include <iostream>
#include <fstream>
#include "string.h"
using namespace std;

#include "readConfig.cpp"

void check(char *str_src, char *str_find, char *str_new);

//строка запуска *.exe %1 %2 %3
int main(int argc, char* argv[])
{ 
  char out_str[2048] = {0};
  char id[255] = {0};
//  CReadTask input;
//  strcpy(out_str,input.getParam("teacher"));
//  strcpy(id,input.getParam("id"));
//  check(out_str,id,"");
  strncpy(id,argv[0],strlen(argv[0])-4);
  //cout << id << endl << endl;

	fstream out; 
	char start[2048]={0};
	char str[1024]={0};
	out.open(id, ios::in);
	char * __GUID__ = "it's guid string --------------------";
	while (out.getline(str,1024) && strcmp(str,__GUID__))
	{
		strcat(start,str);
		strcat(start,"\n");
	}
	out.close();
	
  cout << id << endl << endl;
  cout << "         Out..." << endl << endl;
  cout << "+--------------------+" << endl;
  cout << "        ВАШ КОД" << endl;
  cout << "+--------------------+" << endl;
  cout << start << endl;
  cout << "+--------------------+" << endl;


return 0;
/*	
if (argc >= 3) {
	//нам нужно уничтожить файл %1, так как там в окрытом виде содержится правильный ответ
	fstream out;
	out.open(argv[1], ios::out);
	out << "Input...";
	out.close(); // больше не понадобится... 

	//производим разбор того, что вывела программа sql_tester;
	char str[1024];
	char answer[1024];
	out.open(argv[2], ios::in);
	//в первой строке у нас ответ программы
	out.getline(answer,1024);

	out.getline(str,1024); //должна быть "левая строка"

	//далее следует рузультат правильного запроса
	//его надо сохранить в %3
	fstream out3(argv[3],ios::out);
	char * __GUID__ = "it's guid string -------------------->>>>>>>>>>>>>>>>>>>>>>>>>";
	while (out.getline(str,1024) && strcmp(str,__GUID__))
		out3 << str << endl;

	//далее следует результаты пользовательского запроса
	char _tmp_[8192] = {0};
	while ( out.getline(str,1024) ) {
		strcat(_tmp_,str);
		strcat(_tmp_,"\n");
	};
	out.close();
	out.open(argv[2],ios::out);
	//очистим файл argv[2] и запишем туда эту строку
	out.clear();
	out << _tmp_;
	out.close();
	//выводим как ответ тестирующей программы
	cout << answer;
	return strcmp(answer,"OK")?1:0;
}
return 13;
*/
}

void check(char *str_src, char *str_find, char *str_new)
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
