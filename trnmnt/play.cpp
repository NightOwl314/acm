#include "play.h"
#include "party.h"
#include "db_util.h"
#include "log.h"
#include "trnmnt.h"


static unsigned Str2Int(char *s)
{
   unsigned r = 0;
   while(*s && ((s[0] < '0') || (s[0] > '9'))) s++;
   while((s[0] >= '0') && (s[0] <= '9') && (r <= 10000000))
   {
      r += 10*r + unsigned(s[0] - '0');
      s++;
   }
   return r;
}


int play_game(CChecker* chk, VCPlayers plrs, TLimits lmts, char *gamelog = NULL)
{
   int stat = 0, count_moves = 0;
   VCPlayers::iterator it;
   unsigned i, j, N = 0;
   char status;
   UINT old_err_st;
   FILE *f = NULL;

   //extern char USER[MAX_STR_SHORT_LEN];
   //extern char PASSWORD[MAX_STR_SHORT_LEN];
   
   //не показывать сообщения об ошибках
   old_err_st = SetErrorMode(SEM_NOGPFAULTERRORBOX);

   sprintf_s(logfile.str, "Запуск чекера [%s]", chk->exefile);
   logfile.Write(7);
   stat = chk->Run();
   if(stat)
   {
      sprintf_s(logfile.str, "Ошибка при запуске чекера [%s]", chk->exefile);
      logfile.Write(0);
      return stat;
   }

   //запускаем программы игроков
   for(it = plrs.begin(); it != plrs.end(); it++)
   {
      sprintf_s(logfile.str, "Запуск игрока [%s]", (*it)->exefile);
      logfile.Write(7);
      if((*it)->Run())
      {
         sprintf_s(logfile.str, "Ошибка при запуске игрока [%s]", (*it)->exefile);
         logfile.Write(2);
      }
   }

   if(gamelog)
   {
      fopen_s(&f, gamelog, "w+t");
      if(!f)
      {
         sprintf_s(logfile.str, "Лог-файл игры не открыт [%s]", gamelog);
         logfile.Write(2);
      }
   }

   sprintf_s(logfile.str, "Передаем чекеру количество игроков [%d]", plrs.size());
   logfile.Write(7);
   sprintf_s(chk->buf, "%d\n", plrs.size());
   stat = chk->GiveData(chk->buf);
   if(f)
   {
      fprintf(f, "var K = %d;\n", plrs.size());
      fflush(f);
   }

   if(!stat)
   {
      sprintf_s(logfile.str, "Принимаем кол-во строк инициализации");
      logfile.Write(8);
      stat = chk->GetData();
   }
   if(!stat)
   {
      N = int(chk->buf[0]) - int('0');
      if(f)
      {
         fprintf(f, "\nvar N = %d;\nvar a1 = new Array();\n", N);
         fflush(f);
      }

      for(j = 0; j < N && !stat; j++)
      {
         //читаем у чекера очередную строку
         stat = chk->GetData();
         //и передаем ее всем игрокам
         if(!stat)
         {
            for(i = 0; i < plrs.size(); i++)
              plrs[i]->GiveData(chk->buf);
            if(f)
            {
               chk->buf[strlen(chk->buf)-1] = 0;
               fprintf(f, "   a1[%d] = \"%s\";\n", j, chk->buf);
               fflush(f);
            }
         }
      }
   }
   
   if(f && !stat)
   {
      fprintf(f, "\nvar a2 = new Array();\n");
      fflush(f);
   }
   for(i = 0; !stat && i < plrs.size(); i++)
   {
      //читаем строку
      stat = chk->GetData();
      //передаем ее конкретному игроку
      if(!stat)
      {
         plrs[i]->GiveData(chk->buf);
         //приостанавливаем игрока
         //while(SuspendThread(plrs[i]->piProcInfo.hThread) > 1);
         if(f)
         {
            chk->buf[strlen(chk->buf)-1] = 0;
            fprintf(f, "   a2[%d] = \"%s\";\n", i, chk->buf);
            fflush(f);
         }
      }
   }
   
   if(f && !stat)
   {
      fprintf(f, "\nvar a3 = new Array();\n");
      fflush(f);
   }
   //играем!!!
   status = 0;
   if(!stat)
   {
      sprintf_s(logfile.str, "Игра начата...");
      logfile.Write(8);
   }
   for(i = 0; !stat && !status; )
   {
      sprintf_s(logfile.str, "Получаем ход очередного игрока %d", plrs[i]->id);
      logfile.Write(8);
      plrs[i]->GetData();
      plrs[i]->UpdateStatus(&lmts);
      N = i;
      stat = chk->GiveData(plrs[i]->buf) || chk->GetData();
      if(!stat)
      {
         sprintf_s(logfile.str, "Получен ответ от чекера %c", chk->buf[0]);
         logfile.Write(8);
         switch (chk->buf[0])
         {
         case st_ok_give_all://передаем ход всем игрокам
            for(j = 0; j < plrs.size(); j++)
               if(j != i)
                  plrs[j]->GiveData(plrs[i]->buf+2);
         //проваливаемся

         case st_ok_notgive:            
            i = int(chk->buf[2]) - int('1');//номер следующего игрока
         break;

         case st_end_give_all:
            for(j = 0; j < plrs.size(); j++)
               if(j != i)
                  plrs[j]->GiveData(plrs[i]->buf+2);
         //проваливаемся

         case st_end_ok:
            status = -2;
         break;
         default: status = -1;
         }
      }
      if(f && !stat && (status != -1))
      {
         //проверка на статус
         if((st_end_give_all== chk->buf[0]) || 
            (st_ok_notgive  == chk->buf[0]) ||
            (st_ok_give_all == chk->buf[0]) ||
            (st_end_ok      == chk->buf[0])
         )
         {
            trim(plrs[N]->buf, " \t\r\n");
            fprintf(f, "   a3[%d] = new Object();\n",       count_moves);
            fprintf(f, "      a3[%d].Player = %d;\n",       count_moves, N);
            fprintf(f, "      a3[%d].State  = \"%c\";\n",   count_moves, plrs[N]->status);
            fprintf(f, "      a3[%d].Move   = \"%s\";\n\n", count_moves, plrs[N]->buf+2);
            count_moves++;
            fflush(f);
         } else
         {
            trim(plrs[N]->buf, " \t\r\n");
            fprintf(f, "   a3[%d] = new Object();\n",       count_moves);
            fprintf(f, "      a3[%d].Player = %d;\n",       count_moves, N);
            fprintf(f, "      a3[%d].State  = \"%c\";\n",   count_moves, plrs[N]->status);
            fprintf(f, "      a3[%d].Move   = \" \";\n\n",  count_moves);//Ход в лог не выводим
            count_moves++;
            fflush(f);
         }
      }
   }

   sprintf_s(logfile.str, "Останавливаем игроков");
   logfile.Write(8);
   for(it = plrs.begin(); it != plrs.end(); it++)      
      (*it)->Stop();

   sprintf_s(logfile.str, "Передаем чекеру информацию об игроках");
   logfile.Write(8);
   for(i = 0; !stat && i < plrs.size(); i++)
   {
      sprintf_s(chk->buf, "%c %d %d\n", plrs[i]->status, plrs[i]->count_ok, plrs[i]->count_err);
      stat = chk->GiveData(chk->buf);
   }

   sprintf_s(logfile.str, "Принимаем от чекера информацию об игроках");
   logfile.Write(8);
   for(i = 0; !stat && i < plrs.size(); i++)
   {
      stat = chk->GetData();
      sprintf_s(logfile.str, "Получена информация об игроке %d", plrs[i]->id);
      logfile.Write(8);
      if(!stat)
      {
         //формат: 
         //{статус}_{место}_{набранные баллы}
         //обновляем сведения об участниках
         plrs[i]->SetStatus(int(chk->buf[0]));
         plrs[i]->rank = int(chk->buf[2]) - int('0');
         plrs[i]->points = Str2Int(chk->buf+4);
      }
   }
   
   //останавливаем чекера
   chk->Stop();

   if(f) fclose(f);

   //восстановим начальную обработку ошибок
   SetErrorMode(old_err_st);

   return stat;
}

