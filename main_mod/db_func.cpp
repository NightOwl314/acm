#define _CRT_SECURE_NO_DEPRECATE

#include <windows.h>
#include <cstdio>
#include <fstream>
#include "ibase.h"
#include "db_func.h"
#include "..\common_cpp\result_id.h"
#include "main_mod.h"
//#include "com_substr_cnt.h"
#include "max_substr.h"
#include "testing.h"

using namespace std;

//соединение с существующей базой данных
int TDataBase::Connect(char *file, char *username, char *password)
{
   char ISC_FAR   *dpb, *copy;
   short           dpb_length=0;
   int rs=0;

   //выделим память и укажем обезательный первый байт в буфере параметров
   copy=dpb=new char[7];
   dpb[0]=isc_dpb_version1;
   dpb_length=1;

   //укажем пользователя и пароль
   isc_expand_dpb(&dpb, (short ISC_FAR *) &dpb_length,
                  isc_dpb_user_name, username,
                  isc_dpb_password, password,  NULL);

   delete[] copy;

   //соединение с БД, указатель на БД 4й параметр
   if (save_err(isc_attach_database(status, 0, file, &db, dpb_length, dpb)))
      rs=-1;

   //выделим памяти на сервере
   if (rs || save_err(isc_dsql_allocate_statement(status, &db, &stmt)))
      rs=-1;

   add_server();
   register_events();

   return rs;
}

int TDataBase::wait_events(void)
{
   unsigned long evn_arr[20];
   save_err(isc_wait_for_event(status, &db, (short)event_blength,event_buffer, result_buffer));
   isc_event_counts(evn_arr, (short)event_blength, event_buffer,result_buffer);

   int bit_event=0;
   for (int i=0;i<event_count;i++)
      if (evn_arr[i])
         bit_event|=(1<<i);

   return bit_event;
}


void TDataBase::register_events(void)
{
   char s[50];

   event_count=2;
   sprintf(s,"stop_%-10d",id_srv);

   event_blength=isc_event_block(&event_buffer, &result_buffer,
      (unsigned short)event_count, "new_test_solve",s,0);

   wait_events();
}

void TDataBase::add_server(void)
{
   char query[300],s_name[80];
   DWORD sz=80,p_mask,s_mask,x;
   isc_tr_handle trans;

   GetProcessAffinityMask(GetCurrentProcess(),&p_mask,&s_mask);
   x=p_mask;
   p_mask=0;
   while (x) {
      x>>=1;
      p_mask++;
   }
   GetComputerName(s_name,&sz);
   sprintf(query,"insert into test_servers(pid,host_name,processor_num) values(%d,'%s',%d)",
                 GetCurrentProcessId(),s_name,p_mask);
   trans=start_trans(1);
   SqlExecute(query,trans);
   //GetGenLast("TEST_SERVERS_GEN",&id_srv,trans,1);
   GetGenLast("select max(id_srv) from test_servers",&id_srv,trans,1);
   commit_trans(trans);

   lock_this_srv=start_trans();
   sprintf(query,"update lock_servers set test=1 where id_srv=%d",id_srv);
   SqlExecute(query,lock_this_srv);  

}

int TDataBase::Disconnect(void)
{
   char query[300];

   //удалим блокированную запись
   sprintf(query,"delete from lock_servers where id_srv=%d",id_srv);
   SqlExecute(query,lock_this_srv);
   commit_trans(lock_this_srv);

   //удалим запись в таблице серверов
   sprintf(query,"delete from test_servers where id_srv=%d",id_srv);
   SqlExecute(query);

   //освободим память на сервере
   save_err(isc_dsql_free_statement(status, &stmt, DSQL_drop));
   stmt=NULL;

   //разрываем соединение
   save_err(isc_detach_database (status, &db));
   db=NULL;

   return 0;
}

//выполнить запрос без возвращаемых данных
int TDataBase::SqlExecute(char *query, isc_tr_handle trans, int hide_err)
{
   int rs=0,tr_nl=(trans==NULL);

   //начало транзакции
   if (tr_nl) trans=start_trans();

   //выполнение SQl запроса
   if (/*save_err*/(isc_dsql_execute_immediate(status, &db, &trans, 0, query, SQL_DIALECT_V6, NULL))) {
        rs=-1;
        if (!hide_err) print_error(query);
   }

   //завершение транзакции
   if (tr_nl) commit_trans(trans);
   return rs;
}

