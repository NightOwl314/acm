// readConfig.cpp : Defines the entry point for the console application.
//
#include <iostream>
#include <stdlib.h>
#include <map>
#include <string>
#include <fstream>

char * trim(char * source)
{
if (source) {
  //обрезаем с конца
  char * _=source+strlen(source)-1;
  for( ; _!=source && *_<=' '; *_--=0 );
  //обрезаем с начала
  _ = source;
  for( ; *_ && *_<=' '; *_++);
  return _;
  }
return source;
};

class CReadTask
{
public:
	CReadTask();
	CReadTask(const char* filename);
	const char * getParam(const char * key);
private:
	map<string, string> m_arr;
};

CReadTask::CReadTask()
{
	char Str[1024];
	char buf[32];
	char * Key, * Value, *str;
	bool line = true;
	while (cin.getline(Str,1024)) {
		str = trim(Str);
		if (*str != '#') { //не комментарий
			if (!line && *str != '$' && *str != '@') {
				m_arr[buf] += str;
				m_arr[buf] += '\n';
			} else {
				if (*str != '@' && *str != '$')
					continue; //какой-то косяк в файле.
				line = *str++ == '$';
				for (Value = str; *Value && *Value != '='; *Value++); //находим знак '='
				if (*Value) *Value++ = 0;	//разбиваем строку на key and value
				Key = trim(str);
				Value = trim(Value);
				//лишнее копирование, надо для запоминания, если многострочных параметр
				strcpy(buf,Key);
				m_arr[buf] = Value;
				}//else
			}//if (*str != '#')
	} //while
};

CReadTask::CReadTask(const char* filename)
{
	ifstream f;
	f.open(filename,ios::in);

	char Str[1024];
	char buf[32];
	char * Key, * Value, *str;
	bool line = true;
	while (f.getline(Str,1024)) {
		str = trim(Str);
		if (*str != '#') { //не комментарий
			if (!line && *str != '$' && *str != '@') {
				m_arr[buf] += str;
				m_arr[buf] += '\n';
			} else {
				if (*str != '@' && *str != '$')
					continue; //какой-то косяк в файле.
				line = *str++ == '$';
				for (Value = str; *Value && *Value != '='; *Value++); //находим знак '='
				if (*Value) *Value++ = 0;	//разбиваем строку на key and value
				Key = trim(str);
				Value = trim(Value);
				//лишнее копирование, надо для запоминания, если многострочных параметр
				strcpy(buf,Key);
				m_arr[buf] = Value;
				}//else
			}//if (*str != '#')
	} //while
	f.close();
};

const char * CReadTask::getParam(const char * key)
{
	if (m_arr.find((string(key))) != m_arr.end())
		return m_arr[key].c_str();
	return 0;
};