int check_new()
{
   int stat = 0;
   TTournament trnmnt;
   isc_tr_handle snapshot;
   CPlayer *plr, plr2[1];
   CChecker chk[1];
   VCPlayers plrs;
   
   snapshot = DB->start_trans(0); //создать транзакцию snapshot
   if(!snapshot)
   {
      sprintf_s(logfile.str, "Ошибка транзакции");
      logfile.Write(5);
      return -1;
   }

   //отбираем непроверенное решение
   stat = DB->GetNewSolution(snapshot, &plr);
   if(stat)
   {
      DB->rollback_trans(snapshot);
      return stat;
   }
   if(!plr)
   {
      //нет новых решений
       DB->rollback_trans(snapshot);
       return 0;
   }
   if(!stat && (plr->status == st_ok))
   {
      sprintf_s(logfile.str, "Тестовая проверка нового решения №%d", plr->id);
      logfile.Write(2);

      sprintf_s(logfile.str, "Получение данных о турнире №%d", plr->id_trnmnt);
      logfile.Write(2);
      stat = DB->GetTournamentData(snapshot, plr->id_trnmnt, &trnmnt);
   }
   if(!stat && (plr->status == st_ok))
   {
      StrCopy(chk->exefile, trnmnt.chk_prg, MAX_STR_LEN);
      if(!FileExists(trnmnt.tst_prg)) trnmnt.tst_prg[0] = 0;
      //формируем участников
      if(trnmnt.tst_prg[0])
      {
         plrs.push_back(plr);//проверяемое решение
         //и еще ему противника нада
         *plr2 = *plr;
         plrs.push_back(plr2);
      } else
      {
         //новое решение будет играть само с собой
         plrs.push_back(plr);
         *plr2 = *plr;
         plrs.push_back(plr2);
      }
      sprintf_s(logfile.str, "Проведение тестовой игры");
      logfile.Write(2);
      stat = play_game(chk, plrs, trnmnt.limits);
   }

   if(!stat)
   {
      sprintf_s(logfile.str, "Сохранение результатов тестовой проверки");
      logfile.Write(2);
      //если играло само с собой - выберем с наихудшим результатом :)
      if(!trnmnt.tst_prg[0])
      {
         if(plr2->status > plr->status)
            *plr = *plr2;
      }
      stat = DB->SavePlayerTestResult(snapshot, plr);
   }

   if(stat)
   {
       DB->rollback_trans(snapshot);
       //теперь игроки не нужны - дестракшен их:)
       delete plr;
       return stat;
   }

   //формируем партии игр для нового решения
   if(plr->status == st_ok)
   {
      if(trnmnt.type == 1)
      {
         sprintf_s(logfile.str, "Добавление новых партий игр");
         logfile.Write(2);
         stat = DB->InsertPlayingFull2(snapshot, trnmnt.id, plr->id);
      }      
   }
   
   stat ? DB->rollback_trans(snapshot) : DB->commit_trans(snapshot);
   
   delete plr;
   return stat;
}


