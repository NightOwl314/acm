
#include "db_util.h"
#include "log.h"


//соединение с существующей базой данных
int CDataBase::Connect(char *file, char *username, char *password)
{
   char ISC_FAR   *dpb, *copy;
   short           dpb_length=0;
   int stat = 0;

   //выделим память и укажем обязательный первый байт в буфере параметров
   copy=dpb=new char[7];
   dpb[0]=isc_dpb_version1;
   dpb_length=1;

   //укажем пользователя и пароль
   isc_expand_dpb(&dpb, &dpb_length,
                  isc_dpb_user_name, username,
                  isc_dpb_password, password,  NULL);

   delete[] copy;

   //соединение с БД, указатель на БД 4й параметр
   if (save_err(isc_attach_database(status, 0, file, &db, dpb_length, dpb)))
      stat = -1;

   //выделим память на сервере
   if (stat || save_err(isc_dsql_allocate_statement(status, &db, &stmt)))
      stat = -1;

   if(stat)
   {
      sprintf_s(logfile.str, "Соединение с БД не создано");
      logfile.Write(3);
   }
   else
   {
      sprintf_s(logfile.str, "Соединение с БД создано");
      logfile.Write(3);
   }
   return stat;
}

int CDataBase::Disconnect(void)
{
   //освободим память на сервере
   save_err(isc_dsql_free_statement(status, &stmt, DSQL_drop));
   stmt = NULL;

   //разрываем соединение
   save_err(isc_detach_database (status, &db));
   db = NULL;

   return 0;
}

//выполнить запрос без возвращаемых данных
int CDataBase::SqlExecute(char *query, isc_tr_handle trans)
{
   int stat = 0, tr_nl = (trans == NULL);

   //начало транзакции
   if(tr_nl) trans = start_trans();

   //выполнение SQl запроса
   if(save_err(isc_dsql_execute_immediate(status, &db, &trans, 0, query, SQL_DIALECT_V6, NULL)))
      stat = -1;

   //завершение транзакции
   if(tr_nl) stat ? rollback_trans(trans) : commit_trans(trans);
   if(stat)
   {
      sprintf_s(logfile.str, "Ошибка при выполнении запроса [%s]", query);
      logfile.Write(3);
   } else
   {
      sprintf_s(logfile.str, "Запрос [%s] выполнен успешно", query);
      logfile.Write(9);
   }
   return stat;
}

//создает новую транзакцию
isc_tr_handle CDataBase::start_trans(int type)
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

   if(save_err(isc_start_transaction(status, &trans, 1, &db, isc_tpb_size, isc_tpb)))
   {
      sprintf_s(logfile.str, "Ошибка старта транзакции");
      logfile.Write(4);
   }

   return trans;
}

int CDataBase::commit_trans(isc_tr_handle trans)
{
   return save_err(isc_commit_transaction(status, &trans));
}

int CDataBase::rollback_trans(isc_tr_handle trans)
{
   return save_err(isc_rollback_transaction(status, &trans));
}

//получить значение генератора
int CDataBase::Gen_ID(const char *name_gen, IDENTITY *id, isc_tr_handle trans, int k)
{ 
   short flag[1];
   XSQLDA ISC_FAR *sqlda;   
   int stat = 0, i; 
   int tr_nl = (trans == NULL);

   sprintf_s(query, "SELECT GEN_ID(%s, %d) FROM RDB$DATABASE", name_gen, k);

   if (tr_nl) stat = save_err(isc_start_transaction(status, &trans, 1, &db, 0, NULL));

   if(!stat)
   {
      sqlda = (XSQLDA ISC_FAR *) malloc(XSQLDA_LENGTH(1));

      sqlda->sqln = 1; //принимаем 1 поле
      sqlda->sqld = 1;
      sqlda->version = 1;
   
      stat = save_err(isc_dsql_prepare(status, &trans, &stmt, 0, query, SQL_DIALECT_V6, sqlda));
      if(stat)
      {
         if(sqlda) free(sqlda);
         return -1;
      }
   }

   if(!stat)
   {
      i = 0;
      sqlda->sqlvar[i].sqldata = (char ISC_FAR *)id;
      sqlda->sqlvar[i].sqlind  = (short ISC_FAR *)(flag+i);
      sqlda->sqlvar[i].sqltype = SQL_INT64 + 1;

      stat = save_err(isc_dsql_execute(status, &trans, &stmt, SQL_DIALECT_V6, NULL));
   }

   if(!stat)
      stat = isc_dsql_fetch(status, &stmt, SQL_DIALECT_V6, sqlda);

   save_err(isc_dsql_free_statement(status, &stmt, DSQL_close));

   if (tr_nl) save_err((stat ? isc_commit_transaction : isc_rollback_transaction)(status, &trans));

   if(sqlda) free(sqlda);

   if(stat) {
      sprintf_s(logfile.str, "Ошибка получения значения генератора [%s]", query);
      logfile.Write(4);
   } else {
      sprintf_s(logfile.str, "Получено значение генератора [%s]", query);
      logfile.Write(8);
   }

   return stat;
}

