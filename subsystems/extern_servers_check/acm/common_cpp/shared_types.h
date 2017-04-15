
#ifndef shared_typesH
#define shared_typesH


struct TSubmited{
   int id_sbm; //код учасника
   int id_publ; //публичный код учасника
   int id_prb; //код задачи
   int warn_rsl; //возможный результат (используется анализом плагиата)
   short id_cmp; //код компилятора
   unsigned long idProcess; //идентификатор процесса пославшего сообщение
   unsigned long ShareMem; //адре общей памяти в процессе пославшем сообщение
   int id_stat; //уникальный идентификатор строки статуса
   double time; //время в секундах
   unsigned int mem; //память в килобайтах
   float min_uniq_proc; //минимальный процент уникальности при которм решение все еще верно (если меньше то UNIQUE_ERROR)
   float cur_uniq_proc; //текущий процент уникальности
   int cmp_id_stat; //статус решения на которое максимально похоже текущее
   char *SrcSolve; //текст задачи
   int   SrcSolveSize; //размер текста задачи
   short debug_protect;  //отладка белого списка
};


//элемент стека
struct Telement{
   void* ptr; //указатель на неопределенный тип
};

/* стек классический */
class Tstek
{
   int stcount; //количество элементов стека
   int max_elm; //максимальное кол-во элементов в стеке
   Telement *st; //указатель на первый элемент динамического массива

   public:
      //инициализация
      void init(void) {stcount=-1;}
      
      //проверка на пустоту
      bool empty(void) const {if (stcount==-1) return true; return false;}
      
      //конструктор n-максимальный размер стека
      Tstek(int n) {init(); max_elm=n; st=new Telement[n];}
      
      //положить элемент на вершину стека
      void push(void* ptr) {if (stcount<max_elm-1) st[++stcount].ptr=ptr;}
      
      //извлечь элемент с вершины стека
      void pop(void** ptr) {if (stcount>=0) *ptr=st[stcount--].ptr; else *ptr=NULL;}
      
      //вернуть элемент с вершины стека без извлечения
      void* ptr(void) const {return st[stcount].ptr;}
      
      //дестректор
      ~Tstek(void) {delete[] st;}
      
      //количество элементов в стеке
      int Size(void) const {return stcount+1;}
};


#endif