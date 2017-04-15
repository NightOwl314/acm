#define _WIN32_WINNT 0x0501

#include "windows.h"
#include "stdio.h"


int main(int argc, char* argv[])
{
	FILE* stream;int err = 0;

	DWORD priority = 1, time_sleep = 10, time_procces = 10000, cTime = 0;
	char runFile[256], testFile[256], nameResult[256], n[256];
	strcpy(testFile, "\0");
	strcpy(runFile, "\0");
	strcpy(nameResult, "testing_result.ini\0");
    //обрабатываем входные параметры
	switch(argc)
	{
	case 9:
		strcpy(n, argv[8]);
	case 8:
		strcpy(nameResult, argv[7]);
	case 7:
		time_procces = atol(argv[6]);
	case 6:
		time_sleep = atol(argv[5]);
	case 5:
		priority = atol(argv[4]);
	case 4:
		strcat(testFile, argv[2]);
		strcat(testFile, " ");
	case 3:
		if(argc>3) strcat(testFile, argv[3]);
		else strcat(testFile, argv[2]);
	case 2:
		strcat(runFile, argv[1]);
		break;
	case 1:
		goto error;
	default:
		break;
	}

	switch (priority)
	{
	case 0:
		priority = IDLE_PRIORITY_CLASS;
		break;
	case 1:
		priority = NORMAL_PRIORITY_CLASS;
		break;
	case 2:
		priority = HIGH_PRIORITY_CLASS;
		break;
	case 3:
		priority = REALTIME_PRIORITY_CLASS;
		break;
	default: 
		priority = NORMAL_PRIORITY_CLASS;
	}

	STARTUPINFO si;
    PROCESS_INFORMATION pi;

	SECURITY_ATTRIBUTES sa;
	sa.nLength = sizeof(SECURITY_ATTRIBUTES);
	sa.bInheritHandle = true;
	sa.lpSecurityDescriptor = NULL;

	char op[256], opp[256];
	if(argc>3)strcpy(op, argv[3]);
	else strcpy(op,"c:\\outfile.txt");

	int j;
	for(j = strlen(op);j>=0;j--) 
		if(op[j] == '.') break;
	op[j] = '\0';

	strcpy(opp, op);
	strcat(opp, "_out_f.");
	if(stream  = fopen( opp, "rt" ))
	{
		fclose(stream);
		strcpy(opp, "_out_s.");
		strcat(op, opp);
	}
	else strcpy(op, opp);
	
	if(argc>8) strcat(op,n);
	else strcat(op,"txt");

	HANDLE hOutput = CreateFile(op, GENERIC_WRITE,FILE_SHARE_WRITE,&sa,CREATE_ALWAYS,NULL,NULL);
	ZeroMemory( &si, sizeof(si) );

    si.cb = sizeof(si);
	si.dwFlags=STARTF_USESTDHANDLES|STARTF_USESHOWWINDOW;
	si.wShowWindow=SW_HIDE;
	si.hStdInput=NULL;
	si.hStdOutput=hOutput;
	si.hStdError=NULL;

    ZeroMemory( &pi, sizeof(pi) );
	
	err++;
	DWORD lpExitCode = 0;time_procces *= 10000;
/*
    FILETIME IdleTime,IdleTime2;
*/
	FILETIME cr,ex,kr,ur;
	
	if(!CreateProcess(runFile, testFile, NULL, NULL, true, priority, NULL, NULL, &si, &pi))
		goto error;
//	GetSystemTimes( &IdleTime, NULL, NULL);
	do
	{

//		GetSystemTimes(&IdleTime2, NULL, NULL);
		GetProcessTimes(pi.hProcess,&cr,&ex,&kr,&ur);

		cTime = kr.dwLowDateTime+ur.dwLowDateTime;// - (*(PDWORD64)&IdleTime2 -*(PDWORD64)&IdleTime);
		if(cTime >= time_procces)
		{
			TerminateProcess(pi.hProcess, STILL_ACTIVE);
			break;
		}

		GetExitCodeProcess(pi.hProcess, &lpExitCode);
		Sleep(time_sleep);

	}while(lpExitCode == STILL_ACTIVE);

	CloseHandle( pi.hProcess );
	CloseHandle( pi.hThread );
	CloseHandle( hOutput );

	time_procces /= 10000;

	switch (priority)
	{
	case IDLE_PRIORITY_CLASS:
		priority = 0;
		break;
	case NORMAL_PRIORITY_CLASS:
		priority = 1;
		break;
	case HIGH_PRIORITY_CLASS:
		priority = 2;
		break;
	case REALTIME_PRIORITY_CLASS:
		priority = 3;
		break;
	default: 
		priority = 1;
	}

   if(!(stream  = fopen( nameResult, "r+" )))
   {
		if(!(stream  = fopen( nameResult, "wt" ))) return 1;
		fprintf( stream, "[result]\r\nrun_file=%s\r\ntest_file=%s\r\npriority_run=%d\r\ntime_sleep=%d\r\ntime_procces=%d\r\ntimer=%d\r\nexit_code=%d\r\nout_file=%s\r\nout_rash=%s\r\n",runFile, testFile, priority, time_sleep, time_procces, cTime, lpExitCode, op, n);
   }
   else
   {
	   fseek(stream, 0L, SEEK_END); 
	   fprintf( stream, "[result_second]\r\nrun_file=%s\r\ntest_file=%s\r\npriority_run=%d\r\ntime_sleep=%d\r\ntime_procces=%d\r\ntimer=%d\r\nexit_code=%d\r\nout_file=%s\r\nout_rash=%s\r\n",runFile, testFile, priority, time_sleep, time_procces, cTime, lpExitCode, op, n);
   }
   fclose( stream );
   return 0;

error:

	if(!(stream  = fopen( nameResult, "wt" ))) return 1;

	char str_err[256];
	switch (err)
	{
	case 0:
		strcpy(str_err, "not found base ini file");
		break;
	case 1:
		strcpy(str_err, "I dont create procces");
		break;
	default:
		strcpy(str_err, "unknow error");
	}
	fprintf( stream, "[error]\r\ntest=%s", str_err);

	fclose( stream );

	return 1;

}