int CDataBase::save_err(int err)
{
   long SQLCODE;
   if(!err) return 0;
   if(err && !Error) Error = err;

   SQLCODE = isc_sqlcode(status);
   //isc_print_sqlerror(SQLCODE, status);
   
   if(SQLCODE != 100)
   {
	   sprintf_s(logfile.str, "Ошибка базы данных №%d SQLCODE=%d", err, SQLCODE);
       logfile.Write(0);
   }

   return err;
}


int CDataBase::GetBlobTxt(isc_tr_handle trans, ISC_QUAD *blob_id, char *filename)
{
   int stat = 0;
   int tr_nl = (trans == NULL);
   FILE *f;
    int max_size, total_length;
   unsigned short size_readed;
   isc_blob_handle blob_handle = NULL;
   char blob_items[]={isc_info_blob_max_segment,isc_info_blob_total_length};
   char res_buffer[20], *p;

   stat = save_err(isc_open_blob2(status, &db, &trans, &blob_handle, blob_id, 0, NULL));
   if(stat) return stat;
      
   stat = save_err(isc_blob_info(status, &blob_handle, sizeof(blob_items), blob_items, sizeof(res_buffer), res_buffer));
   if(stat) return stat;
      
   for(p = res_buffer; *p != isc_info_end && !stat; )
   {
      int item = *p++;
      int length = (short)isc_vax_integer(p, 2);
      p += 2;
      switch (item)
      {
         case isc_info_blob_max_segment:
            max_size = isc_vax_integer(p, length);
            break;
         case isc_info_blob_total_length:
            total_length = isc_vax_integer(p, length);
            break;
      }
      p += length;
   }

   p = new char[max_size + 1];
   fopen_s(&f, filename, "w+b");
   while(!save_err(isc_get_segment(status, &blob_handle, (unsigned short *)&size_readed, (unsigned short)max_size, p)))
   {
      fwrite(p, sizeof(char), size_readed, f);
      fflush(f);
   }
   save_err(isc_close_blob(status, &blob_handle));
   fclose(f);
   delete [] p;

   if(stat){
      sprintf_s(logfile.str, "Ошибка получения BLOB значения [%s]", filename);
      logfile.Write(4);
   } else {
      sprintf_s(logfile.str, "Получено BLOB значение [%s]", filename);
      logfile.Write(8);
   }

   return stat;
}


int CDataBase::GetGameForPlay(isc_tr_handle trans, IDENTITY *id)
{
   XSQLDA ISC_FAR *sqlda = NULL;
   int tr_nl = (trans == NULL), stat = 0, i;
   short flag[1];
 
   sprintf_s(query, "select id from playing where state = %d", game_state_forplay);

   if(tr_nl) stat = save_err(isc_start_transaction(status, &trans, 1, &db, 0, NULL));
   
   if(!stat)
   {
      sqlda = (XSQLDA ISC_FAR *) malloc(XSQLDA_LENGTH(1));

      sqlda->sqln=1;
      sqlda->sqld=1;
      sqlda->version = 1;      
      
      stat = save_err(isc_dsql_prepare(status, &trans, &stmt, 0, query, SQL_DIALECT_V6, sqlda));
   }
   if(!stat)
   {
      i = 0;
      sqlda->sqlvar[i].sqldata = (char ISC_FAR *)id;
      sqlda->sqlvar[i].sqlind  = (short ISC_FAR *)(flag+i);
      sqlda->sqlvar[i].sqltype = SQL_INT64 + 1;
      i++;

      stat = save_err(isc_dsql_execute(status, &trans, &stmt, SQL_DIALECT_V6, NULL));
      if(stat)
      {
          if (tr_nl) rollback_trans(trans);
          free(sqlda);
         return -1;
      }
   }
 
   if(!stat) do
   {
      stat = isc_dsql_fetch(status, &stmt, SQL_DIALECT_V6, sqlda);
      if(!stat)
       {
         sprintf_s(query, "update playing set start = CURRENT_TIMESTAMP where id = %d", *id);
         if(!SqlExecute(query, trans))
            break;
      }
   } while (!stat);

   save_err(isc_dsql_free_statement(status, &stmt, DSQL_close));
   if(sqlda) free(sqlda);
   if (tr_nl) stat ? rollback_trans(trans) : commit_trans(trans);

   if(stat){
      sprintf_s(logfile.str, "Ошибка получения игры [%s]", query);
      logfile.Write(4);
   } else {
      sprintf_s(logfile.str, "Отобрана новая игра [%s]", query);
      logfile.Write(8);
   }
   return stat;
}


