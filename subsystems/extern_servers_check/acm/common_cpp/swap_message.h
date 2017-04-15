
#ifndef SWAP_MESSAGE_H
#define SWAP_MESSAGE_H

#include <windows.h>

//процессы будут обмениваться такими сообщениями
struct MessageBlok{
   unsigned int MessageNum,Param1,Param2;
};

class TMessageBuff {

private:
   MessageBlok ShareMem,Buff;
   HANDLE mutex,event_empty,event_full;

public:
   TMessageBuff();
   ~TMessageBuff();
   void GetNewMessage();
   unsigned int MessageNum() { return Buff.MessageNum; }
   unsigned int Param1() { return Buff.Param1; }
   unsigned int Param2() { return Buff.Param2; }
   unsigned int AddressMem() { return (unsigned int)&ShareMem; }
};

extern int SendDataOut(int pid, int address, MessageBlok &buff);

#endif