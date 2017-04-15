<?php

   $host = '/';
   $dir_trnmnt = 'trnmnt/';
   $game_dir = "c:/acm/trnmnt/web/";

   $db_user = 'sysdba';
   $db_password = 'avtfbpas';
   $db_name = 'localhost:c:\acm\db\acm.gdb';
   $RedirectGames = "Location: {$host}{$dir_trnmnt}games.php";

   define("ACT_UPDATE",   1); 
   define("ACT_INSERT",   2);


   define("LVL_GUEST",   10);
   define("LVL_USER",    20);
   define("LVL_TEACHER", 30);
   define("LVL_ADMIN",   50);

   /*
   st_ok,                // 0   a
   st_end_ok,            // 1   b
   st_end_give_all,      // 2   c
   st_ok_give_all,       // 3   d
   st_ok_notgive,        // 4   e     
   st_end_error,         // 5   f
                         
   st_unique_error,      // 6   g
   st_time_limit_move,   // 7   h
   st_time_limit_game,   // 8   i
   st_memory_limit,      // 9   j
   st_move_limit,        // 10  k
   st_sleep_detect,      // 11  l
   st_buffer_overflow,   // 12  m
   st_presentation_error,// 13  n
   st_wrong_move,        // 14  o
   st_run_time_error,    // 15  p
   st_security_violation,// 16  q
   st_compilation_error, // 17  r
   */


   $results[-1] = "Не проверено";
   $results[0]  = "Нет ошибки";
   $results[7]  = "Предел времени на ход";
   $results[8]  = "Предел времени на игру";
   $results[9]  = "Предел памяти";
   $results[10] = "Предел количества ходов";
   $results[12] = "Переполнение буфера";
   $results[13] = "Ошибка представления";
   $results[14] = "Неверный ход";
   $results[15] = "Ошибка выполнения";
   $results[17] = "Ошибка компиляции";



   function autorize()
   {  
      global $DB;

      if(isset($_SESSION['trnmnt_user'])) $user_id = $_SESSION['trnmnt_user'];
      else $user_id = 0;
/*
      if(isset($_REQUEST['trnmnt_user'])) $user_id = $_REQUEST['trnmnt_user'];
      else $user_id = 0;
*/
      settype($user_id, 'integer');

      $level = LVL_GUEST;
      $user_name = "Гость";
      
      if($user_id)
      {
          $query_str = "select * from authors where id_publ = {$user_id}";
          $query = ibase_query($DB, $query_str);
          $row = ibase_fetch_object($query);
          if($row)
          {
             $user_name = trim($row->NAME);
             $level = LVL_USER;
             //$level = LVL_ADMIN;
          } else $user_id = 0;
          ibase_free_result($query);
      }
      return array($user_id, $user_name, $level);
   }



   function DisplayLocalHead($id_user, $user_name)
   {
      global $host, $dir_trnmnt;
      
      echo "\n\n<table class=\"other\" border=\"0\" width=\"100%\">\n<tbody>\n<tr>\n";
      if($id_user > 0)
         echo "   <td>Вы вошли в систему как <a href=\"{$host}{$dir_trnmnt}stats.php?id_autor={$id_user}\">{$user_name}</a></td>";
      else
         echo "   <td>Здравствуйте! Ну что же вы не представитесь, <strong>Гость</strong>!\n <a href=\"{$host}{$dir_trnmnt}login.php\">Войдите с паролем</a> или <a href=\"http://atpp.vstu.edu.ru/cgi-bin/aregister.pl\">зарегистрируйтесь</a>.</td>";
      echo "\n</tr>\n";
      echo "</tbody></table>\n\n\n";

      return NULL;   
   }



   function DisplayHeadTable($access)
   {
      echo "<table border=\"0\" cellpadding=\"0\" cellspacing=\"0\" width=\"100%\">\n".
           "<tbody>\n".
           "<tr><td valign=\"top\">\n".
           "   <table class=\"tbhead\" align=\"center\" border=\"1\" cellpadding=\"5\" width=\"100%\"><tbody>\n".
           "   <tr align=\"center\">\n".
           "      <td width=\"90\"><a href=\"http://atpp.vstu.edu.ru/\" style=\"border: 0px none ;\"><img alt=\"АВТ\" src=\"atpphead2.gif\" align=\"middle\" border=\"0\" height=\"69\" width=\"73\"></a></td>\n".
           "      <td width=\"*\"><h1 align=\"center\" style=\"font-size:24pt\"><a href=\"trnmnt.php\">Турниры игровых компьютерных программ</a></h1></td>\n";
      echo "      <td align=\"center\" nowrap=\"nowrap\" width=\"200\">";

      echo "<a href=\"login.php\">Вход</a><br>";
      echo "<a href=\"http://atpp.vstu.edu.ru/cgi-bin/aregister.pl\">Регистрация</a><br>";
      //if($access >= LVL_USER) echo "<a href=\"stats.php\">Рейтинг авторов</a><br>";

      echo "      </td>\n   </tr>\n".
           "   </tbody></table>\n".
           "</td></tr></tbody></table>\n\n";

      return NULL;
   }



   function DisplayHead()
   {
      echo "<head>\n".
           "<meta http-equiv=\"Content-Type\" content=\"text/html; charset=windows-1251\"><title>АВТ ВоГТУ - Турниры игровых компьютерных пограмм</title>\n".
           "   <link rel=\"STYLESHEET\" type=\"text/css\" href=\"trnmnt.css\">\n".
           "</head>\n\n";

     return NULL;
   }
?>