int CDataBase::GetNewSolution(isc_tr_handle trans, CPlayer **player)
{
   int stat = 0;
   int tr_nl = (trans == NULL), i = 0;
   short flag[4];
   char query[255];
   XSQLDA ISC_FAR *sqlda;
   ISC_QUAD blob_id;
   CPlayer *plr;
   short compiler[1];

   if(tr_nl) stat = save_err(isc_start_transaction(status, &trans, 1, &db, 0, NULL));

   if(!stat)
   {
      plr = new CPlayer();

      sprintf_s(query, "select id, id_trnmnt, compiler, code_source from gm_slv where test_result = %d", -1);
      sqlda = (XSQLDA ISC_FAR *) malloc(XSQLDA_LENGTH(4));
      sqlda->sqln = 4;
      sqlda->sqld = 4;
      sqlda->version = 1;   

      stat = save_err(isc_dsql_prepare(status, &trans, &stmt, 0, query, SQL_DIALECT_V6, sqlda));
      if(stat)
      {
         free(sqlda);
         return stat;
      }
   }
   if(!stat)
   {
      i = 0;
      sqlda->sqlvar[i].sqldata = (char ISC_FAR *)&(plr->id);
      sqlda->sqlvar[i].sqlind  = (short ISC_FAR *)(flag+i);
      sqlda->sqlvar[i].sqltype = SQL_INT64 + 1;

      i++;
      sqlda->sqlvar[i].sqldata = (char ISC_FAR *)&(plr->id_trnmnt);
      sqlda->sqlvar[i].sqlind  = (short ISC_FAR *)(flag+i);
      sqlda->sqlvar[i].sqltype = SQL_INT64 + 1;

      i++;
      sqlda->sqlvar[i].sqldata = (char ISC_FAR *)compiler;
      sqlda->sqlvar[i].sqlind  = (short ISC_FAR *)(flag+i);
      sqlda->sqlvar[i].sqltype = SQL_SHORT + 1;

      i++;
      sqlda->sqlvar[i].sqldata = (char ISC_FAR *)&blob_id;
      sqlda->sqlvar[i].sqlind  = (short ISC_FAR *)(flag+i);
      sqlda->sqlvar[i].sqltype = SQL_BLOB + 1;

      stat = save_err(isc_dsql_execute(status, &trans, &stmt, SQL_DIALECT_V6, NULL));
      if(stat)
      {
          if (tr_nl) rollback_trans(trans);
         save_err(isc_dsql_free_statement(status, &stmt, DSQL_close));
          free(sqlda);  
         return -1;
      }
   }
   if(!stat)
   {
      stat = 1;
      while(!isc_dsql_fetch(status, &stmt, SQL_DIALECT_V6, sqlda))
      {      
         sprintf_s(query, "update gm_slv set test_result = %d where id = %d", -2, plr->id);
         if(!SqlExecute(query, trans))
         {
            stat = 0;
            break;
         }
      }

      if(1 == stat)
      {
         if (tr_nl) rollback_trans(trans);
         *player = NULL;
         free(sqlda);
         return 0;//нет новых решений
      }
      stat = 0;
   }
   if(!stat)
   {
      for(VCCompilers::iterator it = Compilers.begin(); it != Compilers.end(); it++)
         if((*it)->id == *compiler)
         {
            plr->compil = *it;
            break;
         }

      if(!plr->compil)
      {
         plr->status = (char)st_compilation_error;
         save_err(isc_dsql_free_statement(status, &stmt, DSQL_close));
         free(sqlda);
         if (tr_nl) rollback_trans(trans);
         *player = plr;
         return stat;
      }
   }

   if(!stat)
   {
      //определяем путь к исходнику
      sprintf_s(plr->srcfile, "%s%s", TestPlayDir, plr->compil->FileIn);
      _itoa_s((int)plr->id, plr->id_s, 32, 16);
      StrReplace(plr->srcfile, REPLACE_ID, plr->id_s);
      //получаем исходник
      stat = GetBlobTxt(trans, &blob_id, plr->srcfile);
   }
   if(!stat)
      stat = plr->Compile(TestPlayDir);

   if(!stat)
   {
      //sprintf_s(filename, "%scompil%d.out", TestPlayDir, plr->id);
      if(FileExists(plr->compilout)) UpdateCompilOut(trans, plr->id, plr->compilout);      
   }

   save_err(isc_dsql_free_statement(status, &stmt, DSQL_close));
   free(sqlda);

   if(stat)
   {
      if (tr_nl) rollback_trans(trans);
      *player = NULL;
      sprintf_s(logfile.str, "Ошибка при получении тестового решнения");
      logfile.Write(4);
   } else
   {
      if (tr_nl) commit_trans(trans);
      *player = plr;
      sprintf_s(logfile.str, "Найдено непровереное решение [%d]", plr->id);
      logfile.Write(8);
   }

   return stat;
}

