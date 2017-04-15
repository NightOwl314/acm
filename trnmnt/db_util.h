#ifndef db_util_
#define db_util_

#include "trnmnt.h"
#include "party.h"

#include "ibase.h"
#include "iberror.h"


class CDataBase 
{
   private:
      isc_db_handle db; //контекст базы данных
      isc_stmt_handle stmt;  //контекст запроса к БД
      //контекст транзакции блокирующей запись данного сервера

      ISC_STATUS status[40]; //состояние БД после выполнения какай-либо команды
      int Error;

      char query[300];
      
      int save_err(int err); //проверка и сохранение ошибки      
      char strim[10];

   public:
      CDataBase()
      {
         db = NULL; stmt = NULL;
         strim[0] = ' ';
         strim[1] = '\t';
         strim[2] = '\r';
         strim[3] = '\n';
         strim[4] = -52;
         strim[5] = 0;
      };
      ~CDataBase(){  if (db!=NULL) Disconnect();  };

      //соединение с БД
      int Connect(char *file, char *username, char *password);
      int Disconnect(); //разорвать соединение с БД

      int SqlExecute(char *query, isc_tr_handle trans=NULL);
      int Gen_ID(const char *name_gen, IDENTITY *id, isc_tr_handle trans, int k);

      //функции для работы с транзакциями
      isc_tr_handle start_trans(int type=0);
      int commit_trans(isc_tr_handle trans);
      int rollback_trans(isc_tr_handle trans);
      
      int GetGameForPlay(isc_tr_handle trans, IDENTITY *id);

      int GetTournamentData(isc_tr_handle trans, IDENTITY id, TTournament *trnmnt);
      int GetTournamentId(isc_tr_handle trans, IDENTITY playing_id, IDENTITY *id);
      int GetTournamentDataEx(isc_tr_handle trans, IDENTITY id, TTournament *trnmnt)
      {
         /* GetTournamentId + GetTournamentData в одном запросе */
         int stat = 0;

         stat = GetTournamentId(trans, id, &trnmnt->id);
         stat = stat || GetTournamentData(trans, trnmnt->id, trnmnt);

         return stat;
      }
      int GetPlayers(isc_tr_handle trans, IDENTITY playing_id, VCPlayers *plrs, char *dir);
      int SavePlayerTestResult(isc_tr_handle trans, CPlayer *plr);
      int SaveGameResult(isc_tr_handle trans, IDENTITY playing_id, VCPlayers *plrs, char *gamelog);
      int GetNewSolution(isc_tr_handle trans, CPlayer **plr);
      int GetBlobTxt(isc_tr_handle trans, ISC_QUAD *blob_id, char *filename);
      int SetBlobTxt(isc_tr_handle trans, isc_blob_handle *blob_handle, char *filename);
      int UpdateCompilOut(isc_tr_handle trans, IDENTITY id, char *filename);

      int InsertPlayingFull2(isc_tr_handle trans, IDENTITY trnmnt_id, IDENTITY plr_id);
      int GetFinishedTournaments(isc_tr_handle trans, TTournament *trnmnt);     
};



extern CDataBase DB[1]; 

#endif
