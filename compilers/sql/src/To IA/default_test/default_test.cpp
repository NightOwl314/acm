// default_test.cpp : Defines the entry point for the console application.
//

#include "stdafx.h"
#include <iostream>
#include <fstream>
using namespace std;

//������ ������� *.exe %1 %2 %3
int main(int argc, char* argv[])
{
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
}