int CDataBase::GetTournamentId(isc_tr_handle trans, IDENTITY playing_id, IDENTITY *id)
{
   XSQLDA ISC_FAR *sqlda;
   int stat = 0, i;
   short flag[1];
   int tr_nl = (trans == NULL);

   if(tr_nl) stat = save_err(isc_start_transaction(status, &trans, 1, &db, 0, NULL));

   if(!stat)
   {
      sprintf_s(query, "select tournaments.id from tournaments, slv_play, gm_slv where slv_play.id_playing = %d and slv_play.id_gm_slv = gm_slv.id and gm_slv.id_trnmnt = tournaments.id", playing_id);
      sqlda = (XSQLDA ISC_FAR *) malloc(XSQLDA_LENGTH(1));
      sqlda->sqln = 1;
      sqlda->sqld = 1;
      sqlda->version = 1;

      stat = save_err(isc_dsql_prepare(status, &trans, &stmt, 0, query, SQL_DIALECT_V6, sqlda));
   }

   if(!stat)
   {
      i = 0;
      sqlda->sqlvar[i].sqldata = (char ISC_FAR *)id;
      sqlda->sqlvar[i].sqlind  = (short ISC_FAR *)(flag+i);
      sqlda->sqlvar[i].sqltype = SQL_INT64 + 1;
      i++;

      stat = save_err(isc_dsql_execute(status, &trans, &stmt, SQL_DIALECT_V6, NULL));
      if(stat)
      {
          if (tr_nl) rollback_trans(trans);
         free(sqlda);
         save_err(isc_dsql_free_statement(status, &stmt, DSQL_close));
         return stat;
      }
   }

   if(!stat)
      stat = isc_dsql_fetch(status, &stmt, SQL_DIALECT_V6, sqlda);

   save_err(isc_dsql_free_statement(status, &stmt, DSQL_close));
   if(sqlda) free(sqlda);

   if (tr_nl) stat ? rollback_trans(trans) : commit_trans(trans);
   if(stat){
      sprintf_s(logfile.str, "Ошибка при получении турнира");
      logfile.Write(4);
   } else {
      sprintf_s(logfile.str, "Отобран турнир [%u]", *id);
      logfile.Write(8);
   }
   return stat;
}