//создает новую транзакцию
isc_tr_handle TDataBase::start_trans(int type)
{
   isc_tr_handle trans=NULL;

   //тип транзакции 0 - по умолчанию
   //изменения могут быть сохранены, только когда закрыты
   //все остальные транзакции изменявшие эту запись
   static char isc_tpb0[] =
     { isc_tpb_version3,
       isc_tpb_read_committed,
       isc_tpb_rec_version,
       isc_tpb_nowait
     };

   //тип транзакции 1 (snapshot)
   //если запись была изменена с момента старта транзакции,
   //то эта транзакция не сможет ее изменить
   static char isc_tpb1[] =
     { isc_tpb_version3,
       isc_tpb_concurrency,
       isc_tpb_nowait
     };

   //тип транзакции 2
   //тоже что и тип 0 только ждет других
   static char isc_tpb2[] =
     { isc_tpb_version3,
       isc_tpb_read_committed,
       isc_tpb_rec_version,
       isc_tpb_wait
     };

   char *isc_tpb;
   unsigned short isc_tpb_size;
   if (type==1) {
      isc_tpb=isc_tpb1;
      isc_tpb_size=sizeof(isc_tpb1);
   } else if (type==2) {
      isc_tpb=isc_tpb2;
      isc_tpb_size=sizeof(isc_tpb2);
   } else {
      isc_tpb=isc_tpb0;
      isc_tpb_size=sizeof(isc_tpb0);
   }

   save_err(isc_start_transaction(status, &trans, 1, &db,
      isc_tpb_size, isc_tpb));

   return trans;
}

void TDataBase::commit_trans(isc_tr_handle trans)
{
   save_err(isc_commit_transaction(status, &trans));
}

void TDataBase::rollback_trans(isc_tr_handle trans)
{
   save_err(isc_rollback_transaction(status, &trans));
}

//получить значение генератора
int TDataBase::GetGenLast(const char *name_gen, int *id, isc_tr_handle trans, int is_select)
{
   char            selstr[200];
   long            result[2];
   short           flag0 = 0;
   XSQLDA ISC_FAR     *sqlda;
   long            fetch_stat;
   int rs=0,tr_nl=(trans==NULL);

   if (is_select) {
      strcpy(selstr,name_gen);
   } else {
      strcpy(selstr,"select gen_id(");
      strcat(selstr,name_gen);
      strcat(selstr,",0) from rdb$database");
   }

   sqlda = (XSQLDA ISC_FAR *) malloc(XSQLDA_LENGTH(1));

   sqlda->sqln = 1; //принимаем 1 поле
   sqlda->version = 1;

   if (tr_nl) save_err(isc_start_transaction(status, &trans, 1, &db, 0, NULL));

   if (save_err(isc_dsql_prepare(status, &trans, &stmt, 0, selstr, SQL_DIALECT_V6, sqlda)))
       rs=-1;

   sqlda->sqlvar[0].sqldata = (char ISC_FAR *)result;// id;
   sqlda->sqlvar[0].sqlind  = (short ISC_FAR *)&flag0;
   sqlda->sqlvar[0].sqltype = SQL_INT64 + 1;

   if (save_err(isc_dsql_execute(status, &trans, &stmt, SQL_DIALECT_V6, NULL)))
       rs=-1;

   fetch_stat=isc_dsql_fetch(status, &stmt, SQL_DIALECT_V6, sqlda);
   if (fetch_stat != 0)
       rs=-1;

   if (save_err(isc_dsql_free_statement(status, &stmt, DSQL_close)))
      rs=-1;

   if (tr_nl) save_err(isc_commit_transaction(status, &trans));

   free(sqlda);
   *id=result[0];

   return rs;
}


void TDataBase::StartTesting(void)
{
   char query_str[300];
   sprintf(query_str,"update test_servers set testing=1 where id_srv=%d",id_srv);
   SqlExecute(query_str);
   start_time=GetTickCount();
}

void TDataBase::FinishTesting(void)
{
   char query_str[300];
   double tm;
   tm=(double)(GetTickCount()-start_time)/1000.0;

   sprintf(query_str,"update test_servers set testing=0,"
      "last_test_time=current_timestamp, "
      "testing_time=testing_time+%f where id_srv=%d",tm,id_srv);
   SqlExecute(query_str);
}

