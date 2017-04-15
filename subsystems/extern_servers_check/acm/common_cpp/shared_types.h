
#ifndef shared_typesH
#define shared_typesH


struct TSubmited{
   int id_sbm; //��� ��������
   int id_publ; //��������� ��� ��������
   int id_prb; //��� ������
   int warn_rsl; //��������� ��������� (������������ �������� ��������)
   short id_cmp; //��� �����������
   unsigned long idProcess; //������������� �������� ���������� ���������
   unsigned long ShareMem; //���� ����� ������ � �������� ��������� ���������
   int id_stat; //���������� ������������� ������ �������
   double time; //����� � ��������
   unsigned int mem; //������ � ����������
   float min_uniq_proc; //����������� ������� ������������ ��� ������ ������� ��� ��� ����� (���� ������ �� UNIQUE_ERROR)
   float cur_uniq_proc; //������� ������� ������������
   int cmp_id_stat; //������ ������� �� ������� ����������� ������ �������
   char *SrcSolve; //����� ������
   int   SrcSolveSize; //������ ������ ������
   short debug_protect;  //������� ������ ������
};


//������� �����
struct Telement{
   void* ptr; //��������� �� �������������� ���
};

/* ���� ������������ */
class Tstek
{
   int stcount; //���������� ��������� �����
   int max_elm; //������������ ���-�� ��������� � �����
   Telement *st; //��������� �� ������ ������� ������������� �������

   public:
      //�������������
      void init(void) {stcount=-1;}
      
      //�������� �� �������
      bool empty(void) const {if (stcount==-1) return true; return false;}
      
      //����������� n-������������ ������ �����
      Tstek(int n) {init(); max_elm=n; st=new Telement[n];}
      
      //�������� ������� �� ������� �����
      void push(void* ptr) {if (stcount<max_elm-1) st[++stcount].ptr=ptr;}
      
      //������� ������� � ������� �����
      void pop(void** ptr) {if (stcount>=0) *ptr=st[stcount--].ptr; else *ptr=NULL;}
      
      //������� ������� � ������� ����� ��� ����������
      void* ptr(void) const {return st[stcount].ptr;}
      
      //����������
      ~Tstek(void) {delete[] st;}
      
      //���������� ��������� � �����
      int Size(void) const {return stcount+1;}
};


#endif