int CDataBase::GetTournamentData(isc_tr_handle trans, IDENTITY id, TTournament *trnmnt)
{
   XSQLDA ISC_FAR *sqlda;
   int stat = 0, i = 0;
   short flag[9];
   int tr_nl = (trans == NULL);

   if(tr_nl) stat = save_err(isc_start_transaction(status, &trans, 1, &db, 0, NULL));

   if(!stat)
   {
      sprintf_s(query, "select id, state, type, max_mem, max_move, max_time_move, max_time_game, chk_prg, test_prg from tournaments where id = %d", id);
      sqlda = (XSQLDA ISC_FAR *) malloc(XSQLDA_LENGTH(9));
      sqlda->sqln = 9;
      sqlda->sqld = 9;
      sqlda->version = 1;

      stat = save_err(isc_dsql_prepare(status, &trans, &stmt, 0, query, SQL_DIALECT_V6, sqlda));
   }

   if(!stat)
   {
      i = 0;
      sqlda->sqlvar[i].sqldata = (char ISC_FAR *)&trnmnt->id;
      sqlda->sqlvar[i].sqlind  = (short ISC_FAR *)(flag+i);
      sqlda->sqlvar[i].sqltype = SQL_INT64 + 1;
      i++;

      sqlda->sqlvar[i].sqldata = (char ISC_FAR *)&trnmnt->state;
      sqlda->sqlvar[i].sqlind  = (short ISC_FAR *)(flag+i);
      sqlda->sqlvar[i].sqltype = SQL_LONG + 1;
      i++;

      sqlda->sqlvar[i].sqldata = (char ISC_FAR *)&trnmnt->type;
      sqlda->sqlvar[i].sqlind  = (short ISC_FAR *)(flag+i);
      sqlda->sqlvar[i].sqltype = SQL_LONG + 1;
      i++;

      sqlda->sqlvar[i].sqldata = (char ISC_FAR *)&trnmnt->limits.max_mem;
      sqlda->sqlvar[i].sqlind  = (short ISC_FAR *)(flag+i);
      sqlda->sqlvar[i].sqltype = SQL_LONG + 1;
      i++;

      sqlda->sqlvar[i].sqldata = (char ISC_FAR *)&trnmnt->limits.max_move;
      sqlda->sqlvar[i].sqlind  = (short ISC_FAR *)(flag+i);
      sqlda->sqlvar[i].sqltype = SQL_LONG + 1;
      i++;

      sqlda->sqlvar[i].sqldata = (char ISC_FAR *)&trnmnt->limits.max_tm_move;
      sqlda->sqlvar[i].sqlind  = (short ISC_FAR *)(flag+i);
      sqlda->sqlvar[i].sqltype = SQL_LONG + 1;
      i++;

      sqlda->sqlvar[i].sqldata = (char ISC_FAR *)&trnmnt->limits.max_tm_game;
      sqlda->sqlvar[i].sqlind  = (short ISC_FAR *)(flag+i);
      sqlda->sqlvar[i].sqltype = SQL_LONG + 1;
      i++;

      sqlda->sqlvar[i].sqldata = (char ISC_FAR *)trnmnt->chk_prg;
      sqlda->sqlvar[i].sqlind  = (short ISC_FAR *)(flag+i);
      sqlda->sqlvar[i].sqltype = SQL_TEXT + 1;
      i++;

      sqlda->sqlvar[i].sqldata = (char ISC_FAR *)trnmnt->tst_prg;
      sqlda->sqlvar[i].sqlind  = (short ISC_FAR *)(flag+i);
      sqlda->sqlvar[i].sqltype = SQL_TEXT + 1;
      i++;

      stat = save_err(isc_dsql_execute(status, &trans, &stmt, SQL_DIALECT_V6, NULL));
      if(stat)
      {
          if (tr_nl) rollback_trans(trans);
          free(sqlda);
         save_err(isc_dsql_free_statement(status, &stmt, DSQL_close));
         return stat;
      }
   }

   if(!stat)
      stat = save_err(isc_dsql_fetch(status, &stmt, SQL_DIALECT_V6, sqlda));
   if(!stat)
   {
      trnmnt->chk_prg[MAX_STR_LEN-1] = 0;
      trnmnt->tst_prg[MAX_STR_LEN-1] = 0;
      trim(trnmnt->chk_prg, strim);
      trim(trnmnt->tst_prg, strim);
   }
   save_err(isc_dsql_free_statement(status, &stmt, DSQL_close));
   if(sqlda) free(sqlda);
   if (tr_nl) stat ? rollback_trans(trans) : commit_trans(trans);  
  
   if(stat){
      sprintf_s(logfile.str, "Ошибка при получении данных о турнире %u", id);
      logfile.Write(4);
   } else {
      sprintf_s(logfile.str, "Получены данные о турнире [%u]", id);
      logfile.Write(8);
   }

   return stat ? stat : id != trnmnt->id;
}