//обновление статуса решения с сохранением блокировки
int TDataBase::UpdateStatus(int id_stat, int id_rsl, isc_tr_handle *trans_lock)
{
   char query_str[300];
   int rs=1;

   sprintf(query_str,"update status set id_rsl=%d, "
           "update_time=current_timestamp where id_stat=%d",id_rsl,id_stat);
   SqlExecute(query_str,*trans_lock);
   sprintf(query_str,"update status set id_rsl=id_rsl+0, update_time=null where id_stat=%d",id_stat);
   commit_trans(*trans_lock);
   *trans_lock=start_trans(2);
   if (SqlExecute(query_str,*trans_lock)==-1) {
      rollback_trans(*trans_lock);
      rs=0;
   }

   //logf << "UpdateStatus[ "<< id_srv <<" ] id_stat=" << id_stat << "; id_rsl=" << id_rsl << "; rs=" << rs << endl;
   return rs;
}

int TDataBase::SelectDataSubmit(TSubmited *e, isc_tr_handle trans)
{

   char selstr[300];
   char s_log[300];
   float time;
   short flag0=0,flag1=0,flag2=0,flag3=0,flag4=0;
   XSQLDA ISC_FAR *sqlda;
   int rs,tr_nl=(trans==NULL);

   if (tr_nl) save_err(isc_start_transaction(status, &trans, 1, &db, 0, NULL));

   sqlda = (XSQLDA ISC_FAR *) malloc(XSQLDA_LENGTH(5));

   //получим непроверенные задачи
   strcpy(selstr,"select s.id_stat,s.id_publ,s.id_prb,s.id_cmp, "
                 "case when s.warn_rsl is null then -1 else s.warn_rsl end "
                 "from status s inner join results r on s.id_rsl=r.id_rsl "
                 "where r.incl_stat='n' and "
                 "(update_time is null or (current_timestamp-update_time)*86400>10) "
                 "order by id_stat");

   sqlda->sqln=5;
   sqlda->sqld=5;
   sqlda->version = 1;

   save_err(isc_dsql_prepare(status, &trans, &stmt, 0, selstr, SQL_DIALECT_V6, sqlda));

   sqlda->sqlvar[0].sqldata = (char ISC_FAR *)&e->id_stat;
   sqlda->sqlvar[0].sqlind  = (short ISC_FAR *)&flag0;
   sqlda->sqlvar[0].sqltype = SQL_LONG + 1;

   sqlda->sqlvar[1].sqldata = (char ISC_FAR *)&e->id_publ;
   sqlda->sqlvar[1].sqlind  = (short ISC_FAR *)&flag1;
   sqlda->sqlvar[1].sqltype = SQL_LONG + 1;

   sqlda->sqlvar[2].sqldata = (char ISC_FAR *)&e->id_prb;
   sqlda->sqlvar[2].sqlind  = (short ISC_FAR *)&flag2;
   sqlda->sqlvar[2].sqltype = SQL_LONG + 1;

   sqlda->sqlvar[3].sqldata = (char ISC_FAR *)&e->id_cmp;
   sqlda->sqlvar[3].sqlind  = (short ISC_FAR *)&flag3;
   sqlda->sqlvar[3].sqltype = SQL_SHORT + 1;

   sqlda->sqlvar[4].sqldata = (char ISC_FAR *)&e->warn_rsl;
   sqlda->sqlvar[4].sqlind  = (short ISC_FAR *)&flag4;
   sqlda->sqlvar[4].sqltype = SQL_LONG + 1;

   save_err(isc_dsql_execute(status, &trans, &stmt, SQL_DIALECT_V6, NULL));

   do {
      rs=isc_dsql_fetch(status, &stmt, SQL_DIALECT_V6, sqlda);
      if (rs==0) {
	     info2log("Есть непроверенные решения");
         sprintf(selstr,"update status set id_rsl=id_rsl+0 where id_stat=%d",e->id_stat);
		 if (SqlExecute(selstr,trans,1)!=-1) {
            break;
		 }
         sprintf(s_log,"Решение %d заблокировано другим сервером",e->id_stat);
	     info2log(s_log);
      }
   } while (rs==0);

   save_err(isc_dsql_free_statement(status, &stmt, DSQL_close));

   if (rs==0) {

      sprintf(selstr,
         "select time_lim, mem_lim, min_uniq_proc, hardlevel from problems where id_prb=%d order by id_prb",
         e->id_prb);

      sqlda->sqln=4;
      sqlda->sqld=4;
      sqlda->version=1;

      save_err(isc_dsql_prepare(status, &trans, &stmt, 0, selstr, SQL_DIALECT_V6, sqlda));

      sqlda->sqlvar[0].sqldata = (char ISC_FAR *)&time;
      sqlda->sqlvar[0].sqlind  = (short ISC_FAR *)&flag0;
      sqlda->sqlvar[0].sqltype = SQL_FLOAT + 1;

      sqlda->sqlvar[1].sqldata = (char ISC_FAR *)&e->mem;
      sqlda->sqlvar[1].sqlind  = (short ISC_FAR *)&flag1;
      sqlda->sqlvar[1].sqltype = SQL_LONG + 1;

      sqlda->sqlvar[2].sqldata = (char ISC_FAR *)&e->min_uniq_proc;
      sqlda->sqlvar[2].sqlind  = (short ISC_FAR *)&flag2;
      sqlda->sqlvar[2].sqltype = SQL_FLOAT + 1;

	  sqlda->sqlvar[3].sqldata = (char ISC_FAR *)&e->hardlevel;
      sqlda->sqlvar[3].sqlind  = (short ISC_FAR *)&flag3;
      sqlda->sqlvar[3].sqltype = SQL_LONG + 1;

      save_err(isc_dsql_execute(status, &trans, &stmt, SQL_DIALECT_V6, NULL));

      isc_dsql_fetch(status, &stmt, SQL_DIALECT_V6, sqlda);

      save_err(isc_dsql_free_statement(status, &stmt, DSQL_close));


      sprintf(selstr,"select max(g.f_mngr_sys) "
                     "from get_groups_user(%d) ggu inner join groups g "
                     "on ggu.id_grp=g.id_grp ",e->id_publ);

      sqlda->sqln=1;
      sqlda->sqld=1;
      sqlda->version=1;

      save_err(isc_dsql_prepare(status, &trans, &stmt, 0, selstr, SQL_DIALECT_V6, sqlda));

      sqlda->sqlvar[0].sqldata = (char ISC_FAR *)&e->debug_protect;
      sqlda->sqlvar[0].sqlind  = (short ISC_FAR *)&flag0;
      sqlda->sqlvar[0].sqltype = SQL_SHORT + 1;

      save_err(isc_dsql_execute(status, &trans, &stmt, SQL_DIALECT_V6, NULL));

      isc_dsql_fetch(status, &stmt, SQL_DIALECT_V6, sqlda);

      save_err(isc_dsql_free_statement(status, &stmt, DSQL_close));
      e->time=(double)time;
   } else {
   }

   free(sqlda);
   if (tr_nl) save_err(isc_commit_transaction(status, &trans));

   return !rs;
}


