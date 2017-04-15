
#ifndef unit1H
#define unit1H

//---------------------------------------------------------------------------

void SwapFunction(DWORD adr_new_f, DWORD adr_old_f);
void SwapAllFunctions(HMODULE pimage);
HMODULE ModuleFromAddress(PVOID pv);
void SwapAllModules(void);
void SaveStatusFunc(int bl);
void UseWhiteList(void);

extern "C" VOID WINAPI Intercept_ExitProc(UINT uExitCode);
extern "C" VOID WINAPI Security_violation(DWORD xxx);
extern "C" HINSTANCE WINAPI Intercept_LoadLibraryExA(LPCTSTR  lpLibFileName, HANDLE  hFile,  DWORD  dwFlags );
extern "C" HINSTANCE WINAPI Intercept_LoadLibraryExW(LPCTSTR  lpLibFileName, HANDLE  hFile,  DWORD  dwFlags );
extern "C" HINSTANCE WINAPI Intercept_LoadLibraryA(LPCTSTR  lpLibFileName);
extern "C" HINSTANCE WINAPI Intercept_LoadLibraryW(LPCTSTR  lpLibFileName);

extern "C" int APIENTRY WINAPI DllMain(HANDLE hModule, DWORD  ul_reason_for_call,
                      LPVOID lpReserved);

/*
mov ecx,dword ptr [adr_cnt]
cmp ecx,0
jnz xxx:
push [adr_src_func]
call Security_violation
xxx:
dec dword ptr [adr_cnt]
pop ecx
mov [adr_buff],ecx
call adr_src_func
push [adr_buff]
ret
*/
//��������� ��������� ����, � ������� ���������� ���
//����������� ����������� �������
struct TCodeForAll
{
  WORD  instr_mov1; //=0x0D8B
  DWORD adr_cnt1;

  WORD  instr_cmp; //=0xF983
  BYTE  arg_cmp; //=0

  WORD  instr_jnz; //=0x0B75

  BYTE  instr_push1; //=0x68
  DWORD sec_voil_code;

  WORD  instr_call1; //=0x15FF
  DWORD adr_exit_func;

  WORD  instr_dec; //=0x0DFF
  DWORD adr_cnt2;

  BYTE  instr_popecx; //=0x59

  WORD instr_mov2; //=0x0D89
  DWORD adr_buff1;

  WORD  instr_call2; //=0x15FF
  DWORD adr_src_func;

  WORD  instr_push2; //=0x35FF
  DWORD adr_buff2;

  BYTE  instr_ret; //=0xC3
};

//������ ������� DLL
//������������� � ���� ������(���������� �� �������� ��� �������� ������)
struct TList{
   char *name; //�������� �������
   int callcnt; //���������� ����������� �������
                //(����������� �� 1 ��� ������ ������ ������ �������)

   int callcnt1; //�������� �������� (� ������ ����� ����������
                 //����������� ������� �� ������ ������,
                 //� ����� ����� ���������� ���������� �������)

   int callcnt_start; //������ �������� ���������� ������� ��� � ����� ������

   char *dll_name; //�������� DLL (������ �� ���������� ��� ������� �� ����� DLL
                   //��������� �� ���� � ����� �����)
                   
   DWORD adrcall; //����� ���� ������������ �������
   DWORD buff; //����� �������� ����� �������� �� ������� ��������
               //���������� ��� ���������� ������ ������������ �������
               //� ����������� � �����

   TCodeForAll CFA; //��� ������� ��������

   TList *left; //��������� �� ������ �������
   TList *right; //��������� �� ������� �������
};

//��������� ������������ ����������
struct TDll{
   char *name; //��������
   TList *root;  //������ �������
};

//���������� ��� ��������� ������������� ������(������� ���� ������������� �������)
// ��� �������� ���� ���������� � �������� ������������ ������������ ��������
struct TStartThisDll
{
   TStartThisDll(void);
};

#endif