int CDataBase::GetPlayers(isc_tr_handle trans, IDENTITY playing_id, VCPlayers *plrs, char *dir)
{
   int stat = 0, i;
   int tr_nl = (trans == NULL);
   XSQLDA ISC_FAR *sqlda;
   short flag[7];
   CPlayer *plr;
   ISC_QUAD blob_id;
   IDENTITY id[1];
   INTEGER test_result[1];
   INTEGER k[3];
   short compiler[1];

   if(tr_nl) stat = save_err(isc_start_transaction(status, &trans, 1, &db, 0, NULL));

   if(!stat)
   {
      sprintf_s(query, "select gm_slv.id, gm_slv.test_result, gm_slv.compiler, gm_slv.code_source, \
                       gm_slv.count_error, gm_slv.count_good, slv_play.number \
                       from gm_slv, slv_play where slv_play.id_playing = %d and slv_play.id_gm_slv = gm_slv.id", playing_id);
      sqlda = (XSQLDA ISC_FAR *) malloc(XSQLDA_LENGTH(7));
      sqlda->sqln = 7;
      sqlda->sqld = 7;
      sqlda->version = SQLDA_VERSION1;

      stat = save_err(isc_dsql_prepare(status, &trans, &stmt, 0, query, SQL_DIALECT_V6, sqlda));
   }
   if(!stat)
   {
      i = 0;
      sqlda->sqlvar[i].sqldata = (char ISC_FAR *)id;
      sqlda->sqlvar[i].sqlind  = (short ISC_FAR *)(flag+i);
      sqlda->sqlvar[i].sqltype = SQL_INT64 + 1;
      i++;

      sqlda->sqlvar[i].sqldata = (char ISC_FAR *)test_result;
      sqlda->sqlvar[i].sqlind  = (short ISC_FAR *)(flag+i);
      sqlda->sqlvar[i].sqltype = SQL_LONG + 1;
      i++;

      sqlda->sqlvar[i].sqldata = (char ISC_FAR *)compiler;
      sqlda->sqlvar[i].sqlind  = (short ISC_FAR *)(flag+i);
      sqlda->sqlvar[i].sqltype = SQL_SHORT + 1;
      i++;

      sqlda->sqlvar[i].sqldata = (char ISC_FAR *)&blob_id;
      sqlda->sqlvar[i].sqlind  = (short ISC_FAR *)(flag+i);
      sqlda->sqlvar[i].sqltype = SQL_BLOB + 1;
      i++;

      sqlda->sqlvar[i].sqldata = (char ISC_FAR *)k;//error
      sqlda->sqlvar[i].sqlind  = (short ISC_FAR *)(flag+i);
      sqlda->sqlvar[i].sqltype = SQL_LONG + 1;
      i++;

      sqlda->sqlvar[i].sqldata = (char ISC_FAR *)(k+1);//ok
      sqlda->sqlvar[i].sqlind  = (short ISC_FAR *)(flag+i);
      sqlda->sqlvar[i].sqltype = SQL_LONG + 1;
      i++;

      sqlda->sqlvar[i].sqldata = (char ISC_FAR *)(k+2);//number
      sqlda->sqlvar[i].sqlind  = (short ISC_FAR *)(flag+i);
      sqlda->sqlvar[i].sqltype = SQL_LONG + 1;
      i++;

      stat = save_err(isc_dsql_execute(status, &trans, &stmt, SQL_DIALECT_V6, NULL));
      if(stat)
      {
          if (tr_nl) rollback_trans(trans);
          free(sqlda);
         save_err(isc_dsql_free_statement(status, &stmt, DSQL_close));
         return stat;
      }
   }
   while(!isc_dsql_fetch(status, &stmt, SQL_DIALECT_V6, sqlda) && !stat)
   {
      plr = new CPlayer();
       plr->id = *id;
       plr->test_result = *test_result;
      plr->count_err = k[0];
      plr->count_ok  = k[1];
      plr->number = k[2];
      for(VCCompilers::iterator it = Compilers.begin(); it != Compilers.end(); it++)
         if((*it)->id == *compiler)
         {
            plr->compil = *it;
            break;
         }

      if(!plr->compil)
      {
         plr->status = st_compilation_error;
         return stat;
      }
      _itoa_s((int)plr->id, plr->id_s, 32, 16);
      sprintf_s(plr->srcfile, "%s%s", dir, plr->compil->FileIn);
      StrReplace(plr->srcfile, REPLACE_ID, plr->id_s);
      stat = GetBlobTxt(trans, &blob_id, plr->srcfile) || plr->Compile(dir);
      plrs->push_back(plr);
   }

   if(sqlda) free(sqlda);
   save_err(isc_dsql_free_statement(status, &stmt, DSQL_close));
   if (tr_nl) stat ? rollback_trans(trans) : commit_trans(trans);

   if(stat){
      sprintf_s(logfile.str, "Ошибка при отборе игроков игры %u", playing_id);
      logfile.Write(4);
   } else {
      sprintf_s(logfile.str, "Отобраны игроки игры %u", playing_id);
      logfile.Write(8);
   }

   return stat;
}

int CDataBase::SavePlayerTestResult(isc_tr_handle trans, CPlayer *plr)
{
   int stat = 0;
   int tr_nl = (trans == NULL);

   sprintf_s(query, "update gm_slv set test_result=%d, mem=%d, time_game=%d, time_move=%d, move=%d where id=%d",
      (int)(plr->status)-int(st_ok), plr->lmts.max_mem, plr->lmts.max_tm_game, plr->lmts.max_tm_move, plr->lmts.max_move, plr->id);
   
   if(tr_nl) stat = save_err(isc_start_transaction(status, &trans, 1, &db, 0, NULL));
   stat = stat || SqlExecute(query, trans);
   if(tr_nl) stat ? rollback_trans(trans) : commit_trans(trans); 

   return stat;
}