//проверка лучшего решения
//возвращает истину если текущее лучше
BOOL TDataBase::TestingBestSolve(TSubmited *e, int *old_author, int *id_slv, isc_tr_handle trans)
{
   char selstr[300];
   short flag0=0,flag1=0;
   XSQLDA ISC_FAR     *sqlda;
   int rs,tmp_field;
   BOOL ret=FALSE,tr_nl=(trans==NULL);

   if (tr_nl) save_err(isc_start_transaction(status, &trans, 1, &db, 0, NULL));

   sqlda = (XSQLDA ISC_FAR *) malloc(XSQLDA_LENGTH(2));
   sqlda->sqln=2;
   sqlda->sqld=2;
   sqlda->version=1;

   sprintf(selstr, "select bs.id_slv,s.id_publ from best_solve bs inner join status s on bs.id_slv=s.id_stat "
                   "where s.id_prb=%d and bs.add_admin='n'",e->id_prb);

   save_err(isc_dsql_prepare(status, &trans, &stmt, 0, selstr, SQL_DIALECT_V6, sqlda));

   sqlda->sqlvar[0].sqldata = (char ISC_FAR *)id_slv;
   sqlda->sqlvar[0].sqlind  = (short ISC_FAR *)&flag0;
   sqlda->sqlvar[0].sqltype = SQL_LONG + 1;

   sqlda->sqlvar[1].sqldata = (char ISC_FAR *)&tmp_field;
   sqlda->sqlvar[1].sqlind  = (short ISC_FAR *)&flag1;
   sqlda->sqlvar[1].sqltype = SQL_LONG + 1;

   save_err(isc_dsql_execute(status, &trans, &stmt, SQL_DIALECT_V6, NULL));

   rs=isc_dsql_fetch(status, &stmt, SQL_DIALECT_V6, sqlda);
   save_err(isc_dsql_free_statement(status, &stmt, DSQL_close));

   if (rs==100L) {
      *old_author=0;
      ret=TRUE;
   } else {
      *old_author=tmp_field;

      sqlda->sqln=1;
      sqlda->sqld=1;
      sqlda->version=1;
      char s1[200],s2[200],s3[50];

      strcpy(s1,master_cfg->Options->BestSourceFormula);
      sprintf(s3,"%.9f",e->time);
      StrReplace(s1,"$time",s3);
      sprintf(s3,"%d",e->mem);
      StrReplace(s1,"$mem",s3);

      strcpy(s2,master_cfg->Options->BestSourceFormula);
      StrReplace(s2,"$time","time_work");
      StrReplace(s2,"$mem","mem_use");

      sprintf(selstr, "select count(*) from status "
                      "where id_stat=%d and (%s)<(%s)",*id_slv,s1,s2);
      save_err(isc_dsql_prepare(status, &trans, &stmt, 0, selstr, SQL_DIALECT_V6, sqlda));

      sqlda->sqlvar[0].sqldata = (char ISC_FAR *)&tmp_field;
      sqlda->sqlvar[0].sqlind  = (short ISC_FAR *)&flag0;
      sqlda->sqlvar[0].sqltype = SQL_LONG + 1;

      save_err(isc_dsql_execute(status, &trans, &stmt, SQL_DIALECT_V6, NULL));

      isc_dsql_fetch(status, &stmt, SQL_DIALECT_V6, sqlda);
      save_err(isc_dsql_free_statement(status, &stmt, DSQL_close));
      if (tmp_field==1) ret=TRUE;
   }

   free(sqlda);
   if (tr_nl) save_err(isc_commit_transaction(status, &trans));

   return ret;
}