int check_playing(char *GameFolder)
{
   int stat = 0;
   IDENTITY playing_id, trnmnt_id;
   TTournament trnmnt;
   isc_tr_handle snapshot;
   VCPlayers plrs;
   CChecker chk[1];
   char filename[MAX_STR_LEN];
   char gamelog[MAX_STR_LEN];
   char id_s[32];

   snapshot = DB->start_trans(1); //создать транзакцию snapshot
   if(!snapshot)
   {
      sprintf_s(logfile.str, "Ошибка транзакции");
      logfile.Write(5);
      return -1;
   }
   StrCopy(gamelog, LogFileName, MAX_STR_LEN);
   stat = DB->GetGameForPlay(snapshot, &playing_id);
   if(stat)
   {
      DB->rollback_trans(snapshot);
      return stat;
   }
   if(!playing_id)
   {
       //нет игр
       DB->rollback_trans(snapshot);
       return 0;
   }

   sprintf_s(logfile.str, "Проведение партии игры №%d", playing_id);
   logfile.Write(2);
   
   _itoa_s((int)playing_id, id_s, 32, 10);
   sprintf_s(filename, "%s%s\\", PlayDir, GameFolder);
   StrReplace(filename, REPLACE_ID, id_s);
   CreateDirectory(filename, NULL);
   StrReplace(gamelog, REPLACE_ID, id_s);
   //if(stat) return stat;

   sprintf_s(logfile.str, "Получение данных об игроках");
   logfile.Write(2);
   stat = DB->GetPlayers(snapshot, playing_id, &plrs, filename);
   if(stat)
   {
      sprintf_s(logfile.str, "Ошибка при получении данных об игроках");
      logfile.Write(2);
      for(VCPlayers::iterator it = plrs.begin(); it != plrs.end(); it++)
         delete *it;
   }

   if(!stat)
   {
      sprintf_s(logfile.str, "Получение данных о турнире");
      logfile.Write(2);
      stat = DB->GetTournamentId(snapshot, playing_id, &trnmnt_id) || DB->GetTournamentData(snapshot, trnmnt_id, &trnmnt);
   }
   if(!stat)
   {
      StrCopy(chk->exefile, trnmnt.chk_prg, MAX_STR_LEN);

      sprintf_s(logfile.str, "Проведение игры");
      logfile.Write(2);
    
      stat = play_game(chk, plrs, trnmnt.limits, gamelog);
      if(stat)
      {
         sprintf_s(logfile.str, "Игра %u завершена c ошибкой", playing_id);
         logfile.Write(7);
      }
   }

   if(!stat)
   {
      sprintf_s(logfile.str, "Игра %u завершена успешно", playing_id);
      logfile.Write(7);
      sprintf_s(logfile.str, "Сохранение результатов игры");
      logfile.Write(2);
      stat = DB->SaveGameResult(snapshot, playing_id, &plrs, gamelog);
   }
   //if(DeleteLog && FileExists(gamelog)) DeleteFile(gamelog);
    //теперь игроки не нужны - дестракшен их:)
    for(VCPlayers::iterator it = plrs.begin(); it != plrs.end(); it++)
    {
       (*it)->DeleteFiles(filename);
       delete *it;
    }

   //удаляем уже ненужные файлы и каталоги
   RemoveDirectory(filename);

   if(stat)
   {
       DB->rollback_trans(snapshot);
       return stat;
   }
   DB->commit_trans(snapshot);
   return 0;
}
