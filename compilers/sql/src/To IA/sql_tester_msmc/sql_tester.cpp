// sql_tester.cpp : Defines the entry point for the console application.
//

#include "stdafx.h"
#include <iostream>
#include <string>
#include <fstream>
#include <windows.h>

#define OTL_ORA9I // Compile OTL 4.0/OCI9i
#include <otlv4.h> // include the OTL 4.0 header file

using namespace std;
#include "readConfig.cpp"

//#define my_debug

otl_connect db; // connect object

//��������� ������ ���������� � �������
const char * connect_string(
							char * conn_str,
							const char * password_file,
							const char * scheme,
							const char * action);

/*
 * ������ ������� ������ ��������� *.exe < input.txt test_sql.txt
 * , ��� input.txt, test_sql.txt  ����� ������
 */	
int main(int argc, char* argv[])
{
	char query[1024] = {0};
	char test_answer[8192] = {0};
	char right_answer[8192] = {0};
	char answer[128] = {0};
	char * b; //������ ��� ������
	char ch;  //������ ��� ������

	CReadTask input; //������ ������� ������ � ���������� ������
	//������ ���������������� ������ 
	ifstream sql(argv[1], ios::binary );
	if (!sql) { cout << "Error: cannot open input file."; return 1;}
	for (b = query; sql.get(ch); ) {
		*b++ = ch;
	};
	*b = 0;
	trim(query);
	sql.close();
	//������ � �������
	otl_connect::otl_initialize(); // initialize OCI environment
	try{
		char str[128];
		db.rlogon( // connect to Oracle
			connect_string(
				str,
				//"password.txt",
				getenv("SQLPASSFILE"), //������� �� ���������� ���������
				input.getParam("scheme"),
				input.getParam("action")
				)
			);
		//����� ��������
		int num_action;
		strcpy(str,input.getParam("action"));
		for (b = str; *b != 0; b++)
			*b = tolower(*b);
		//tolower(str);
		if (strcmp(str,"select") == 0)
			num_action = 1;
		else if (strcmp(str,"dml") == 0)
			num_action = 2;
switch (num_action) {
case 1:{
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
	s << query;
	s << input.getParam("sql");
	s << (input.getParam("order")?atoi(input.getParam("order")):0);
	s >> test_answer;
	s >> right_answer;
	s >> answer;
	};break;
case 2: {
	char cod_PL_SQL[256] = {0};
	strcpy(cod_PL_SQL,"begin ");
	strcat(cod_PL_SQL,input.getParam("scheme"));
	strcat(cod_PL_SQL,"_creator.cmp_dml("	
		"   :sql1<char[1024],in>,   :sql2<char[1024],in>,   "
		"   :sql3<char[1024],out>,  :sql4<char[1024],out>,  "
		"   :sql5<char[1024],out>,                          "
		"   :sql6<char[32],in>,     :sql7<char[512],in>);   "
		"end;");
	otl_stream s(
		1, // buffer size needs to be set to 1 in this case
		cod_PL_SQL,
        db // connect object
        );
	s << query;                              //������ ������������
	s << input.getParam("sql");              //���������� ������
	s << input.getParam("table_name");       //��� �������
	s << input.getParam("compate_fields");   //����������� ����
	s >> test_answer;
	s >> right_answer;
	s >> answer;
	};break;
}
//---------------
#ifdef my_debug
		cout << "Right query: " << input.getParam("sql") << endl; 
		cout << "User  query: " << query << endl;
		cout << "Right out: "	<< right_answer << endl;
		cout << "User out: "	<< test_answer << endl;
		cout << "Answer procedure 'cmp_selection': " << answer <<endl;

#endif
	char * __GUID__ = "it's guid string -------------------->>>>>>>>>>>>>>>>>>>>>>>>>\n";
	//����� �������
	cout << answer << endl;
	cout << __GUID__;
	//���������� ����������� �������
	cout << "����� �������:" << endl; 
	if (input.getParam("prompt") && input.getParam("prompt")[0] != '0') { // ���� "��������� ���������"
		cout << right_answer;
	} else {
		cout << "� ���� ����� ��������� ���������.";
	};
	cout << endl;
	cout << __GUID__;
	//������ ������������
	cout << "���� SQL ����������: " << query << endl;
	cout << test_answer;
	} //try

	catch(otl_exception& p){	// intercept OTL exceptions
	cout<<p.msg<<endl;			// print out error message
	cout<<p.stm_text<<endl;		// print out SQL that caused the error
	cout<<p.sqlstate<<endl;		// print out SQLSTATE message
	cout<<p.var_info<<endl;		// print out the variable that caused the error
	}

	db.logoff(); // disconnect from Oracle*/
	return 0;
};

//��������� ������ ���������� � �������
const char * connect_string(char * conn_str, const char * password_file,const char * scheme,const char * action)
{
	char * sch = (char*)scheme;
	char * act = (char*)action;
	char * b = conn_str;
	//��������� "�� ��������" ����� ������������.
	//�������: scheme_action
	for (; *sch; *b++ = *sch++); //����������� scheme � conn_str[]
	*b++ = '_';
	for (; *act; *b++ = *act++); //����������� action � conn_str[]
	*b = 0;
	CReadTask pass(password_file);
	char ret[64] = {0};
	char * d = ret;
	strcpy(d,pass.getParam(conn_str));
	*b++ = '/';
	for (; *d; *b++ = *d++);
	if (pass.getParam("service")) {
		*b++ = '@';
		strcpy(ret,pass.getParam("service"));
		d = ret;
		for (; *d; *b++ = *d++);
	}
	*b = 0;
	//�������� ������ ����� PR = buses0_select/buses0_select@data
	return conn_str;
}
