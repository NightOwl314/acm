

#include <fstream>
#include <cstdio>
#include "..\common_cpp\swap_message.h"

using namespace std;

TMessageBuff::TMessageBuff()
{
   int pid=GetCurrentProcessId();

   //имена мьютексов и эвентов формируются на основе pid процесса
   char mutexname[50],eventname_empty[50],eventname_full[50];
   sprintf(mutexname,"TESTINGSYSTEM_%d_mutex",pid);
   sprintf(eventname_empty,"TESTINGSYSTEM_%d_event_empty",pid);
   sprintf(eventname_full,"TESTINGSYSTEM_%d_event_full",pid);

   mutex=CreateMutex(NULL, FALSE, mutexname);

   //ручка на сигнал пуст (ручной сброс, активизирован при создании)
   event_empty=CreateEvent(NULL, TRUE, TRUE, eventname_empty);

   //ручка на сигнал полон (ручной сброс, неактивизирован при создании)
   event_full=CreateEvent(NULL, TRUE, FALSE, eventname_full);
}

TMessageBuff::~TMessageBuff()
{
   CloseHandle(mutex);
   CloseHandle(event_empty);
   CloseHandle(event_full);
}

void TMessageBuff::GetNewMessage()
{
   WaitForSingleObject(event_full,INFINITE);
   if (WaitForSingleObject(mutex,INFINITE)==WAIT_OBJECT_0) { //занять мьютекс
/*
      if (WaitForSingleObject(event_empty,50)==WAIT_OBJECT_0) { //если пуст
         ReleaseMutex(mutex);
         WaitForSingleObject(event_full,INFINITE);
         WaitForSingleObject(mutex,INFINITE);
      }
*/
      memmove(&Buff,&ShareMem,sizeof(MessageBlok)); //читаем

      ResetEvent(event_full); //сбрасываем полон
      SetEvent(event_empty);  //сигналим пуст

      ReleaseMutex(mutex); //освобождаем мьютекс
   }
}


//посылает данные другому процессу
//работает по классическому алгоритму Дейкстры
int SendDataOut(int pid, int address, MessageBlok &buff)
{
   int er=0;
   //имена мьютексов и эвентов формируются на основе pid процесса
   char mutexname[50],eventname_empty[50],eventname_full[50];
   sprintf(mutexname,"TESTINGSYSTEM_%d_mutex",pid);
   sprintf(eventname_empty,"TESTINGSYSTEM_%d_event_empty",pid);
   sprintf(eventname_full,"TESTINGSYSTEM_%d_event_full",pid);

   HANDLE arr[2];
   HANDLE hProcess; //ручка на внешний процесс
   DWORD wn;
   HANDLE mutex=CreateMutex(NULL, FALSE, mutexname);

   //ручка на сигнал пуст
   HANDLE event_empty=CreateEvent(NULL, TRUE, FALSE, eventname_empty);

   //ручка на сигнал полон
   HANDLE event_full=CreateEvent(NULL, TRUE, FALSE, eventname_full);

   if (WaitForSingleObject(mutex,INFINITE)==WAIT_OBJECT_0) { //занять мьютекс
      if (WaitForSingleObject(event_full,50)==WAIT_OBJECT_0) { //если полон
         ReleaseMutex(mutex);
         //WaitForSingleObject(event_empty,INFINITE);
         //WaitForSingleObject(mutex,INFINITE);

         arr[0]=event_empty;
         arr[1]=mutex;
         WaitForMultipleObjects(2,arr,TRUE,INFINITE);
      }

      //открыть процесс с нужным доступом
      hProcess=OpenProcess(PROCESS_VM_WRITE|PROCESS_VM_OPERATION, FALSE, pid);
      if (hProcess) {
         WriteProcessMemory(hProcess, (void *)address, &buff, sizeof(MessageBlok), &wn);
         CloseHandle(hProcess);
      } else er=1;

      ResetEvent(event_empty);
      SetEvent(event_full);
      ReleaseMutex(mutex);
   }
   CloseHandle(mutex);
   CloseHandle(event_empty);
   CloseHandle(event_full);

   return er;
}

