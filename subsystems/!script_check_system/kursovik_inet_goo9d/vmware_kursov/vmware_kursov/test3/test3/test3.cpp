#include "stdafx.h"
#include "windows.h"

//Используем библиотеку vix api
#include "vix.h"
#include <iostream>
#include <stdio.h>
#include <time.h>
#include <shellapi.h>

//Динамически подгружаем библиотеки с помощью LoadLibrary
typedef VixHandle (*ppVixHost_Connect)(int apiVersion,
                          VixServiceProvider hostType,
                          const char *hostName,
                          int hostPort,
                          const char *userName,
                          const char *password,
                          VixHostOptions options,
                          VixHandle propertyListHandle,
                          VixEventProc *callbackProc,
                          void *clientData);
typedef void (*ppVixHost_Disconnect)(VixHandle hostHandle);

typedef VixHandle (*ppVixVM_Open)(VixHandle hostHandle,
                     const char *vmxFilePathName,
                     VixEventProc *callbackProc,
                     void *clientData);

typedef VixHandle (*ppVixVM_PowerOn)(VixHandle vmHandle,
                        VixVMPowerOpOptions powerOnOptions,
                        VixHandle propertyListHandle,
                        VixEventProc *callbackProc,
                        void *clientData);

typedef VixHandle (*ppVixVM_PowerOff)(VixHandle vmHandle,
                         VixVMPowerOpOptions powerOffOptions,
                         VixEventProc *callbackProc,
                         void *clientData);

typedef VixHandle (*ppVixVM_Suspend)(VixHandle vmHandle,
                        VixVMPowerOpOptions powerOffOptions,
                        VixEventProc *callbackProc,
                        void *clientData);

typedef VixHandle (*ppVixVM_WaitForToolsInGuest)(VixHandle vmHandle,
                                    int timeoutInSeconds,
                                    VixEventProc *callbackProc,
                                    void *clientData);

typedef VixHandle (*ppVixVM_LoginInGuest)(VixHandle vmHandle,
                             const char *userName,
                             const char *password,
                             int options,
                             VixEventProc *callbackProc,
                             void *clientData);




typedef VixHandle (*ppVixVM_RunProgramInGuest)(VixHandle vmHandle,
                                  const char *guestProgramName,
                                  const char *commandLineArgs,
                                  VixRunProgramOptions options,
                                  VixHandle propertyListHandle,
                                  VixEventProc *callbackProc,
                                  void *clientData);

typedef VixHandle (*ppVixVM_CopyFileFromHostToGuest)(VixHandle vmHandle,
                                        const char *hostPathName,
                                        const char *guestPathName,
                                        int options,
                                        VixHandle propertyListHandle,
                                        VixEventProc *callbackProc,
                                        void *clientData);

typedef VixHandle (*ppVixVM_CopyFileFromGuestToHost)(VixHandle vmHandle,
                                        const char *guestPathName,
                                        const char *hostPathName,
                                        int options,
                                        VixHandle propertyListHandle,
                                        VixEventProc *callbackProc,
                                        void *clientData);

typedef VixError (*ppVixVM_GetNumRootSnapshots)(VixHandle vmHandle,
                                   int *result);

typedef VixError (*ppVixVM_GetRootSnapshot)(VixHandle vmHandle,
                               int index,
                               VixHandle *snapshotHandle);


typedef VixHandle (*ppVixVM_RevertToSnapshot)(VixHandle vmHandle,
                                 VixHandle snapshotHandle,
                                 int options,
                                 VixHandle propertyListHandle,
                                 VixEventProc *callbackProc,
                                 void *clientData);

typedef VixHandle (*ppVixVM_CreateSnapshot)(VixHandle vmHandle,
                               const char *name,
                               const char *description,
                               int options,
                               VixHandle propertyListHandle,
                               VixEventProc *callbackProc,
                               void *clientData);


typedef VixError (*ppVixJob_Wait)(VixHandle jobHandle, VixPropertyID firstPropertyID, ...);

typedef VixError (*ppVixJob_CheckCompletion)(VixHandle jobHandle, Bool *complete);

typedef VixError (*ppVix_GetProperties)(VixHandle handle, 
                           VixPropertyID firstPropertyID, ...);

typedef void (*ppVix_ReleaseHandle)(VixHandle handle);

typedef const char * (*ppVix_GetErrorText)(VixError err, const char *locale);




    ppVixHost_Connect pVixHost_Connect;// = (ppVixHost_Connect) GetProcAddress(hinstLib, "VixHost_Connect");
    ppVixHost_Disconnect pVixHost_Disconnect;// = (ppVixHost_Disconnect) GetProcAddress(hinstLib, "VixHost_Disconnect");
    ppVixVM_Open pVixVM_Open;// = (ppVixVM_Open) GetProcAddress(hinstLib, "VixVM_Open");
    ppVixVM_PowerOn pVixVM_PowerOn;// = (ppVixVM_PowerOn) GetProcAddress(hinstLib, "VixVM_PowerOn");
    ppVixVM_PowerOff pVixVM_PowerOff;// = (ppVixVM_PowerOff) GetProcAddress(hinstLib, "VixVM_PowerOff");
    ppVixVM_Suspend pVixVM_Suspend ;//= (ppVixVM_Suspend) GetProcAddress(hinstLib, "VixVM_Suspend");
    ppVixVM_WaitForToolsInGuest pVixVM_WaitForToolsInGuest;// = (ppVixVM_WaitForToolsInGuest) GetProcAddress(hinstLib, "VixVM_WaitForToolsInGuest");
    ppVixVM_LoginInGuest pVixVM_LoginInGuest;// = (ppVixVM_LoginInGuest) GetProcAddress(hinstLib, "VixVM_LoginInGuest");
    ppVixVM_RunProgramInGuest pVixVM_RunProgramInGuest;// = (ppVixVM_RunProgramInGuest) GetProcAddress(hinstLib, "VixVM_RunProgramInGuest");
    ppVixVM_CopyFileFromHostToGuest pVixVM_CopyFileFromHostToGuest;// = (ppVixVM_CopyFileFromHostToGuest) GetProcAddress(hinstLib, "VixVM_CopyFileFromHostToGuest");
    ppVixVM_CopyFileFromGuestToHost pVixVM_CopyFileFromGuestToHost;// = (ppVixVM_CopyFileFromGuestToHost) GetProcAddress(hinstLib, "VixVM_CopyFileFromGuestToHost");
    ppVixVM_GetNumRootSnapshots pVixVM_GetNumRootSnapshots;// = (ppVixVM_GetNumRootSnapshots) GetProcAddress(hinstLib, "VixVM_GetNumRootSnapshots");
    ppVixVM_GetRootSnapshot pVixVM_GetRootSnapshot;// = (ppVixVM_GetRootSnapshot) GetProcAddress(hinstLib, "VixVM_GetRootSnapshot");
    ppVixVM_RevertToSnapshot pVixVM_RevertToSnapshot;// = (ppVixVM_RevertToSnapshot) GetProcAddress(hinstLib, "VixVM_RevertToSnapshot");
    ppVixVM_CreateSnapshot pVixVM_CreateSnapshot;// = (ppVixVM_CreateSnapshot) GetProcAddress(hinstLib, "VixVM_CreateSnapshot");
    ppVixJob_Wait pVixJob_Wait;// = (ppVixJob_Wait) GetProcAddress(hinstLib, "VixJob_Wait");
    ppVixJob_CheckCompletion pVixJob_CheckCompletion;// = (ppVixJob_CheckCompletion) GetProcAddress(hinstLib, "VixJob_CheckCompletion");
    ppVix_GetProperties pVix_GetProperties;// = (ppVix_GetProperties) GetProcAddress(hinstLib, "Vix_GetProperties");
    ppVix_ReleaseHandle pVix_ReleaseHandle;// = (ppVixJob_CheckCompletion) GetProcAddress(hinstLib, "VixJob_CheckCompletion");