int TDataBase::UpdateBestSolve(TSubmited *e, char* bf, int len, int old_author, int id_slv,isc_tr_handle trans)
{
   char query[200];
   ISC_QUAD blob_id;
   isc_blob_handle blob_handle=NULL;
//   isc_tr_handle trans=NULL;
   XSQLDA ISC_FAR *sqlda;
   int tr_nl=(trans==NULL);

   if (tr_nl) save_err(isc_start_transaction(status, &trans, 1, &db, 0, NULL));

   if (old_author==0) {
      sprintf(query,"insert into best_solve(id_slv,add_admin,best_code) values(%d,'%s',?)",
            e->id_stat,"n");
   } else if (e->id_publ==old_author) {
      sprintf(query,"update best_solve set id_slv=%d,best_code=? where id_slv=%d",
            e->id_stat,id_slv);
   } else {
      sprintf(query,"update best_solve set id_slv=%d,who_view='s',best_code=? where id_slv=%d",
            e->id_stat,id_slv);
   }

   //обновим поле blob
   sqlda=(XSQLDA ISC_FAR *) malloc(XSQLDA_LENGTH(1));
   memset(sqlda,0,XSQLDA_LENGTH(1));
   sqlda->sqln=1;
   sqlda->sqld=1;
   sqlda->version=1;

   sqlda->sqlvar[0].sqldata=(char ISC_FAR *) &blob_id;
   sqlda->sqlvar[0].sqltype=SQL_BLOB;
   sqlda->sqlvar[0].sqllen=sizeof(ISC_QUAD);

   blob_handle=0;
   save_err(isc_create_blob(status, &db, &trans, &blob_handle, &blob_id));

   unsigned short sz=1024;
   for (int i=0;i<len;i+=sz) {
      if (len-i<sz) sz=(unsigned short)(len-i);
      save_err(isc_put_segment(status, &blob_handle, sz, (char *)(bf+i)));
   }

   save_err(isc_close_blob(status, &blob_handle));
   save_err(isc_dsql_execute_immediate(status,&db,&trans,0,query,1,sqlda));
   free(sqlda);

   if (tr_nl) save_err(isc_commit_transaction(status, &trans));

   return 0;
}

