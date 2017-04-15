<?php

   require_once("autor.php");
   
   
   function viewgame($id_user, $id_playing, $access_level)
   {
      global $DB, $host, $dir_trnmnt, $results;

      $query_str = "select * from playing where id={$id_playing}";
      $query = ibase_query($DB, $query_str);
      $gm = ibase_fetch_object($query);
      ibase_free_result($query);
      if(!$gm)
      {
         return;
      }

      echo "<h2 align=\"center\"><a href=\"{$host}{$dir_trnmnt}play.php?id={$id_playing}\">Просмотр партии игры</a></h2><br>\n";
      if($gm->STATE === 2)
      {
         echo "<h5 align=\"center\">Начало: {$gm->START}, завершение: {$gm->FINISH}</h5><br>\n";
      }
      echo "<h3 align=\"center\">Участники игры</h3>\n";

      echo "<table class=\"tbbd2\" align=\"center\" border=\"1\" cellspacing=\"1\" width=\"100%\">\n<tbody>\n";
      echo " <tr>\n";
      echo "   <th>Номер</th> <th>Автор</th> <th>Программа</th> <th>Компилятор</th> <th>Результат</th> <th>Очки</th> ";
      echo "<th>Память</th> <th>Ходы</th> <th>Время на ход</th> <th>Время игры</th>\n</tr>\n";

      $query_str = "select slv_play.*, gm_slv.caption as cptn, compil.name as cmpl, authors.name as autor ".
                   "from slv_play, authors, compil, gm_slv ".
                   "where slv_play.id_playing={$id_playing} and slv_play.id_gm_slv=gm_slv.id and ".
                   "gm_slv.compiler=compil.id_cmp and gm_slv.id_player=authors.id_publ ".
                   "order by slv_play.number";
      $query = ibase_query($DB, $query_str);
      $row = ibase_fetch_object($query);
      while($row)
      {
         $row->CPTN  = trim($row->CPTN);
         $row->CMPL  = trim($row->CMPL);
         $row->AUTOR = trim($row->AUTOR);
         echo "\n <tr align=\"center\">\n";
         
         echo "   <td>{$row->NUMBER}</td>";
         echo " <td>{$row->AUTOR}</td>";
         echo " <td>{$row->CPTN}</td>";
         echo " <td>{$row->CMPL}</td>";
         //echo " <td>{$row->RESULT}</td>";
         @$res = $results[$row->RESULT];
         if(!$res) $res = $row->RESULT;
         echo " <td>{$res}</td>";
         echo " <td>{$row->POINTS}</td>";
         echo " <td>{$row->MEM}</td>";
         echo " <td>{$row->MOVE}</td>";
         echo " <td>{$row->TIME_MOVE}</td>";
         echo " <td>{$row->TIME_GAME}</td>";

         echo "</tr>\n";
         $row = ibase_fetch_object($query);
      }
      echo "\n</tbody>\n</table>";
      ibase_free_result($query);
   }
   



   //entry point
   session_start();
   $DB = ibase_pconnect($db_name, $db_user, $db_password);
   if(!$DB)
   {
      echo "failed...";
      exit;
   }
      
   list ($id_user, $user_name, $access_level) = autorize();
   if($access_level <= LVL_GUEST)
   {
      Header($RedirectGames);
      exit();
   }

   if(isset($_REQUEST['id']))
   {
      $id_playing = $_REQUEST['id'];
      settype($id_playing, 'integer');
   }   
   else $id_playing = false;

   //check access
   
   echo "<html>\n";
   DisplayHead();
   echo "<body>\n";
   DisplayHeadTable($access_level);
   DisplayLocalHead($id_user, $user_name);
  
   viewgame($id_user, $id_playing, $access_level);
   
   ibase_close($DB);
   echo "\n</body></html>";
?>