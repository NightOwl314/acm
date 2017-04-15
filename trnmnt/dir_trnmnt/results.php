<?php

   require_once("autor.php");
   
   
   
   function DisplayFullTrnmnt($id_user, $id_trnmnt, $access_level)
   {
      global $DB, $host, $dir_trnmnt;

      $query_str = "select * from tournaments where id={$id_trnmnt}";
      $query = ibase_query($DB, $query_str);
      $row = ibase_fetch_object($query);
      if(!$row)                                      
      {
         //
         ibase_free_result($query);
         return "";
      }
      
      echo "<h2 align=\"center\">";
      echo "Предварительные результаты турнира ";
      $row->CAPTION = trim($row->CAPTION);
      echo "\"{$row->CAPTION}\"</h2><br>\n";
      $count_players = $row->COUNT_PLAYERS;
      ibase_free_result($query);
      
      $query_str = "select v_full_table.*, authors.name as autor, compil.name as cmpname ".
                   "from v_full_table, authors, compil ".
                   "where v_full_table.tourn={$id_trnmnt} and ".
                   "authors.id_publ=v_full_table.id_plr and compil.id_cmp=v_full_table.cmpl ".
                   "order by v_full_table.pnts descending, AID, BID";
      $query = ibase_query($DB, $query_str);
      $row = ibase_fetch_object($query);

      $i = 0;//$count_players;
      $k = 0;
      $saveAID = false;

      $str = "";
      $h = "";
      while($row)
      {
         if($saveAID === $row->AID)
         {
            //продолжаем строку таблицы
            $i++;
            if($i === $k) $str .= " <td> - </td>";
            $str .= " \n  <td><a href={$host}{$dir_trnmnt}viewgame.php?id={$row->AP}>{$row->APOINTS} &nbsp / &nbsp {$row->BPOINTS}</a></td>";
         }
         else
         {
            //новая строка таблицы
            $row->AUTOR = trim($row->AUTOR);
            $str .= "\n</tr>\n\n <tr align=\"center\">\n   <th>{$row->AUTOR}</th>";
            $row->CPTN = trim($row->CPTN);
            $str .= " <th>{$row->CPTN}</th>";
            $orw->CMPNAME = trim($row->CMPNAME);
            $str .= " <th>{$row->CMPNAME}</th>";
            $str .= " <th>{$row->PNTS}</th>";
            $str .= " <th>{$row->AID}</th>";
            if(!$k) $str .= " <td> - </td>";//первая клетка - пустая
            $str .= " <td><a href={$host}{$dir_trnmnt}viewgame.php?id={$row->AP}>{$row->APOINTS} &nbsp / &nbsp {$row->BPOINTS}</a></td>";
            $k++;
            $i = 1;
            $saveAID = $row->AID;
            $h .= "<th>{$row->AID}</th>";
         }
         $row = ibase_fetch_object($query);
      }
      ibase_free_result($query);
      //последняя клетка - пустая
      if($k) $str .= " <td> - </td>\n";
      $str .= "</tr>\n</tbody>\n</table>";

      echo "<table class=\"tbbd2\" align=\"center\" border=\"1\" cellspacing=\"1\" width=\"100%\">\n<tbody>\n <tr>\n";
      if($k)
      {
         echo " <th>Автор</th><th>Программа</th><th>Компилятор</th><th>Очки</th><th>Номер</th>";
         echo "{$h}";
      }
      echo $str;

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

   if(isset($_REQUEST['id_trnmnt']))
   {
      $id_trnmnt = $_REQUEST['id_trnmnt'];
      settype($id_trnmnt, 'integer');
   }   
   else $id_trnmnt = false;

   //check access
   
   echo "<html>\n";
   DisplayHead();
   echo "<body>\n";
   DisplayHeadTable($access_level);
   DisplayLocalHead($id_user, $user_name);
  

   DisplayFullTrnmnt($id_user, $id_trnmnt, $access_level);

   
   ibase_close($DB);
   echo "\n</body></html>";
?>