int TDataBase::SaveReports(int id_stat, int id_rsl, TPaths *pt, isc_tr_handle trans)
{
   char query[200],*bf,*bf1;
   ISC_QUAD blob_id;
   isc_blob_handle blob_handle=NULL;
   XSQLDA ISC_FAR *sqlda, *sqlda_sel;
   int tr_nl=(trans==NULL);
   int id_rpt,rs,len,max_sz;
   short flag0=0;
   unsigned short sz=1024,sz_r;
   ifstream in;

   if (tr_nl) save_err(isc_start_transaction(status, &trans, 1, &db, 0, NULL));

   //DEBUG!!!
         if (id_rsl==RS_WRONG_ANSWER && FileExists(pt->ListPoints)){
			 id_rsl = RS_PARTIALLY_ACCEPTED;
		 }

   sprintf(query,"select id_rpt from result_report where id_rsl=%d",id_rsl);

   sqlda_sel = (XSQLDA ISC_FAR *) malloc(XSQLDA_LENGTH(1));
   sqlda_sel->sqln=1;
   sqlda_sel->sqld=1;
   sqlda_sel->version=1;

   save_err(isc_dsql_prepare(status, &trans, &stmt, 0, query, SQL_DIALECT_V6, sqlda_sel));

   sqlda_sel->sqlvar[0].sqldata = (char ISC_FAR *)&id_rpt;
   sqlda_sel->sqlvar[0].sqlind  = (short ISC_FAR *)&flag0;
   sqlda_sel->sqlvar[0].sqltype = SQL_LONG + 1;

   save_err(isc_dsql_execute(status, &trans, &stmt, SQL_DIALECT_V6, NULL));

   sprintf(query,"insert into status_reports(id_stat,id_rpt,text) values(%d,?,?)",
          id_stat);

   sqlda=(XSQLDA ISC_FAR *) malloc(XSQLDA_LENGTH(2));
   memset(sqlda,0,XSQLDA_LENGTH(2));
   sqlda->sqln=2;
   sqlda->sqld=2;
   sqlda->version=1;

   sqlda->sqlvar[0].sqldata=(char ISC_FAR *) &id_rpt;
   sqlda->sqlvar[0].sqltype=SQL_LONG;
   sqlda->sqlvar[0].sqllen=4;

   sqlda->sqlvar[1].sqldata=(char ISC_FAR *) &blob_id;
   sqlda->sqlvar[1].sqltype=SQL_BLOB;
   sqlda->sqlvar[1].sqllen=sizeof(ISC_QUAD);

   bf=new char[sz];
   while(1) {
      rs=isc_dsql_fetch(status, &stmt, SQL_DIALECT_V6, sqlda_sel);
      if (rs) break;

      blob_handle=NULL;
      save_err(isc_create_blob(status, &db, &trans, &blob_handle, &blob_id));

      if (id_rpt==RPT_PLAGIAT_OUTPUT) {
         //bf1=pt->get_report_name(id_rpt);
         bf1="";
         save_err(isc_put_segment(status, &blob_handle,(unsigned short)strlen(bf1),bf1));
      } 
	  else 
	  {
         len=0;
         in.clear();		 

         in.open(pt->get_report_name(id_rpt),ios::in | ios::binary);
         max_sz=1024*master_cfg->Options->MaxFileSizeAddOtchet;
         while (in && max_sz>=0) {
            in.read(bf,sz);
            sz_r=(unsigned short)in.gcount();
            if (max_sz-sz_r<0) {
               sz_r=(unsigned short)max_sz;
               max_sz--;
            }
            len+=sz_r;
            save_err(isc_put_segment(status, &blob_handle,sz_r,bf));
            max_sz-=sz_r;
            if (sz!=sz_r) break;
         }
         in.close();
         if (max_sz<0)
            save_err(isc_put_segment(status, &blob_handle,5,"<...>"));
      }

      if (!len && (id_rpt==RPT_TEST_ERROR || id_rpt==RPT_CHECKER_OUTPUT)) {
         save_err(isc_cancel_blob(status, &blob_handle));
         continue;
      }

      save_err(isc_close_blob(status, &blob_handle));
      save_err(isc_dsql_execute_immediate(status,&db,&trans,0,query,1,sqlda));
   }

   if (tr_nl) save_err(isc_commit_transaction(status, &trans));

   free(sqlda);
   free(sqlda_sel);
   delete[] bf;

   return 0;
}