ppVix_GetErrorText pVix_GetErrorText;

//Глобальные переменные
char out_exec_from[256], out_exec_to[256], report_rash[256], name_report[256], out_report_f[256], out_report_s[256], utilTesting[256], logName[256], 
	test_fileToVM[256], good_fileToVM[256], nameOfVM[256],loginVM[256], passVM[256], pathInGuest[256], prog_exec_f[256],
	prog_exec_s[256], result_report[256], temp[256], temp2[256]; 
int count_vm, global_timeout, priority_now, exec_prior_f, exec_sleep_f, exec_timelimit_f,
				exec_prior_s, exec_sleep_s, exec_timelimit_s;

VixHandle hostHandle = VIX_INVALID_HANDLE;
VixError err;
VixHandle jobHandle = VIX_INVALID_HANDLE;
VixHandle vmHandle = VIX_INVALID_HANDLE;
VixHandle snapshotHandle = VIX_INVALID_HANDLE;
VixPowerState powerState = 0;
Bool jobCompleted = FALSE;
SHFILEOPSTRUCT sh;

int result = 0, num=0;

// Ведение лога ошибок
bool flag = true;
void log_error(const char* str)
{
	FILE* stream;
	time_t t;
	time(&t);
	tm* m = localtime(&t);
	if(!(stream  = fopen( logName, "at" )))
		stream = fopen( logName, "wt" );
	char tmp[25];
	strcpy(tmp, asctime(m));
	tmp[strlen(tmp)-1] = '\0';
	if(flag)
	{
		flag = false;
		fprintf( stream, "---------------\nFound error\n");
        fprintf( stream, "path_to_vm=%s\ncount_vm=%d\nvmware_number=%d\nglobal_timeout(<)=%d\nlogin_in_vm=%s\nprogram_exec_first=%s\nprogram_exec_second=%s\n",nameOfVM, count_vm, num, global_timeout,loginVM, prog_exec_f, prog_exec_s );
	}
	fprintf( stream, "%s %s\n", tmp, str);

	fclose( stream );
}
////////////////////////////////////////////////////////////////////////////////
//Данный поток, который отвечает за работу с Виртальной машиной
DWORD WINAPI workToVM( LPVOID lpParam ) 
{
    //Подключаемся к хосту
    jobHandle = pVixHost_Connect(VIX_API_VERSION,VIX_SERVICEPROVIDER_VMWARE_SERVER,NULL, 0,NULL, NULL, 0, VIX_INVALID_HANDLE, NULL, NULL); 

	result++;
	err = pVixJob_CheckCompletion(jobHandle, &jobCompleted);
    //Проверяем успешность операции
    //Если операция завершилась неудачно, выходим
	if (VIX_OK != err)
	{
		log_error("bad result from CheckCompletion, host to connect");
		pVix_ReleaseHandle(jobHandle);
        return result; //1
	}
    //Ждем пока операция завершится
    //Данные операции совершаются асинхронно
	while (!jobCompleted) 
	{
		err = pVixJob_CheckCompletion(jobHandle, &jobCompleted);
		if (VIX_OK != err)
		{
			log_error("bad result from CheckCompletion, host to connect");
			pVix_ReleaseHandle(jobHandle);
			return result; //1
		}
		Sleep(100);
	}
    //Получаем handle хоста (hostHandle)
	err = pVix_GetProperties(jobHandle, VIX_PROPERTY_JOB_RESULT_HANDLE, &hostHandle,VIX_PROPERTY_NONE);
    if (VIX_OK != err) 
	{
		log_error("Bad is connect to VMWare (bad VIX_PROPERTY_JOB_RESULT_HANDLE)");
		pVix_ReleaseHandle(jobHandle);
		pVixHost_Disconnect(hostHandle);
        return result; //1
    }
    pVix_ReleaseHandle(jobHandle);

    //Открываем хост
  	jobHandle = pVixVM_Open(hostHandle,nameOfVM,NULL,NULL);
 
	result++;

	jobCompleted = FALSE;
	err = pVixJob_CheckCompletion(jobHandle, &jobCompleted);
	if (VIX_OK != err)		
	{
		log_error("bad result from CheckCompletion, open to guest machine");
		pVix_ReleaseHandle(jobHandle);
		pVixHost_Disconnect(hostHandle);
		return result; //2
	}
	while (!jobCompleted) 
	{
		err = pVixJob_CheckCompletion(jobHandle, &jobCompleted);
		if (VIX_OK != err)		
		{
			log_error("bad result from CheckCompletion, open to guest machine");
			pVix_ReleaseHandle(jobHandle);
			pVixHost_Disconnect(hostHandle);
			return result; //2
		}
		Sleep(200);
	}

    //Получаем handle Виртуальной машины 
    err = pVixJob_Wait(jobHandle,VIX_PROPERTY_JOB_RESULT_HANDLE,&vmHandle ,VIX_PROPERTY_NONE);

    if (VIX_OK != err) 
	{
		log_error("Bad is open VMWare (bad VIX_PROPERTY_JOB_RESULT_HANDLE)");
		pVix_ReleaseHandle(jobHandle);
		pVix_ReleaseHandle(vmHandle);
		pVixHost_Disconnect(hostHandle);
        return result; //2
    }
	pVix_ReleaseHandle(jobHandle);

	result++;
//----------------------------------------------------------------------------------------
new_loop:
    //Получаем статус виртуальной машины (ВМ)
	powerState = 0;
	err = pVix_GetProperties(vmHandle,VIX_PROPERTY_VM_POWER_STATE,&powerState,VIX_PROPERTY_NONE);
	if (VIX_OK != err) 
	{
		log_error("Bad is open VMWare (bad VIX_PROPERTY_VM_POWER_STATE)");
		pVix_ReleaseHandle(vmHandle);
		pVixHost_Disconnect(hostHandle);
		return result; //3
	}
    //На основании полученного статуса выполним соответствующее действие
	switch (powerState)
	{
        //Если машина выключается, пишем в лог, спим секунду и получаем статус снова 
	case VIX_POWERSTATE_POWERING_OFF:
		log_error("Машина выключаеться, подождем не много и опять посмотрим");
		Sleep(1000);
		goto new_loop;
        //Машина выключена, получаем снимок, если снимка нет, то пишем в лог 
        //и переходим к следующему блоку
	case VIX_POWERSTATE_POWERED_OFF:
revert_vm:
		err = pVixVM_GetRootSnapshot(vmHandle, 0, &snapshotHandle);
		if (VIX_OK != err) 
		{
			log_error("Машины выключена, пытался найти снимок, но не нашёл, будем запускать так");
			break;
		}
		pVix_ReleaseHandle(jobHandle);
        //если снимок есть, то востановим его
        //если возникнет ошибка, то информация запишется в лог и переход к следующему блоку
	    jobHandle = pVixVM_RevertToSnapshot(vmHandle, snapshotHandle,0,VIX_INVALID_HANDLE,NULL,NULL);
		jobCompleted = FALSE;
		err = pVixJob_CheckCompletion(jobHandle, &jobCompleted);
		if (VIX_OK != err)
		{
			log_error("Машины выключена, снимок вроде нашёл, но востановить не удалось");
			break;
		}
		while (!jobCompleted) 
		{
			err = pVixJob_CheckCompletion(jobHandle, &jobCompleted);
			if (VIX_OK != err)
			{
				log_error("Машины выключена, снимок вроде нашёл, но востановить не удалось (second)");
				break;
			}
			Sleep(200);
		}  
		pVix_ReleaseHandle(jobHandle);
//***************************************************************		
		break;
        //Машина включается
	case VIX_POWERSTATE_POWERING_ON:
		log_error("Машина включаеться, не порядок, подождем не много и опять по смотрим");
		Sleep(1000);
		goto new_loop;
        //Машина включена, пишем в лог и востанавливаем снимок
	case VIX_POWERSTATE_POWERED_ON:
		log_error("Почему то машина уже включена, попытаемся её восстановить (снимок)");
		goto revert_vm;
        //Машина приостанавливается
	case VIX_POWERSTATE_SUSPENDING:
		log_error("VIX_POWERSTATE_SUSPENDING, через 1 секунду ещё раз посмотрим");
		Sleep(1000);
		goto new_loop;
        //Машина перезагружается
	case VIX_POWERSTATE_RESETTING:
		log_error("Машина перезагружаеться, ждем секунду и опять смотрим");
		Sleep(1000);
		goto new_loop;
        //Все нормально
	case VIX_POWERSTATE_SUSPENDED: // good
		break;
	}

	result++;
    //получаем кол-во снимков
	int numSnapshots =0;
	err = pVixVM_GetNumRootSnapshots(vmHandle, &numSnapshots);
    if (VIX_OK != err) 
	{
		log_error("Bad is GetNumRootSnapshot");
		pVix_ReleaseHandle(vmHandle);
		pVixHost_Disconnect(hostHandle);
        return result; //4
    }
    //включаем ВМ
	jobHandle = pVixVM_PowerOn(vmHandle,VIX_VMPOWEROP_NORMAL,VIX_INVALID_HANDLE,NULL,NULL); 
 
	result++;

	jobCompleted = FALSE;
	err = pVixJob_CheckCompletion(jobHandle, &jobCompleted);
	if (VIX_OK != err)
	{
		log_error("bad result from CheckCompletion, power_on to guest machine");
		pVix_ReleaseHandle(jobHandle);	
		pVix_ReleaseHandle(vmHandle);	
		pVixHost_Disconnect(hostHandle);
		return result; //5
	}
	while (!jobCompleted) 
	{
		err = pVixJob_CheckCompletion(jobHandle, &jobCompleted);
		if (VIX_OK != err)
		{
			log_error("bad result from CheckCompletion, power_on to guest machine");
			pVix_ReleaseHandle(jobHandle);	
			pVix_ReleaseHandle(vmHandle);	
			pVixHost_Disconnect(hostHandle);
			return result; //5
		}
		Sleep(500);
	}   
    pVix_ReleaseHandle(jobHandle);
//----------------------------------------------------------------------------------------
//****************************************************************************************
	result++;
    //Если снимков нет, то делаем его
	if(numSnapshots == 0)
	{	
		jobHandle = pVixVM_CreateSnapshot(vmHandle,"good_vm","good_vm",0,VIX_INVALID_HANDLE,NULL,NULL);
 
		jobCompleted = FALSE;
		err = pVixJob_CheckCompletion(jobHandle, &jobCompleted);
		if (VIX_OK != err)
		{
			log_error("bad result from CheckCompletion, CreateSnapshot");
			pVix_ReleaseHandle(jobHandle);	
			return result; //6
		}
		while (!jobCompleted) 
		{
			err = pVixJob_CheckCompletion(jobHandle, &jobCompleted);
			if (VIX_OK != err)
			{
				log_error("bad result from CheckCompletion, CreateSnapshot");
				pVix_ReleaseHandle(jobHandle);	
				return result; //6
			}
			Sleep(500);
		}   
		err = pVix_GetProperties(jobHandle,VIX_PROPERTY_JOB_RESULT_HANDLE,&snapshotHandle,VIX_PROPERTY_NONE);
		if (VIX_OK != err) 
		{
			log_error("Bad VIX_PROPERTY_JOB_RESULT_HANDLE, CreateSnapshot");
			pVix_ReleaseHandle(jobHandle);	
			pVix_ReleaseHandle(snapshotHandle);	
			return result; //6
		}
		pVix_ReleaseHandle(jobHandle);
		pVix_ReleaseHandle(snapshotHandle);
	}

	result++;

//===============================================
	
    //Настройка ВМ
	jobHandle = pVixVM_WaitForToolsInGuest(vmHandle,60, NULL, NULL); // !!! time limit small ~0

	result++;

	jobCompleted = FALSE;
	err = pVixJob_CheckCompletion(jobHandle, &jobCompleted);
	if (VIX_OK != err)
	{
		log_error("bad result from CheckCompletion, WaitForToolsInGuest");
		pVix_ReleaseHandle(jobHandle);	
		return result; //8
	}
	while (!jobCompleted) 
	{
		err = pVixJob_CheckCompletion(jobHandle, &jobCompleted);
		if (VIX_OK != err)
		{
			log_error("bad result from CheckCompletion, WaitForToolsInGuest");
			pVix_ReleaseHandle(jobHandle);	
			return result; //8
		}
		Sleep(200);
	}   

	pVix_ReleaseHandle(jobHandle);

	result++;
    //Авторизируемся в системе
    //! Гостевая ОС, обязательно должна быть защищена паролем
    //Логин и пароль задаются в конфигурационном файле
	jobHandle = pVixVM_LoginInGuest(vmHandle,loginVM, passVM, 0, NULL, NULL); 
	
	result++;

	jobCompleted = FALSE;
	err = pVixJob_CheckCompletion(jobHandle, &jobCompleted);
	if (VIX_OK != err)
	{
		log_error("bad result from CheckCompletion, LoginInGuest");
		pVix_ReleaseHandle(jobHandle);	
		return result; //10
	}
	while (!jobCompleted) 
	{
		err = pVixJob_CheckCompletion(jobHandle, &jobCompleted);
		if (VIX_OK != err)
		{
			log_error("bad result from CheckCompletion, LoginInGuest");
			pVix_ReleaseHandle(jobHandle);	
			return result; //10
		}
		Sleep(200);
	}  
	pVix_ReleaseHandle(jobHandle);
	
	result++;

//===============================================
    //Копируем исходный код решаемой задачи в ВМ
	char n_temp3[256], temp4[256];
	strcpy(n_temp3, pathInGuest);
	strcpy(temp4, "\0");
	int o,oo;oo = o = strlen(test_fileToVM);
	for(;o>=0;o--) if(test_fileToVM[o]=='\\') break;o++;
	for(int k = 0;o<=oo;o++,k++) temp4[k] = test_fileToVM[o];

 	strcat(n_temp3, temp4);

	jobHandle = pVixVM_CopyFileFromHostToGuest(vmHandle,test_fileToVM, n_temp3, 0, VIX_INVALID_HANDLE, NULL, NULL);
	
	strcpy(temp4, "\0");
	result++;

	jobCompleted = FALSE;
	err = pVixJob_CheckCompletion(jobHandle, &jobCompleted);
	if (VIX_OK != err)
	{
		log_error("bad result from CheckCompletion, CopyFileFromHostToGuest");
		pVix_ReleaseHandle(jobHandle);	
		return result; //12
	}
	while (!jobCompleted) 
	{
		err = pVixJob_CheckCompletion(jobHandle, &jobCompleted);
		if (VIX_OK != err)
		{
			log_error("bad result from CheckCompletion, CopyFileFromHostToGuest");
			pVix_ReleaseHandle(jobHandle);	
			return result; //12
		}
		Sleep(200);
	}  
	pVix_ReleaseHandle(jobHandle);


	result++;
    //Передаем необходимые файлы (test_util.exe)
	char n_temp4[256];
	strcpy(n_temp4, pathInGuest);
	oo = o = strlen(utilTesting);
	for(;o>=0;o--) if(utilTesting[o]=='\\') break;o++;
	for(int k = 0;o<=oo;o++,k++) temp4[k] = utilTesting[o];


	strcat(n_temp4, temp4);

	jobHandle = pVixVM_CopyFileFromHostToGuest(vmHandle,utilTesting, n_temp4, 0, VIX_INVALID_HANDLE, NULL, NULL);

	strcpy(temp4, "\0");
	result++;

	jobCompleted = FALSE;
	err = pVixJob_CheckCompletion(jobHandle, &jobCompleted);
	if (VIX_OK != err)
	{
		log_error("bad result from CheckCompletion, CopyFileFromHostToGuest");
		pVix_ReleaseHandle(jobHandle);	
		return result; //14
	}
	while (!jobCompleted) 
	{
		err = pVixJob_CheckCompletion(jobHandle, &jobCompleted);
		if (VIX_OK != err)
		{
			log_error("bad result from CheckCompletion, CopyFileFromHostToGuest");
			pVix_ReleaseHandle(jobHandle);	
			return result; //14
		}
		Sleep(200);
	}  
	pVix_ReleaseHandle(jobHandle);

	result++;
       //Запускаем test_util.exe внутри ВМ
	char temp5[256]; // temp
	strcpy(temp5, "\0");

	oo = o = strlen(prog_exec_f);
	for(;o>=0;o--) if(prog_exec_f[o]=='\\') break;o++;
	for(int k = 0;o<=oo;o++,k++) temp4[k] = prog_exec_f[o];

	strcpy(temp5, prog_exec_f); // runFile
	strcat(temp5, " ");
	strcat(temp5, temp4);
	strcat(temp5, " "); 
	strcat(temp5, n_temp3);// testFile

    //Передаем аргументы test_util.exe
	strcpy(temp4, "\0");
	sprintf(temp4, " %d %d %d %s%s %s", exec_prior_f, exec_sleep_f, exec_timelimit_f, pathInGuest, result_report, report_rash);

	strcat(temp5, temp4);
	strcpy(temp4, "\0");
	
	jobHandle = pVixVM_RunProgramInGuest(vmHandle,n_temp4,temp5,0,VIX_INVALID_HANDLE,NULL,NULL);

	strcpy(temp5, "\0");
	result++;
	
	jobCompleted = FALSE;
	err = pVixJob_CheckCompletion(jobHandle, &jobCompleted);
	if (VIX_OK != err)
	{
		log_error("bad result from CheckCompletion, RunProgramInGuest");
		pVix_ReleaseHandle(jobHandle);	
		return result; //16
	}
	while (!jobCompleted) 
	{
		err = pVixJob_CheckCompletion(jobHandle, &jobCompleted);
		if (VIX_OK != err)
		{
			log_error("bad result from CheckCompletion, RunProgramInGuest");
			pVix_ReleaseHandle(jobHandle);	
			return result; //16
		}
		Sleep(200);
	}  
	pVix_ReleaseHandle(jobHandle);

	result++;
    //Копируем скрипт выполняющий проверку правильности решения в ВМ
	strcpy(n_temp3, "\0");
	strcpy(n_temp3, pathInGuest);
	oo = o = strlen(good_fileToVM);
	for(;o>=0;o--) if(good_fileToVM[o]=='\\') break;o++;
	for(int k = 0;o<=oo;o++,k++) temp4[k] = good_fileToVM[o];

	strcat(n_temp3, temp4);

	jobHandle = pVixVM_CopyFileFromHostToGuest(vmHandle,good_fileToVM, n_temp3, 0, VIX_INVALID_HANDLE, NULL, NULL);
	
	strcpy(temp4, "\0");
	result++;

	jobCompleted = FALSE;
	err = pVixJob_CheckCompletion(jobHandle, &jobCompleted);
	if (VIX_OK != err)
	{
		log_error("bad result from CheckCompletion, CopyFileFromHostToGuest");
		pVix_ReleaseHandle(jobHandle);	
		return result; //18
	}
	while (!jobCompleted) 
	{
		err = pVixJob_CheckCompletion(jobHandle, &jobCompleted);
		if (VIX_OK != err)
		{
			log_error("bad result from CheckCompletion, CopyFileFromHostToGuest");
			pVix_ReleaseHandle(jobHandle);	
			return result; //18
		}
		Sleep(200);
	}  
	pVix_ReleaseHandle(jobHandle);

	result++;
    //Снова копируем test_util.exe в ВМ
	jobHandle = pVixVM_CopyFileFromHostToGuest(vmHandle,utilTesting, n_temp4, 0, VIX_INVALID_HANDLE, NULL, NULL);

	result++;

	jobCompleted = FALSE;
	err = pVixJob_CheckCompletion(jobHandle, &jobCompleted);
	if (VIX_OK != err)
	{
		log_error("bad result from CheckCompletion, CopyFileFromHostToGuest (reload)");
		pVix_ReleaseHandle(jobHandle);	
		return result; //20
	}
	while (!jobCompleted) 
	{
		err = pVixJob_CheckCompletion(jobHandle, &jobCompleted);
		if (VIX_OK != err)
		{
			log_error("bad result from CheckCompletion, CopyFileFromHostToGuest (reload)");
			pVix_ReleaseHandle(jobHandle);	
			return result; //20
		}
		Sleep(200);
	}  
	pVix_ReleaseHandle(jobHandle);

	result++;
    // запуск test_util.exe внутри ВМ
	oo = o = strlen(prog_exec_s);
	for(;o>=0;o--) if(prog_exec_s[o]=='\\') break;o++;
	for(int k = 0;o<=oo;o++,k++) temp4[k] = prog_exec_s[o];

	strcpy(temp5, prog_exec_s); // runFile
	strcat(temp5, " ");
	strcat(temp5, temp4);
	strcat(temp5, " "); 
	strcat(temp5, n_temp3);// testFile

	strcpy(temp4, "\0");
	sprintf(temp4, " %d %d %d %s%s %s", exec_prior_s, exec_sleep_s, exec_timelimit_s, pathInGuest, result_report, report_rash);

	strcat(temp5, temp4);
	strcpy(temp4, "\0");
	
	jobHandle = pVixVM_RunProgramInGuest(vmHandle,n_temp4,temp5,0,VIX_INVALID_HANDLE,NULL,NULL);

	strcpy(temp5, "\0");
	result++;
	
	jobCompleted = FALSE;
	err = pVixJob_CheckCompletion(jobHandle, &jobCompleted);
	if (VIX_OK != err)
	{
		log_error("bad result from CheckCompletion, RunProgramInGuest");
		pVix_ReleaseHandle(jobHandle);	
		return result; //22
	}
	while (!jobCompleted) 
	{
		err = pVixJob_CheckCompletion(jobHandle, &jobCompleted);
		if (VIX_OK != err)
		{
			log_error("bad result from CheckCompletion, RunProgramInGuest");
			pVix_ReleaseHandle(jobHandle);	
			return result; //22
		}
		Sleep(200);
	}  
	pVix_ReleaseHandle(jobHandle);

	result++;
    // Копируем файл содержащий результаты работы (result.ini) из ВМ
	strcpy(temp5, name_report);
	GetFullPathName(temp5, 256, name_report, NULL);
	strcpy(temp4, pathInGuest);
	strcat(temp4, result_report);

	jobHandle = pVixVM_CopyFileFromGuestToHost(vmHandle,temp4, name_report, 0, VIX_INVALID_HANDLE, NULL, NULL);

	strcpy(temp4, "\0");
	strcpy(temp5, "\0");
	result++;

	jobCompleted = FALSE;
	err = pVixJob_CheckCompletion(jobHandle, &jobCompleted);
	if (VIX_OK != err)
	{
		log_error("bad result from CheckCompletion, CopyFileFromGuestToHost");
		pVix_ReleaseHandle(jobHandle);	
		return result; //24
	}
	while (!jobCompleted) 
	{
		err = pVixJob_CheckCompletion(jobHandle, &jobCompleted);
		if (VIX_OK != err)
		{
			log_error("bad result from CheckCompletion, CopyFileFromGuestToHost");
			pVix_ReleaseHandle(jobHandle);	
			return result; //24
		}
		Sleep(200);
	}  
	pVix_ReleaseHandle(jobHandle);

    //Читаем принятый файл
	GetPrivateProfileString( "error", "text", "0", temp4, 256, name_report);
	if(strcmp(temp4,"0")) return result; // была ошибка , фатальная, лучше выйти нах
	strcpy(temp4, "\0");


	GetPrivateProfileString( "result", "out_file", "0", temp4, 256, name_report);
	if(!strcmp(temp4,"0")) return result; // значит файлов нет, то есть прога даже не запустилась

	GetPrivateProfileString( "result_second", "out_file", "0", temp5, 256, name_report);
	if(!strcmp(temp5,"0")) return result;

	result++;
    //копируем файлы содержащие выходные потоки из ВМ
	jobHandle = pVixVM_CopyFileFromGuestToHost(vmHandle,temp4, out_report_f, 0, VIX_INVALID_HANDLE, NULL, NULL);

	strcpy(temp4, "\0");
	result++;

	jobCompleted = FALSE;
	err = pVixJob_CheckCompletion(jobHandle, &jobCompleted);
	if (VIX_OK != err)
	{
		log_error("bad result from CheckCompletion, CopyFileFromHostToGuest");
		pVix_ReleaseHandle(jobHandle);	
		return result; //26
	}
	while (!jobCompleted) 
	{
		err = pVixJob_CheckCompletion(jobHandle, &jobCompleted);
		if (VIX_OK != err)
		{
			log_error("bad result from CheckCompletion, CopyFileFromHostToGuest");
			pVix_ReleaseHandle(jobHandle);	
			return result; //26
		}
		Sleep(200);
	}  
	pVix_ReleaseHandle(jobHandle);

	result++;

	jobHandle = pVixVM_CopyFileFromGuestToHost(vmHandle,temp5, out_report_s, 0, VIX_INVALID_HANDLE, NULL, NULL);

	strcpy(temp5, "\0");
	result++;

	jobCompleted = FALSE;
	err = pVixJob_CheckCompletion(jobHandle, &jobCompleted);
	if (VIX_OK != err)
	{
		log_error("bad result from CheckCompletion, CopyFileFromHostToGuest");
		pVix_ReleaseHandle(jobHandle);	
		return result; //28
	}
	while (!jobCompleted) 
	{
		err = pVixJob_CheckCompletion(jobHandle, &jobCompleted);
		if (VIX_OK != err)
		{
			log_error("bad result from CheckCompletion, CopyFileFromHostToGuest");
			pVix_ReleaseHandle(jobHandle);	
			return result; //28
		}
		Sleep(200);
	}  
	pVix_ReleaseHandle(jobHandle);

	result++;

    //Получаем handle снимка
    err = pVixVM_GetRootSnapshot(vmHandle, 0, &snapshotHandle);
    if (VIX_OK != err) 
	{
		log_error("bad result from GetRootSnapshot");
		pVix_ReleaseHandle(jobHandle);	
        return result; //29
    }

    pVix_ReleaseHandle(jobHandle);

	result++;

    //Востанавливаем состояние ВМ
    jobHandle = pVixVM_RevertToSnapshot(vmHandle, snapshotHandle,0,VIX_INVALID_HANDLE,NULL,NULL);

	result++;
	jobCompleted = FALSE;
	err = pVixJob_CheckCompletion(jobHandle, &jobCompleted);
	if (VIX_OK != err)
	{
		log_error("bad result from CheckCompletion, RevertToSnapshot");
		pVix_ReleaseHandle(jobHandle);	
		return result; //31
	}
	while (!jobCompleted) 
	{
		err = pVixJob_CheckCompletion(jobHandle, &jobCompleted);
		if (VIX_OK != err)
		{
			log_error("bad result from CheckCompletion, RevertToSnapshot");
			pVix_ReleaseHandle(jobHandle);	
			return result; //31
		}
		Sleep(200);
	}  
	pVix_ReleaseHandle(jobHandle);


	result++;

    //Переводим ВМ в состояние Suspend
	jobHandle = pVixVM_Suspend(vmHandle,0, NULL,NULL);

	result++;

	jobCompleted = FALSE;
	err = pVixJob_CheckCompletion(jobHandle, &jobCompleted);
	if (VIX_OK != err)
	{
		log_error("bad result from CheckCompletion, suspend to guest machine");
		pVix_ReleaseHandle(jobHandle);
		return result; //33
	}
	while (!jobCompleted) 
	{
		err = pVixJob_CheckCompletion(jobHandle, &jobCompleted);
		if (VIX_OK != err)
		{
			log_error("bad result from CheckCompletion, suspend to guest machine");
			pVix_ReleaseHandle(jobHandle);
			return result;//33
		}
		Sleep(200);
	}   
	pVix_ReleaseHandle(jobHandle);

	result++;

	powerState = 0; // !!!
	while (VIX_POWERSTATE_SUSPENDED != powerState) 
	{
		err = pVix_GetProperties(vmHandle,VIX_PROPERTY_VM_POWER_STATE,&powerState,VIX_PROPERTY_NONE);
		if (VIX_OK != err) 
		{
			log_error("bad result from pVix_GetProperties, suspend is BAD");
			pVix_ReleaseHandle(jobHandle);
			return result; //34
		}
		Sleep(200);
	}

	result++; //35

    //Отключамся от ВМ
    pVix_ReleaseHandle(jobHandle);
    pVix_ReleaseHandle(vmHandle);
	pVixHost_Disconnect(hostHandle);
	
	return result;
}

