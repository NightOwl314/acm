// default_test.cpp : Defines the entry point for the console application.
//

#include "stdafx.h"
#include <iostream>
#include <fstream>
#include "string.h"
using namespace std;

#include "readConfig.cpp"

void check(char *str_src, char *str_find, char *str_new);

//������ ������� *.exe %1 %2 %3
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
  cout << "        ��� ���" << endl;
  cout << "+--------------------+" << endl;
  cout << start << endl;
  cout << "+--------------------+" << endl;


return 0;
/*	
if (argc >= 3) {
	//��� ����� ���������� ���� %1, ��� ��� ��� � ������� ���� ���������� ���������� �����
	fstream out;
	out.open(argv[1], ios::out);
	out << "Input...";
	out.close(); // ������ �� �����������... 

	//���������� ������ ����, ��� ������ ��������� sql_tester;
	char str[1024];
	char answer[1024];
	out.open(argv[2], ios::in);
	//� ������ ������ � ��� ����� ���������
	out.getline(answer,1024);

	out.getline(str,1024); //������ ���� "����� ������"

	//����� ������� ��������� ����������� �������
	//��� ���� ��������� � %3
	fstream out3(argv[3],ios::out);
	char * __GUID__ = "it's guid string -------------------->>>>>>>>>>>>>>>>>>>>>>>>>";
	while (out.getline(str,1024) && strcmp(str,__GUID__))
		out3 << str << endl;

	//����� ������� ���������� ����������������� �������
	char _tmp_[8192] = {0};
	while ( out.getline(str,1024) ) {
		strcat(_tmp_,str);
		strcat(_tmp_,"\n");
	};
	out.close();
	out.open(argv[2],ios::out);
	//������� ���� argv[2] � ������� ���� ��� ������
	out.clear();
	out << _tmp_;
	out.close();
	//������� ��� ����� ����������� ���������
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