int TDataBase::SaveObjFile(int id_stat, char *obj_file, isc_tr_handle trans)
{
   char query[200],*bf;
   ISC_QUAD blob_id;
   isc_blob_handle blob_handle=NULL;
   XSQLDA ISC_FAR *sqlda;
   int tr_nl=(trans==NULL);
   unsigned short sz=512,sz_r;
   ifstream in;

   if (tr_nl) save_err(isc_start_transaction(status, &trans, 1, &db, 0, NULL));

   sprintf(query,"update status set obj_data=? where id_stat=%d",id_stat);

   sqlda=(XSQLDA ISC_FAR *) malloc(XSQLDA_LENGTH(1));
   memset(sqlda,0,XSQLDA_LENGTH(1));
   sqlda->sqln=1;
   sqlda->sqld=1;
   sqlda->version=1;

   sqlda->sqlvar[0].sqldata=(char ISC_FAR *) &blob_id;
   sqlda->sqlvar[0].sqltype=SQL_BLOB;
   sqlda->sqlvar[0].sqllen=sizeof(ISC_QUAD);

   bf=new char[sz];

   blob_handle=NULL;
   save_err(isc_create_blob(status, &db, &trans, &blob_handle, &blob_id));

   in.clear();
   in.open(obj_file,ios::in | ios::binary);
   while (in) {
      in.read(bf,sz);
      sz_r=(unsigned short)in.gcount();
      save_err(isc_put_segment(status, &blob_handle, sz_r,bf));
      if (sz!=sz_r) break;
   }
   in.close();
   save_err(isc_close_blob(status, &blob_handle));
   save_err(isc_dsql_execute_immediate(status,&db,&trans,0,query,1,sqlda));

   if (tr_nl) save_err(isc_commit_transaction(status, &trans));

   free(sqlda);
   delete[] bf;

   return 0;
}

