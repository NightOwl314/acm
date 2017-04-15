#ifndef db_funcH
#define db_funcH

#include "ibase.h"
#include "..\common_cpp\shared_types.h"
#include "readconfig.h"


#define EVN_NEW_TEST 1
#define EVN_STOP_SRV 2


class TDataBase {
   private:
      isc_db_handle db; //контекст базы данных
      isc_stmt_handle stmt;  //контекст запроса к БД
      //контекст транзакции блокирующей запись данного сервера
      isc_tr_handle lock_this_srv;

      long status[20]; //состояние БД после выполнения какай-либо команды

      //буферы событий
      char *event_buffer, *result_buffer;
      long event_blength; //длина каждого буфера
      int event_count; //количество отслеживаемых событий
      int id_srv; //идентификатор данного сервера
      DWORD start_time; //отметка начала проверки

      void print_error(char *s = "none"); //вывод ошибки в лог-файл
      int save_err(int err); //проверка и сохранение ошибки
      void register_events(void); //регистрация на получение событий от БД
      //добавляет запись в БД соответствующую текущему серверу
      void add_server(void);

   public:
      TDataBase(){  db=NULL; stmt=NULL;  };
      ~TDataBase(){  if (db!=NULL) Disconnect();  };

      //соединение с БД
      int Connect(char *file, char *username, char *password);
      int Disconnect(); //разорвать соединение с БД
      //получить уникальный идентификатор данного сервера
      int get_id(void) {return id_srv;}

      int SqlExecute(char *query, isc_tr_handle trans=NULL);
      int GetGenLast(const char *name_gen, int *id, isc_tr_handle trans=NULL, int is_select=0);
      int wait_events(void);

      //функции для работы с транзакциями
      isc_tr_handle start_trans(int type=0);
      void commit_trans(isc_tr_handle trans);
      void rollback_trans(isc_tr_handle trans);

      int UpdateStatus(int id_stat, int id_rsl, isc_tr_handle *trans_lock);
      int SelectDataSubmit(TSubmited *e, isc_tr_handle trans=NULL);
      BOOL TestingBestSolve(TSubmited *e, int *old_author,
                            int *id_slv,isc_tr_handle trans=NULL);
      int UpdateBestSolve(TSubmited *e, char* bf, int len, int old_author,
                          int id_slv, isc_tr_handle trans=NULL);
      void StartTesting(void);
      void FinishTesting(void);
      int SaveReports(int id_stat, int id_rsl, TPaths *pt, isc_tr_handle trans=NULL);
      int SaveObjFile(int id_stat, char *obj_file, isc_tr_handle trans=NULL);
      int TestPlagiat(int id_stat, char *obj_file, float min_uniq_proc,
                      char *otch , int *again_plagiat, isc_tr_handle trans=NULL);
};

#endif