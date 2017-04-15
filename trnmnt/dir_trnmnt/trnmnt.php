<?php

   require_once("autor.php");
   

   
   function DisplayTrnmntById($id_user, $id_trnmnt, $access_level)
   {
      global $DB, $host, $dir_trnmnt;
      
      $query_str = "select tournaments.*, games.caption as name_game, games.gamefile as gamefile from tournaments, games";
      $query_str .= " where tournaments.id={$id_trnmnt} and games.id=tournaments.id_game";
      $query = ibase_query($DB, $query_str);
      $row = ibase_fetch_object($query);


      if(!$row)
      {
         echo "qweqwe";
         return NULL;
      }
 
      //check $access_level

      $row->CAPTION = trim($row->CAPTION);
      echo "<h2 align=\"center\">{$row->CAPTION}</h2>\n";
      echo "<h4 align=\"center\">Ограничения: {$row->MAX_MEM} КБ, {$row->MAX_TIME_GAME} мс на игру, {$row->MAX_TIME_MOVE} мс на ход, {$row->MAX_MOVE} ходов";
      echo "</h4>\n";

      if($access_level >= LVL_ADMIN)
      {
      /*
         echo "<table class=\"other\" width=\"97%\" border=\"0\"><tbody>\n<tr>";
         echo "   <td align=\"left\"><a href=\"{$host}{$dir_trnmnt}trnmnt.php?act=1&id_trnmnt={$id_trnmnt}\">Редатировать турнир</a></td>\n";
         echo "   <td align=\"right\"><a href=\"{$host}{$dir_trnmnt}trnmnt.php?act=2\">Добавить турнир</a></td>\n";
         echo "</tr>\n</tbody></table>\n";
      */
      }

      echo "<br>\n\n";
      $row->NAME_GAME = trim($row->NAME_GAME);      
      echo "<h3>{$row->NAME_GAME}</h3>\n";
      if($row->GAMEFILE)
      {
         $row->GAMEFILE = trim($row->GAMEFILE);
         if(file_exists($row->GAMEFILE))
         {
            echo "<hr>\n";
            include "{$row->GAMEFILE}";
            echo "<hr>\n";
         }
      }
      echo "\n<br>\n";
      ibase_blob_echo($row->DESCRIPTION);
      echo "<br><br>";      

      ibase_free_result($query);
   }



   //mode 1 - активные, 2 - завершенные 3 - все, иначе 1
   function DisplayTrnmnts($id_user, $mode, $access_level, $id_game)
   {
      global $DB, $host, $dir_trnmnt;
      
      $query_str = "select * from tournaments";
      switch ($mode)
      {
         case 2:
            $query_str .= " where dt_finish < CURRENT_TIMESTAMP";
         break;
            
         case 3:
            $query_str .= " where dt_start <= CURRENT_TIMESTAMP";
         break;
         
         default:
            $mode = 1;
            $query_str .= " where (dt_finish >= CURRENT_TIMESTAMP) and (dt_start <= CURRENT_TIMESTAMP)";
      }
      if($id_game) $query_str .= " and id_game={$id_game}";
      $query_str .= " order by dt_start, id";
      
      $query = ibase_query($DB, $query_str);
      $row = ibase_fetch_object($query);
      $k = 0;

      echo "<br>\n\n";
      
      while($row)
      {
          echo "<table class=\"tbbd2\" border=\"0\" width=\"90%\" align=\"center\">\n   <tbody valign=\"top\">\n";
          $k++;
          $row->CAPTION = trim($row->CAPTION);
          echo "\n   <tr><th align=\"center\" colspan=\"2\"><a href=\"{$host}{$dir_trnmnt}trnmnt.php?id_trnmnt={$row->ID}\"><h2>{$row->CAPTION}</h2></th></tr>\n";
          echo "   <tr><td class=\"other\">";
          echo "      <strong>Начало: {$row->DT_START}</strong><br><strong>Окончание: {$row->DT_FINISH}</strong><br><strong>Сложность: {$row->LVL}</strong>\n";
          echo "      <br><strong>Количество участников: {$row->COUNT_PLAYERS}</strong>\n";
          echo "      </td>\n";
          echo "      <td width=\"50%\">";
          if($access_level >= LVL_USER) 
             echo "       <a href=\"{$host}{$dir_trnmnt}submit.php?id_trnmnt={$row->ID}\">Отправить программу</a><br>\n";
          if(($access_level >= LVL_USER) && (($mode === 1) || ($row->TYPE === 1)))
             echo "       <a href=\"{$host}{$dir_trnmnt}results.php?id_trnmnt={$row->ID}\">Просмотр результатов</a><br>\n";
          if($access_level >= LVL_USER) 
             echo "       <a href=\"{$host}{$dir_trnmnt}parties.php?id_trnmnt={$row->ID}\">Просмотр участников</a><br>\n";
          if($access_level >= LVL_ADMIN) 
             echo "       <a href=\"{$host}{$dir_trnmnt}act_t.php?id_trnmnt={$row->ID}&act=1\">Редактирование</a><br>\n";
          echo "   </td></tr>\n";
          $row = ibase_fetch_object($query);
          echo "\n   </tbody>\n</table>\n\n<br>\n";
      }

         echo "<br><table class=\"other\" border=\"0\"><tbody>\n<tr>";

         echo "   <td align=\"right\"><a href=\"{$host}{$dir_trnmnt}trnmnt.php?mode=3";
         if($id_game) echo"&id_game={$id_game}";
         echo "\">&nbsp Все &nbsp</a></td>\n";

         echo "   <td align=\"right\"><a href=\"{$host}{$dir_trnmnt}trnmnt.php?mode=1";
         if($id_game) echo"&id_game={$id_game}";
         echo "\">&nbsp Активные &nbsp</a></td>\n";

         echo "   <td align=\"right\"><a href=\"{$host}{$dir_trnmnt}trnmnt.php?mode=2";
         if($id_game) echo"&id_game={$id_game}";
         echo "\">&nbsp Завершенные &nbsp</a></td>\n";

         echo "</tr>\n</tbody></table>\n\n";

      
      ibase_free_result($query);
   }
   


   //точка входа
   session_start();
   $DB = ibase_pconnect($db_name, $db_user, $db_password);
   if(!$DB)
   {
      echo "Ошибка соединения с базой данных...";
      exit;
   }
      
   list ($id_user, $user_name, $access_level) = autorize();
   if($access_level <= LVL_GUEST)
   {
      Header($RedirectGames);
      exit();
   }

   echo "<html>\n";
   DisplayHead();
   echo "<body>\n";
   DisplayHeadTable($access_level);
   DisplayLocalHead($id_user, $user_name);
  
   if(isset($_REQUEST['id_trnmnt']))
   {
      $id_trnmnt = $_REQUEST['id_trnmnt'];
      settype($id_trnmnt, 'integer');
   }   
   else $id_trnmnt = false;

   if(isset($_REQUEST['mode']))
   {
      $mode = $_REQUEST['mode'];
      settype($mode, 'integer');
   }   
   else $mode = 1;

   if(isset($_REQUEST['id_game']))
   {
      $id_game = $_REQUEST['id_game'];
      settype($id_game, 'integer');
   }   
   else $id_game = false;


   if($id_trnmnt !== false)
      DisplayTrnmntById($id_user, $id_trnmnt, $access_level);
   else
      DisplayTrnmnts($id_user, $mode, $access_level, $id_game);
   
   ibase_close($DB);
   echo "\n</body></html>";
?>