////////////////////////////////////////////////////////////////////////////////
int main(int argc, char* argv[])
{

        //Подгружаем необходимые библиотеки
    HINSTANCE hinstLib; 
    hinstLib = LoadLibrary("libeay32.dll"); 
    hinstLib = LoadLibrary("ssleay32.dll"); 
    hinstLib = LoadLibrary("vix.dll"); 

    if(hinstLib==NULL)  return 1;

    pVixHost_Connect = (ppVixHost_Connect) GetProcAddress(hinstLib, "VixHost_Connect");
     pVixHost_Disconnect = (ppVixHost_Disconnect) GetProcAddress(hinstLib, "VixHost_Disconnect");
     pVixVM_Open = (ppVixVM_Open) GetProcAddress(hinstLib, "VixVM_Open");
     pVixVM_PowerOn = (ppVixVM_PowerOn) GetProcAddress(hinstLib, "VixVM_PowerOn");
     pVixVM_PowerOff = (ppVixVM_PowerOff) GetProcAddress(hinstLib, "VixVM_PowerOff");
     pVixVM_Suspend = (ppVixVM_Suspend) GetProcAddress(hinstLib, "VixVM_Suspend");
     pVixVM_WaitForToolsInGuest = (ppVixVM_WaitForToolsInGuest) GetProcAddress(hinstLib, "VixVM_WaitForToolsInGuest");
     pVixVM_LoginInGuest = (ppVixVM_LoginInGuest) GetProcAddress(hinstLib, "VixVM_LoginInGuest");
     pVixVM_RunProgramInGuest = (ppVixVM_RunProgramInGuest) GetProcAddress(hinstLib, "VixVM_RunProgramInGuest");
     pVixVM_CopyFileFromHostToGuest = (ppVixVM_CopyFileFromHostToGuest) GetProcAddress(hinstLib, "VixVM_CopyFileFromHostToGuest");
     pVixVM_CopyFileFromGuestToHost = (ppVixVM_CopyFileFromGuestToHost) GetProcAddress(hinstLib, "VixVM_CopyFileFromGuestToHost");
     pVixVM_GetNumRootSnapshots = (ppVixVM_GetNumRootSnapshots) GetProcAddress(hinstLib, "VixVM_GetNumRootSnapshots");
     pVixVM_GetRootSnapshot = (ppVixVM_GetRootSnapshot) GetProcAddress(hinstLib, "VixVM_GetRootSnapshot");
     pVixVM_RevertToSnapshot = (ppVixVM_RevertToSnapshot) GetProcAddress(hinstLib, "VixVM_RevertToSnapshot");
     pVixVM_CreateSnapshot = (ppVixVM_CreateSnapshot) GetProcAddress(hinstLib, "VixVM_CreateSnapshot");
     pVixJob_Wait = (ppVixJob_Wait) GetProcAddress(hinstLib, "VixJob_Wait");
     pVixJob_CheckCompletion = (ppVixJob_CheckCompletion) GetProcAddress(hinstLib, "VixJob_CheckCompletion");
     pVix_GetProperties = (ppVix_GetProperties) GetProcAddress(hinstLib, "Vix_GetProperties");
     pVix_ReleaseHandle = (ppVix_ReleaseHandle) GetProcAddress(hinstLib, "Vix_ReleaseHandle");

pVix_GetErrorText = (ppVix_GetErrorText) GetProcAddress(hinstLib, "Vix_GetErrorText");

    //Читаем файл настроек
    strcpy(temp, "\0");

    //имя файла для ошибок
	GetPrivateProfileString( "base_options", "name_log_file", ".\\log_errors.txt", temp, 256, ".\\options.ini");
	strcpy(logName, "\0");
	strcpy(logName, temp);
	strcpy(temp, "\0");

    //путь до test_util.exe
	GetPrivateProfileString( "base_options", "path_to_test_util", "0", temp, 256, ".\\options.ini");
	if(!strcmp(temp,"0"))
	{
		log_error("Ошибка в ini файле, не найдено или не коректно поле path_to_test_util");
		goto exit2;
	}
	strcpy(utilTesting, "\0");
	strcpy(utilTesting, temp);
	strcpy(temp, "\0");

    //Количество ВМ
	count_vm = GetPrivateProfileInt( "base_options", "count_vm", 0, ".\\options.ini");
	if(count_vm==0)
	{
		log_error("Ошибка в ini файле, не найдено или не коректно поле count_vm");
		goto exit2;
	}
    global_timeout = GetPrivateProfileInt( "base_options", "global_timeout", 100, ".\\options.ini");

    //приоритет запускаемого потока
	int priority_now_temp = GetPrivateProfileInt( "base_options", "priority_now", 2, ".\\options.ini");
    
    //расширение временных фалов
	GetPrivateProfileString( "base_options", "report_rash", "obj", report_rash, 256, ".\\options.ini");
	
/*
#define THREAD_PRIORITY_LOWEST          THREAD_BASE_PRIORITY_MIN
#define THREAD_PRIORITY_BELOW_NORMAL    (THREAD_PRIORITY_LOWEST+1)
#define THREAD_PRIORITY_NORMAL          0
#define THREAD_PRIORITY_HIGHEST         THREAD_BASE_PRIORITY_MAX
#define THREAD_PRIORITY_ABOVE_NORMAL    (THREAD_PRIORITY_HIGHEST-1)
#define THREAD_PRIORITY_ERROR_RETURN    (MAXLONG)
*/
	switch (priority_now_temp)
	{
	case 0:
		priority_now = THREAD_PRIORITY_LOWEST;
		break;
	case 1:
		priority_now = THREAD_PRIORITY_BELOW_NORMAL;
		break;
	case 2:
		priority_now = THREAD_PRIORITY_NORMAL;
		break;
	case 3:
		priority_now = THREAD_PRIORITY_HIGHEST;
		break;
	case 4:
		priority_now = THREAD_PRIORITY_ABOVE_NORMAL;
		break;
	case 5: 
		priority_now = THREAD_PRIORITY_ERROR_RETURN;
		break;
	default:
		priority_now = THREAD_PRIORITY_NORMAL;
	}

	strcpy(temp2, "\0");

    int yy;char ggg[256];
	strcpy(ggg, "\0");
    strcat(ggg, argv[0]);
    for(yy=strlen(ggg);yy>=0;yy--) 
		if(ggg[yy]=='.') break;
	ggg[yy] = '\0';
    strcat(ggg, "_ex.vbs");



	strcpy(test_fileToVM, "\0");
    strcpy(test_fileToVM, ggg);

    //сохраняем входной поток
	int q;
    strcpy(good_fileToVM, test_fileToVM);
    for(q = strlen(good_fileToVM);q>=0;q--) 
		if(good_fileToVM[q]=='.') break;
    good_fileToVM[q] = '\0';
	strcat(good_fileToVM, "_in.vbs");
    
       
    FILE* std_in;char f_tmp[256];
    if((std_in = fopen(good_fileToVM, "wt")) == NULL) goto exit2;
    gets(f_tmp);
	
    //получаем номер ВМ
	num = atoi(f_tmp);
    if((num>count_vm) || (num<=0)) goto exit2;
    
	while (!feof(stdin))
    {
		gets(f_tmp);
        fprintf(std_in, "%s\n", f_tmp);
	}
    fclose(std_in);

	int j;
	
	strcpy(name_report, test_fileToVM);
	for(j = strlen(name_report);j>=0;j--) 
		if(name_report[j] == '.') break;
	name_report[j] = '\0';
		
	strcpy(out_report_f, name_report);
	strcat(out_report_f, "_out_f.");
	strcat(out_report_f, report_rash);

	strcpy(out_report_s, name_report);
	strcat(out_report_s, "_out_s.");
	strcat(out_report_s, report_rash);

	strcat(name_report, "_result.");
	strcat(name_report, report_rash);

    //Определяем под какой ОС запускать скрипт
	sprintf(temp, "vmware_number_%d", num); //number section

	GetPrivateProfileString( temp, "path_to_vm", "0", temp2, 256, ".\\options.ini");
	if(!strcmp(temp2,"0")) goto exit2;
	strcpy(nameOfVM, "\0");
	strcpy(nameOfVM, temp2);
 
	strcpy(temp2, "\0");

	GetPrivateProfileString( temp, "login_in_vm", "0", loginVM, 256, ".\\options.ini");
	if(!strcmp(loginVM,"0")) log_error("login in vm machine is default (error?)");

	GetPrivateProfileString( temp, "pass_in_vm", "0", passVM, 256, ".\\options.ini");
	if(!strcmp(passVM,"0")) log_error("password in vm machine is default (error?)");

	GetPrivateProfileString( temp, "path_in_guest", "c:\\", pathInGuest, 256, ".\\options.ini");
		
	GetPrivateProfileString( temp, "program_exec_first", "0", prog_exec_f, 256, ".\\options.ini");
	if(!strcmp(prog_exec_f,"0")) goto exit2;

	exec_prior_f = GetPrivateProfileInt( temp, "exec_in_guest_priority_first", 1, ".\\options.ini");
	exec_sleep_f = GetPrivateProfileInt( temp, "exec_in_guest_sleep_first", 10, ".\\options.ini");
	exec_timelimit_f = GetPrivateProfileInt( temp, "exec_in_guest_timelimit_first", 1000, ".\\options.ini");

	GetPrivateProfileString( temp, "program_exec_second", "0", prog_exec_s, 256, ".\\options.ini");
	if(!strcmp(prog_exec_s,"0")) goto exit2;

	exec_prior_s = GetPrivateProfileInt( temp, "exec_in_guest_priority_second", 1, ".\\options.ini");
	exec_sleep_s = GetPrivateProfileInt( temp, "exec_in_guest_sleep_second", 10, ".\\options.ini");
	exec_timelimit_s = GetPrivateProfileInt( temp, "exec_in_guest_timelimit_second", 1000, ".\\options.ini");

	GetPrivateProfileString( temp, "exec_in_guest_result_name", "result.txt", result_report, 256, ".\\options.ini");

    //создаем папку чтобы, под данной ОС больше никто не запускал ничего
	int y = strlen(nameOfVM) - 1, i;
	for(;y>=0;y--) if(nameOfVM[y]=='.') break;
	for(i = 0;i<y;i++) temp2[i] = nameOfVM[i];
	temp2[y] = '\0';strcat(temp2, "_lock\0");
       
    
	WIN32_FIND_DATA st;
	FILETIME f_date;
    SYSTEMTIME s_date;
	GetSystemTime(&s_date);           
    SystemTimeToFileTime(&s_date, &f_date);
	srand((unsigned)time( NULL ));int tp = global_timeout*2;
	while(!CreateDirectory(temp2, NULL))
	{
		FindFirstFile(temp2, &st);
		GetSystemTime(&s_date);           
		SystemTimeToFileTime(&s_date, &f_date);
		if((f_date.dwLowDateTime<=st.ftCreationTime.dwLowDateTime)||((f_date.dwHighDateTime-st.ftCreationTime.dwHighDateTime)!=0))
		{
			if((f_date.dwLowDateTime/10000000+(430-st.ftCreationTime.dwLowDateTime/10000000)+(f_date.dwHighDateTime-st.ftCreationTime.dwHighDateTime-1)*430)>tp)
			{
				log_error("time limit on del directory");
				sh.hwnd   = NULL;
				sh.wFunc  = FO_DELETE;
				sh.pFrom = temp2;
				sh.pTo = NULL;
				sh.fFlags =   FOF_NOCONFIRMATION | FOF_SILENT;
				sh.hNameMappings = 0;
				sh.lpszProgressTitle = NULL;
				SHFileOperation (&sh);
			}
		}
		else
		{
			if(((f_date.dwLowDateTime-st.ftCreationTime.dwLowDateTime)/10000000)>tp)
			{
				log_error("time limit on del directory");
				sh.hwnd   = NULL;
				sh.wFunc  = FO_DELETE;
				sh.pFrom = temp2;
				sh.pTo = NULL;
				sh.fFlags =   FOF_NOCONFIRMATION | FOF_SILENT;
				sh.hNameMappings = 0;
				sh.lpszProgressTitle = NULL;
				SHFileOperation (&sh);
			}
		}
		Sleep(rand()/40);
	}
//****************************************************************************************
    //запуск потока
	DWORD dwThreadId, lpExitCode = 0; 
    HANDLE hThread;
	char error[256];

    hThread = CreateThread( NULL,0,workToVM,NULL,0,&dwThreadId);



    if (hThread == NULL) 
	{
		sprintf(error, "Bad create base thread. CreateThread failed (%d)", GetLastError()); 
		log_error(error);
		goto exit;
	}
	SetThreadPriority(hThread, priority_now);

    //код возврата потока
	do
    {
 		GetExitCodeThread(hThread,&lpExitCode);
        
		if(global_timeout<=0)
		{
			// вышло вреня работы, убить процесс и самостоятельно убирать каку ..
			TerminateThread(hThread, 0);
			log_error("Proccess has been terminate (time limit)");
			break;
		}
		Sleep(100);//global_timeout--;
	}while(lpExitCode == STILL_ACTIVE);
    //поток отработал
	CloseHandle( hThread );
    //обрабатываем код возврата
    //нормальный код возврата - 35
	if(lpExitCode==result){if(lpExitCode!=35) log_error("Поток вышел сам, по return");}
	else log_error("Поток был принудительно закрыт, видимо вышел time limit");

	switch (result)
	{
	case 0:
		log_error("Очень странное, это Вы не когда не должны были увидеть");
		break;
	case 1:
		log_error("Не смог подконектиться к vmware или получить хендл соединения");
		break;
	case 2:
		log_error("Не смог открыть соединение или получить хендл открытой машины (машина ещё не запущена)");
		break;
	case 3:
		log_error("Не можем определить power state машины");
		break;
	case 4:
		log_error("Не могу получить положительный результат от функции pVixVM_GetNumRootSnapshots");
		break;
	case 5:
		log_error("Не могу включить виртуальную машину");
		break;
	case 6:
		log_error("Пыталась сделать снимок, неполучилось");
//********************************************************************************
suspend_vm:
        //ставим на SUSPEND
		pVix_ReleaseHandle(jobHandle);
		jobHandle = pVixVM_Suspend(vmHandle,0, NULL,NULL);
		jobCompleted = FALSE;
		err = pVixJob_CheckCompletion(jobHandle, &jobCompleted);
		if (VIX_OK != err)
		{
			log_error("Пыталась сделать снимок, неполучилось (и выключиться не получилось, типа fatal error)");
			pVix_ReleaseHandle(jobHandle);
			pVix_ReleaseHandle(vmHandle);
			pVixHost_Disconnect(hostHandle);
			goto exit;
		}
		while (!jobCompleted) 
		{
			err = pVixJob_CheckCompletion(jobHandle, &jobCompleted);
			if (VIX_OK != err)
			{
				log_error("Пыталась сделать снимок, неполучилось (и выключиться не получилось, типа fatal error)");
				pVix_ReleaseHandle(vmHandle);
				pVix_ReleaseHandle(hostHandle);
				goto exit;
			}
			Sleep(200);
		}   
		pVix_ReleaseHandle(jobHandle);

		powerState = 0; // !!!
		while (VIX_POWERSTATE_SUSPENDED != powerState) 
		{
			err = pVix_GetProperties(vmHandle,VIX_PROPERTY_VM_POWER_STATE,&powerState,VIX_PROPERTY_NONE);
			if (VIX_OK != err) 
			{
				log_error("Пыталась сделать снимок, неполучилось (и статус выключения не подтвердился, типа fatal error)");
				pVix_ReleaseHandle(jobHandle);
				pVix_ReleaseHandle(vmHandle);
				pVixHost_Disconnect(hostHandle);
				goto exit;
			}
			Sleep(200);
		}
		pVix_ReleaseHandle(jobHandle);
		pVix_ReleaseHandle(vmHandle);
		pVixHost_Disconnect(hostHandle);
//*****************************************************************************
		break;
	case 7:
		log_error("Застрял на функции pVixVM_WaitForToolsInGuest");
		goto suspend_vm;
	case 8:
		log_error("Функция pVixVM_WaitForToolsInGuest завершилась неудачей");
//*****************************************************************************
snapshot_vm:
		pVix_ReleaseHandle(jobHandle);
		err = pVixVM_GetRootSnapshot(vmHandle, 0, &snapshotHandle);
		if (VIX_OK != err) 
		{
			log_error("Функция pVixVM_WaitForToolsInGuest завершилась неудачей (не смог получить хендл снимка, идем на приостановку)");
			goto suspend_vm;
		}
		pVix_ReleaseHandle(jobHandle);
	    jobHandle = pVixVM_RevertToSnapshot(vmHandle, snapshotHandle,0,VIX_INVALID_HANDLE,NULL,NULL);

		jobCompleted = FALSE;
		err = pVixJob_CheckCompletion(jobHandle, &jobCompleted);
		if (VIX_OK != err)
		{
			log_error("Функция pVixVM_WaitForToolsInGuest завершилась неудачей (не смог завершить функцию pVixVM_RevertToSnapshot, идем на приостановку)");
			goto suspend_vm;
		}
		while (!jobCompleted) 
		{
			err = pVixJob_CheckCompletion(jobHandle, &jobCompleted);
			if (VIX_OK != err)
			{
				log_error("Функция pVixVM_WaitForToolsInGuest завершилась неудачей (не смог завершить функцию pVixVM_RevertToSnapshot, идем на приостановку)");
				goto suspend_vm;
			}
			Sleep(200);
		}  
		pVix_ReleaseHandle(jobHandle);		
		goto suspend_vm;
		
//*****************************************************************************
	case 9:
		log_error("Застрял на функции pVixVM_LoginInGuest");
		goto snapshot_vm;
	case 10:
		log_error("Функция pVixVM_LoginInGuest завершилась неудачей");
		goto snapshot_vm;
	case 11:
		log_error("Застрял на функции pVixVM_CopyFileFromHostToGuest (1)");
		goto snapshot_vm;
	case 12:
		log_error("Функция pVixVM_CopyFileFromHostToGuest (1) завершилась неудачей");
		goto snapshot_vm;
	case 13:
		log_error("Застрял на функции pVixVM_CopyFileFromHostToGuest (2)");
		goto snapshot_vm;
	case 14:
		log_error("Функция pVixVM_CopyFileFromHostToGuest (2) завершилась неудачей");
		goto snapshot_vm;
	case 15:
		log_error("Застрял на функции pVixVM_RunProgramInGuest (1)");
		goto snapshot_vm;
	case 16:
		log_error("Функция pVixVM_RunProgramInGuest (1) завершилась неудачей");
		goto snapshot_vm;
	case 17:
		log_error("Застрял на функции pVixVM_CopyFileFromHostToGuest (3)");
		goto snapshot_vm;
	case 18:
		log_error("Функция pVixVM_CopyFileFromHostToGuest (3) завершилась неудачей");
		goto snapshot_vm;
	case 19:
		log_error("Застрял на функции pVixVM_CopyFileFromHostToGuest (4)");
		goto snapshot_vm;
	case 20:
		log_error("Функция pVixVM_CopyFileFromHostToGuest (4) завершилась неудачей");
		goto snapshot_vm;
	case 21:
		log_error("Застрял на функции pVixVM_RunProgramInGuest (2)");
		goto snapshot_vm;
	case 22:
		log_error("Функция pVixVM_RunProgramInGuest (2) завершилась неудачей");
		goto snapshot_vm;
	case 23:
		log_error("Застрял на функции pVixVM_CopyFileFromGuestToHost (1 - 5)");
		goto snapshot_vm;
	case 24:
		log_error("Функция pVixVM_RunProgramInGuest (1 - 5) завершилась неудачей");
		goto snapshot_vm;
	case 25:
		log_error("Застрял на функции pVixVM_CopyFileFromGuestToHost (2 - 6)");
		goto snapshot_vm;
	case 26:
		log_error("Функция pVixVM_RunProgramInGuest (2 - 6) завершилась неудачей");
		goto snapshot_vm;
	case 27:
		log_error("Застрял на функции pVixVM_CopyFileFromGuestToHost (3 - 7)");
		goto snapshot_vm;
	case 28:
		log_error("Функция pVixVM_RunProgramInGuest (3 - 7) завершилась неудачей");
		goto snapshot_vm;
	case 29:
		log_error("Не смог получить хендл снимка для востановления (черт)");
		goto suspend_vm;
	case 30:
		log_error("Застрял на функции pVixVM_RevertToSnapshot");
		goto suspend_vm;
	case 31:
		log_error("Функция pVixVM_RevertToSnapshot завершилась неудачей");
		goto suspend_vm;
	case 32:
		log_error("Застрял на функции pVixVM_Suspend");
		goto suspend_vm;
	case 33:
		log_error("Функция pVixVM_Suspend завершилась неудачей");
//**********************************************************************
power_off:
		pVix_ReleaseHandle(jobHandle);
		jobHandle = pVixVM_PowerOff(vmHandle,VIX_VMPOWEROP_NORMAL,NULL,NULL);
		jobCompleted = FALSE;
		err = pVixJob_CheckCompletion(jobHandle, &jobCompleted);
		if (VIX_OK != err)
		{
			log_error("Функция pVixVM_Suspend завершилась неудачей, (и power off завершился не удачей)");
			goto exit;
		}
		while (!jobCompleted) 
		{
			err = pVixJob_CheckCompletion(jobHandle, &jobCompleted);
			if (VIX_OK != err)
			{
				log_error("Функция pVixVM_Suspend завершилась неудачей, (и power off завершился не удачей)");
				goto exit;
			}
			Sleep(200);
		}  
		pVix_ReleaseHandle(jobHandle);
		pVix_ReleaseHandle(vmHandle);
		pVixHost_Disconnect(hostHandle);
//**********************************************************************
		break;
	case 34:
		log_error("Уже ждали когда машина встанет на приостановку, а функция завершилась не удачно");
		goto power_off;
	case 35:
		break;
		// good, 
	default:
		log_error("Вроде и не ошибка, но не должно быть такого");
		break;
	}

//*******************************************************************************************
//Если все хорошо (код возврата 35)
	if(lpExitCode==35)
	{
        FILE* file;char f_tmp[256];
        if((file = fopen(out_report_f, "rt")) == NULL)
        {
            log_error("Нет выходного файла, может не получил из VM, странно");
            goto exit;
        }
       	int v = GetPrivateProfileInt( "result_second", "exit_code", 1, name_report);

        printf("%d\n%s\n", v, out_report_s);
char tr[256];
strcpy(tr, "\0");
            fgets(f_tmp, 256, file);

        while (!feof(file))
        {
            OemToChar(f_tmp, tr);
            printf("%s", tr);
            strcpy(tr, "\0");
            fgets(f_tmp, 256, file);
        }
        fclose(file);
    }
exit:
	sh.hwnd   = NULL;
	sh.wFunc  = FO_DELETE;
	sh.pFrom = temp2;
	sh.pTo = NULL;
	sh.fFlags =   FOF_NOCONFIRMATION | FOF_SILENT;
	sh.hNameMappings = 0;
	sh.lpszProgressTitle = NULL;
	SHFileOperation (&sh);

    sh.hwnd   = NULL;
	sh.wFunc  = FO_DELETE;
	sh.pFrom = name_report;
	sh.pTo = NULL;
	sh.fFlags =   FOF_NOCONFIRMATION | FOF_SILENT;
	sh.hNameMappings = 0;
	sh.lpszProgressTitle = NULL;
	SHFileOperation (&sh);

    sh.hwnd   = NULL;
	sh.wFunc  = FO_DELETE;
	sh.pFrom = out_report_f;
	sh.pTo = NULL;
	sh.fFlags =   FOF_NOCONFIRMATION | FOF_SILENT;
	sh.hNameMappings = 0;
	sh.lpszProgressTitle = NULL;
	SHFileOperation (&sh);

    sh.hwnd   = NULL;
	sh.wFunc  = FO_DELETE;
	sh.pFrom = good_fileToVM;
	sh.pTo = NULL;
	sh.fFlags =   FOF_NOCONFIRMATION | FOF_SILENT;
	sh.hNameMappings = 0;
	sh.lpszProgressTitle = NULL;
	SHFileOperation (&sh);
exit2:
	if(!flag)
    {
        log_error("end error logs\r\n---------------");
    	return 1;
    }
    return 0;
}