int TDataBase::TestPlagiat(int id_stat, int id_cmp, char *obj_file,
                           int *again_plagiat, float *cur_eq, int *cmp_id_stat, 
						   isc_tr_handle trans)
{
   char query[400],*bf0,*bf1,*bf_cur;
   ISC_QUAD blob_id;
   isc_blob_handle blob_handle=NULL;
   XSQLDA ISC_FAR *sqlda;
   int tr_nl=(trans==NULL),rez=1;
   int id_stat_x,id_publ_x;
   short flag0=0,flag1=0,flag2=0,length;
   int sz=512,sz_r=0,len0,len1;
   ifstream in;
   char blob_items[]={isc_info_blob_max_segment,isc_info_blob_total_length};
   char res_buffer[20],*p;
   unsigned char item;
   double proc_uniq=100.0,vl_uniq;

   *cur_eq=100.0;
   *cmp_id_stat=0;
   *again_plagiat=0;

   in.clear();
   in.open(obj_file,ios::in | ios::binary);
   in.seekg(0,ios::end);
   len0=in.tellg();
   if (len0==0) { //файл пуст - проверять нечего
	   in.close();
	   return rez; //решение уникально :)
   }
   in.seekg(0,ios::beg);

   bf0=new char[len0];
   bf_cur=bf0;
   while (in) {
      in.read(bf_cur,sz);
      sz_r=(unsigned short)in.gcount();
      if (sz!=sz_r) break;
      bf_cur+=sz_r;
   }
   in.close();

   if (tr_nl) save_err(isc_start_transaction(status, &trans, 1, &db, 0, NULL));

   sprintf(query,"select count(*) "
                 "from status s1, status s2 "
                 "where s1.id_stat=%d and s2.id_prb=s1.id_prb and "
                 "s2.id_publ=s1.id_publ and s2.id_rsl=%d", id_stat, RS_UNIQUE_ERROR);
   GetGenLast(query,again_plagiat,trans,1);

   sprintf(query,"select s.id_stat, s.id_publ, s.obj_data "
                 "from status s inner join status s0 "
                 "   on s.id_cmp=s0.id_cmp and "
                 "      s.id_publ<>s0.id_publ and "
                 "      s.dt_tm<s0.dt_tm "
                 "   inner join problems p1 "
                 "   on p1.id_prb=s0.id_prb "
                 "   inner join problems p2 "
                 "   on p2.union_plagiat=p1.union_plagiat and p2.id_prb=s.id_prb "
                 "where s0.id_stat=%d and s.id_rsl=0 and s.obj_data is not null "
                 "order by s.dt_tm",id_stat);

   sqlda=(XSQLDA ISC_FAR *) malloc(XSQLDA_LENGTH(3));
   memset(sqlda,0,XSQLDA_LENGTH(3));
   sqlda->sqln=3;
   sqlda->sqld=3;
   sqlda->version=1;

   save_err(isc_dsql_prepare(status, &trans, &stmt, 0, query, SQL_DIALECT_V6, sqlda));

   sqlda->sqlvar[0].sqldata = (char ISC_FAR *)&id_stat_x;
   sqlda->sqlvar[0].sqlind  = (short ISC_FAR *)&flag0;
   sqlda->sqlvar[0].sqltype = SQL_LONG + 1;

   sqlda->sqlvar[1].sqldata = (char ISC_FAR *)&id_publ_x;
   sqlda->sqlvar[1].sqlind  = (short ISC_FAR *)&flag1;
   sqlda->sqlvar[1].sqltype = SQL_LONG + 1;

   sqlda->sqlvar[2].sqldata = (char ISC_FAR *) &blob_id;
   sqlda->sqlvar[2].sqlind  = (short ISC_FAR *)&flag2;
   sqlda->sqlvar[2].sqltype = SQL_BLOB + 1;

   save_err(isc_dsql_execute(status, &trans, &stmt, SQL_DIALECT_V6, NULL));

   while (isc_dsql_fetch(status, &stmt, SQL_DIALECT_V6, sqlda)==0) {
      save_err(isc_open_blob2(status, &db, &trans, &blob_handle, &blob_id, 0, NULL));
      save_err(isc_blob_info(status,&blob_handle,
         sizeof(blob_items),blob_items,sizeof(res_buffer),res_buffer));

      for (p=res_buffer;*p!=isc_info_end;) {
         item=*p++;
         //length=(short)isc_portable_integer(p,2);
         length=(*(short*)p);
         p+=2;
         switch (item) {
            case isc_info_blob_max_segment:
               //sz_r=isc_portable_integer(p,length);
               sz=(*(int*)p);
               break;
            case isc_info_blob_total_length:
               //len1=isc_portable_integer(p, length);
               len1=(*(int*)p);
               break;
         }
         p+=length;
      }

      bf1=new char[len1];
      bf_cur=bf1;
      while (isc_get_segment(status, &blob_handle,
            (unsigned short *) &sz_r,(unsigned short)sz,bf_cur) == 0)
            bf_cur+=sz_r;

      save_err(isc_close_blob(status, &blob_handle));

      //вызываем мега функцию сравнения
	  vl_uniq=find_common_substr_x(bf0,len0,bf1,len1,master_cfg->CompilerId(id_cmp)->MinLenComStr);
      vl_uniq = 100.0-100.0*vl_uniq/len0;
      if (vl_uniq<0) vl_uniq=0;

      delete[] bf1;

      if (vl_uniq<proc_uniq) {
         proc_uniq=vl_uniq;
         //sprintf(s,"id_stat=%d;id_publ=%d;proc_not_uniq=%.3f",
        //         id_stat_x,id_publ_x,100.0-proc_uniq);
		 *cur_eq=(float)proc_uniq;
		 *cmp_id_stat=id_stat_x;
      }
   }
   save_err(isc_dsql_free_statement(status, &stmt, DSQL_close));

   if (tr_nl) save_err(isc_commit_transaction(status, &trans));

   free(sqlda);
   delete[] bf0;
/*
   if (proc_uniq<min_uniq_proc) {
      if (otch) {
         strcpy(otch,s);
      }
      rez=0;
   }
*/
   return rez;
}

void TDataBase::print_error(char *s)
{
   int errcode=isc_sqlcode(status);
   long *hst=status;
   char msg[512],ts[50];
   SYSTEMTIME sys_tm;

   GetSystemTime(&sys_tm);
   sprintf(ts,"%02d:%02d:%02d.%03d",sys_tm.wHour,sys_tm.wMinute,sys_tm.wSecond,sys_tm.wMilliseconds);

   logfl << ts <<" [СЕРВЕР "<< id_srv <<"] ERROR DATABASE!!! errorcode="<< errcode << ":\n";
   logfl << "{ " << s << "\n";
   isc_interprete(msg,&hst);
   logfl << "  "<< msg << "\n";
   isc_sql_interprete((short)errcode,msg,512);
   logfl << "  "<< msg << "}\n";
   logfl.close();
   logfl.open(master_cfg->GlobalPaths->LogFile,ios::out | ios::app);
}

int TDataBase::save_err(int err)
{
   if (err) print_error();
   return err;
}

