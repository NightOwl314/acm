

#include <fstream>
#include <windows.h>

using namespace std;

//процессы будут обмениваться такими сообщениями
struct MessageBuff {
   unsigned int MessageNum,Param1,Param2;
};

ofstream d;

void sw(int a, char *b)
{
   char fn[80];
   sprintf(fn,"d:\\cpp_xxx\\mega_log%d.txt",GetTickCount());
   d.open(fn,ios::out | ios::app);
   d << GetCurrentProcessId() << " " << a << " " << b << "\n";
   d.close();
   Sleep(50);
}


//посылает данные другому процессу
//работает по классическому алгоритму Дейкстры
int SendDataOut(int pid, int address, MessageBuff &buff)
{
   int err=0;
   //имена мьютексов и эвентов формируются на основе pid процесса
   char mutexname[50],eventname_empty[50],eventname_full[50];
   sprintf(mutexname,"TESTINGSYSTEM_%d_mutex",pid);
   sprintf(eventname_empty,"TESTINGSYSTEM_%d_event_empty",pid);
   sprintf(eventname_full,"TESTINGSYSTEM_%d_event_full",pid);

   HANDLE arr[2];
   HANDLE hProcess; //ручка на внешний процесс
   DWORD wn;
   HANDLE mutex=CreateMutex(NULL, FALSE, mutexname);
   //HANDLE mutex=CreateSemaphore(NULL, 0, 50, mutexname);

   //ручка на сигнал пуст
   HANDLE event_empty=CreateEvent(NULL, TRUE, FALSE, eventname_empty);

   //ручка на сигнал полон
   HANDLE event_full=CreateEvent(NULL, TRUE, FALSE, eventname_full);

   //sw(pid,"SEND WaitForSingleObject(mutex,INFINITE)==WAIT_OBJECT_0");
   if (WaitForSingleObject(mutex,INFINITE)==WAIT_OBJECT_0) { //занять мьютекс
      //sw(pid,"SEND WaitForSingleObject(event_full,50)==WAIT_OBJECT_0");
      if (WaitForSingleObject(event_full,50)==WAIT_OBJECT_0) { //если полон
         //sw(pid,"SEND ReleaseMutex(mutex)");
         ReleaseMutex(mutex);
         /*
         sw(pid,"SEND WaitForSingleObject(event_empty,INFINITE)");
         WaitForSingleObject(event_empty,INFINITE);
         sw(pid,"SEND WaitForSingleObject(mutex,INFINITE)");
         WaitForSingleObject(mutex,INFINITE);
         */

         //sw(pid,"SEND WaitForMultipleObjects(2,arr,{event_empty, mutex},INFINITE)");
         arr[0]=event_empty;
         arr[1]=mutex;
         WaitForMultipleObjects(2,arr,TRUE,INFINITE);
      }
      //sw(pid,"SEND OpenProcess...");
      //открыть процесс с нужным доступом
      hProcess=OpenProcess(PROCESS_VM_WRITE|PROCESS_VM_OPERATION, FALSE, pid);
      if (hProcess) {
         WriteProcessMemory(hProcess, (void *)address, &buff, sizeof(MessageBuff), &wn);
         CloseHandle(hProcess);
      } else err=1;

      //sw(pid,"SEND ResetEvent(event_empty)");
      ResetEvent(event_empty);
      //sw(pid,"SEND SetEvent(event_full)");
      SetEvent(event_full);
      //sw(pid,"SEND ReleaseMutex(mutex)");
      ReleaseMutex(mutex);
   }
   CloseHandle(mutex);
   CloseHandle(event_empty);
   CloseHandle(event_full);
   return err;
}

HANDLE in_mutex,in_event_empty,in_event_full;

//принимает данные записанные другим процессом
//работает по классическому алгоритму Дейкстры
void GetDataThis(int address, MessageBuff &buff)
{

   if (!address) {
      int pid=GetCurrentProcessId();

      //имена мьютексов и эвентов формируются на основе pid процесса
      char mutexname[50],eventname_empty[50],eventname_full[50];
      sprintf(mutexname,"TESTINGSYSTEM_%d_mutex",pid);
      sprintf(eventname_empty,"TESTINGSYSTEM_%d_event_empty",pid);
      sprintf(eventname_full,"TESTINGSYSTEM_%d_event_full",pid);

      in_mutex=CreateMutex(NULL, FALSE, mutexname);

      //ручка на сигнал пуст
      in_event_empty=CreateEvent(NULL, TRUE, FALSE, eventname_empty);

      //ручка на сигнал полон
      in_event_full=CreateEvent(NULL, TRUE, FALSE, eventname_full);
      return;
   }

   //sw(0,"GET WaitForSingleObject(event_full,INFINITE)");
   WaitForSingleObject(in_event_full,INFINITE);
   //sw(0,"GET WaitForSingleObject(mutex,INFINITE)==WAIT_OBJECT_0");
   if (WaitForSingleObject(in_mutex,INFINITE)==WAIT_OBJECT_0) { //занять мьютекс
   /*
      if (WaitForSingleObject(event_empty,50)==WAIT_OBJECT_0) { //если пуст
         ReleaseMutex(mutex);
         WaitForSingleObject(event_full,INFINITE);
         WaitForSingleObject(mutex,INFINITE);
      }
    */
      //sw(0,"GET memmove");
      memmove(&buff,(void *)address,sizeof(MessageBuff)); //читаем


      //sw(0,"GET ResetEvent(event_full)");
      ResetEvent(in_event_full); //сбрасываем полон
      //sw(0,"GET SetEvent(event_empty)");
      SetEvent(in_event_empty);  //сигналим пуст

      //sw(0,"GET ReleaseMutex(mutex)");
      ReleaseMutex(in_mutex); //освобождаем мьютекс
   }

   //CloseHandle(mutex);
   //CloseHandle(event_empty);
   //CloseHandle(event_full);
}

/*
void StartEmptyBuff()
{
   int pid=GetCurrentProcessId();

   char eventname_empty[50];
   sprintf(eventname_empty,"TESTINGSYSTEM_%d_event_empty",pid);
   HANDLE event_empty=CreateEvent(NULL, TRUE, FALSE, eventname_empty);
   SetEvent(event_empty);
   CloseHandle(event_empty);
}
*/