int CDataBase::SaveGameResult(isc_tr_handle trans, IDENTITY playing_id, VCPlayers *plrs, char *gamelog)
{
   int stat = 0;
   int tr_nl = (trans == NULL);

   if(tr_nl) stat = save_err(isc_start_transaction(status, &trans, 1, &db, 0, NULL));

   sprintf_s(query, "update playing set state = %d", game_state_played);
   sprintf_s(query, "%s, finish = CURRENT_TIMESTAMP, logfile='%s'", query, gamelog);
   sprintf_s(query, "%s where id = %d", query, playing_id);
   stat = stat || SqlExecute(query, trans);

   for(VCPlayers::iterator it = plrs->begin(); it != plrs->end() && !stat; it++)
   {
/*      
      sprintf_s(query, 
"update slv_play \
set result=%d, rank=%d, points=%d, mem=%d, time_game%d, time_move=%d, move=%d \
where id_playing=%d and id_gm_slv = %d and number = %d",
(*it)->stat, (*it)->rank, (*it)->points, (*it)->lmts.max_mem, (*it)->lmts.max_tm_game, (*it)->lmts.max_tm_move, (*it)->lmts.max_move,
playing_id, (*it)->id, (*it)->number);
*/
      sprintf_s(query, "update slv_play set result=%u, ", int((*it)->status) - int(st_ok));
      sprintf_s(query, "%s rank=%u, ", query, (*it)->rank);
      sprintf_s(query, "%s points=%u, ", query, (*it)->points);
      sprintf_s(query, "%s mem=%u, ", query, (*it)->lmts.max_mem);
      sprintf_s(query, "%s time_game=%u, ", query, (*it)->lmts.max_tm_game);
      sprintf_s(query, "%s time_move=%u, ", query, (*it)->lmts.max_tm_move);
      sprintf_s(query, "%s move=%u ", query, (*it)->lmts.max_move);
      sprintf_s(query, "%s where id_playing=%u and ", query, playing_id);
      sprintf_s(query, "%s id_gm_slv = %u and ", query, (*it)->id);
      sprintf_s(query, "%s number = %u", query, (*it)->number);

      stat = SqlExecute(query, trans);
   }

   if (tr_nl) stat ? rollback_trans(trans) : commit_trans(trans);

   if(stat){
      sprintf_s(logfile.str, "Ошибка при сохранении результатов игры %u", playing_id);
      logfile.Write(4);
   } else {
      sprintf_s(logfile.str, "Сохранены результаты игры %u", playing_id);
      logfile.Write(8);
   }

    return stat;
}

int CDataBase::SetBlobTxt(isc_tr_handle trans, isc_blob_handle *blob_handle, char *filename)
{
   int stat = 0;
   FILE *f;
   char buf[1024];
   unsigned short len_readed;

   fopen_s(&f, filename, "rb");
   while(!feof(f) && !stat)
   {
      len_readed = (unsigned short)fread(buf, sizeof(char), 1000, f);
      stat = stat || save_err(isc_put_segment(status, blob_handle, len_readed, buf));
   }

   fclose(f);
   return stat;
}

int CDataBase::UpdateCompilOut(isc_tr_handle trans, IDENTITY id, char *filename)
{
   int stat = 0;
   int tr_nl = (trans == NULL);
   //XSQLDA ISC_FAR *sqlda = 0;
   //ISC_QUAD blob_id;
   //isc_blob_handle blob_handle = NULL;

   sprintf_s(query, "update gm_slv set compilfile = '%s' where id = %d", filename, id);
   if(tr_nl) stat = save_err(isc_start_transaction(status, &trans, 1, &db, 0, NULL));
   stat = stat || SqlExecute(query, trans);
/*   
   sprintf_s(query, "update gm_slv set compil_out = ? where id = %d", id);
   if(tr_nl) stat = save_err(isc_start_transaction(status, &trans, 1, &db, 0, NULL));

   if(!stat)
   {
      sqlda = (XSQLDA ISC_FAR *) malloc(XSQLDA_LENGTH(1));
      ZeroMemory(sqlda, XSQLDA_LENGTH(1));
      //memset(sqlda, 0, XSQLDA_LENGTH(1));
      sqlda->sqln = 1;
      sqlda->sqld = 1;
      sqlda->version = 1;

      sqlda->sqlvar[0].sqldata = (char ISC_FAR *)&blob_id;
      sqlda->sqlvar[0].sqltype = SQL_BLOB+1;
      sqlda->sqlvar[0].sqllen = sizeof(ISC_QUAD);

      blob_handle = 0;
      stat = save_err(isc_create_blob2(status, &db, &trans, &blob_handle, &blob_id, 0, NULL));
   }

   stat = stat || SetBlobTxt(trans, &blob_handle, filename);

   stat = stat || save_err(isc_close_blob(status, &blob_handle));
   stat = stat || save_err(isc_dsql_execute_immediate(status, &db, &trans, 0, query, SQL_DIALECT_V6, sqlda));

   if (tr_nl) save_err((stat ? isc_rollback_transaction : isc_commit_transaction)(status, &trans));
 */

   //if(sqlda) free(sqlda);
   if (tr_nl) stat ? rollback_trans(trans) : commit_trans(trans);
   
   return stat;
}


int CDataBase::InsertPlayingFull2(isc_tr_handle trans, IDENTITY trnmnt_id, IDENTITY plr_id)
{
   int stat = 0, i = 0;
   int tr_nl = (trans == NULL);
   XSQLDA ISC_FAR *sqlda;   
   short flag[1];
   long isError = 0;

   sprintf_s(query, "select isError from AddNewGamesFull(%u", plr_id);
   sprintf_s(query, "%s, %u)", query, trnmnt_id);
   if(tr_nl) stat = save_err(isc_start_transaction(status, &trans, 1, &db, 0, NULL));
   if(!stat)
   {
      sqlda = (XSQLDA ISC_FAR *) malloc(XSQLDA_LENGTH(1));
      sqlda->sqln = 1;
      sqlda->sqld = 1;
      sqlda->version = 1;

      stat = save_err(isc_dsql_prepare(status, &trans, &stmt, 0, query, SQL_DIALECT_V6, sqlda));
   }
   if(!stat)
   {
      i = 0;
      sqlda->sqlvar[i].sqldata = (char ISC_FAR *)&isError;
      sqlda->sqlvar[i].sqlind  = (short ISC_FAR *)(flag+i);
      sqlda->sqlvar[i].sqltype = SQL_LONG + 1;
      i++;
   
      stat = save_err(isc_dsql_execute(status, &trans, &stmt, SQL_DIALECT_V6, NULL));
      if(stat)
      {
         if (tr_nl) rollback_trans(trans);
         save_err(isc_dsql_free_statement(status, &stmt, DSQL_close));
          free(sqlda);
         return stat;
      }
      stat = isc_dsql_fetch(status, &stmt, SQL_DIALECT_V6, sqlda);
      if(!stat)
      {
         stat = isError;         
      }
   }

   save_err(isc_dsql_free_statement(status, &stmt, DSQL_close));
   if(sqlda) free(sqlda);

   if(tr_nl) stat ? rollback_trans(trans) : commit_trans(trans);

   if(stat){
      sprintf_s(logfile.str, "Ошибка при создании новых партий игр с игроком %u", plr_id);
      logfile.Write(1);
   } else {
      sprintf_s(logfile.str, "Добавлены новые партии игр с игроком %u", plr_id);
      logfile.Write(8);
   }

   return stat;
}

int CDataBase::GetFinishedTournaments(isc_tr_handle trans, TTournament *trnmnt)
{
   char query[255];
   XSQLDA ISC_FAR *sqlda;
   int stat = 0, i;
   short flag[1];
   int tr_nl = (trans == NULL);

   if(tr_nl) stat = save_err(isc_start_transaction(status, &trans, 1, &db, 0, NULL));

   if(!stat)
   {
      sprintf_s(query, "select tournaments.id from tournaments where dt_finish > CURRENT_TIMESTAMP and state = %d", 2);//going
      sqlda = (XSQLDA ISC_FAR *) malloc(XSQLDA_LENGTH(1));
      sqlda->sqln = 1;
      sqlda->sqld = 1;
      sqlda->version = 1;

      stat = save_err(isc_dsql_prepare(status, &trans, &stmt, 0, query, SQL_DIALECT_V6, sqlda));
   }
   if(!stat)
   {
      i = 0;
      sqlda->sqlvar[i].sqldata = (char ISC_FAR *)&trnmnt->id;
      sqlda->sqlvar[i].sqlind  = (short ISC_FAR *)(flag+i);
      sqlda->sqlvar[i].sqltype = SQL_INT64 + 1;
      i++;

      stat = save_err(isc_dsql_execute(status, &trans, &stmt, SQL_DIALECT_V6, NULL));
      if(stat)
      {
          if (tr_nl) rollback_trans(trans);
         save_err(isc_dsql_free_statement(status, &stmt, DSQL_close));
         free(sqlda);
         return stat;
      }
   }

   save_err(isc_dsql_fetch(status, &stmt, SQL_DIALECT_V6, sqlda));

   save_err(isc_dsql_free_statement(status, &stmt, DSQL_close));
   free(sqlda);

   if (tr_nl) stat ? rollback_trans(trans) : commit_trans(trans);  
   return stat;
}

CDataBase DB[1];
