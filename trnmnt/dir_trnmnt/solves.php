<?php

   require_once("autor.php");

   function DisplayById($id_user, $access, $id_trnmnt, $id_first)
   {
      global $DB, $host, $dir_trnmnt, $results;

      $count_per_page = 10;

      echo "\n<br><h2 align=\"center\">Просмотр решений</h2><br>\n\n";

      $tr_id = ibase_trans(IBASE_READ | IBASE_NOWAIT | IBASE_REC_VERSION | IBASE_COMMITTED, $DB);

      $i = $count_per_page + 1;
      
      $query_str = "select first {$i} gm_slv.*, compil.name as cmpl ".
                   "from gm_slv, compil ".
                   "where gm_slv.id_player={$id_user} and gm_slv.compiler=compil.id_cmp";
      if($id_trnmnt) 
         $query_str = "{$query_str} and gm_slv.id_trnmnt={$id_trnmnt}";
      if($id_first)
         $query_str = "{$query_str} and gm_slv.id<={$id_first}";
      $query_str = "{$query_str} order by gm_slv.id descending";
     
      $query = ibase_query($DB, $query_str);
   
      $row = ibase_fetch_object($query);

      echo "<table class=\"tbbd2\" align=\"center\" border=\"1\" cellspacing=\"1\" width=\"100%\">\n";
      echo "<tbody>\n";
      echo " <tr><th align=\"center\" width=\"75\">Номер</th>\n";
      echo "     <th align=\"center\" width=\"75\">Дата</th>\n";
      if(!$id_trnmnt) echo "     <th align=\"center\" width=\"75\">Турнир</th>\n";
      echo "     <th align=\"center\" width=\"175\">Название</th>\n";
      echo "     <th align=\"center\" width=\"175\">Компилятор</th>\n";
      echo "     <th align=\"center\" width=\"75\">Результат</th>\n";
      echo " </tr>\n\n";
      while($row)
      {
         echo "\n <tr>\n";
         echo "     <td align=\"center\">{$row->ID}</td>\n";
         echo "     <td align=\"center\">{$row->INPUT_DT}</td>\n";
         if(!$id_trnmnt) echo "     <td align=\"center\">{$row->ID_TRNMNT}</td>\n";
         $row->CAPTION = trim($row->CAPTION);
         echo "     <td align=\"center\"><a href=\"{$host}{$dir_trnmnt}viewsrc.php?id={$row->ID}\">{$row->CAPTION}</a></td>\n";
         echo "     <td align=\"center\">{$row->CMPL}</td>\n";
         @$res = $results[$row->TEST_RESULT];
         if(!$res) $res = $row->TEST_RESULT;//$res = "Не определено";
         if($row->TEST_RESULT == 17)//compilation error
              echo "     <td align=\"center\"><a href=\"{$host}{$dir_trnmnt}viewcmpl.php?id={$row->ID}\">{$res}</a></td>\n";
         else echo "     <td align=\"center\">{$res}</td>\n";
         echo " </tr>\n";
         $row = ibase_fetch_object($query);
     }

     echo "\n</tbody></table>\n";
     echo "\n<br><br>\n\n";
     ibase_free_result($query);
     ibase_commit($tr_id);
     return NULL;
   }
   
   
   //точка входа в скрипт
   session_start();
   $DB = ibase_pconnect($db_name, $db_user, $db_password);
   if(!$DB)
   {
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

   if(isset($_REQUEST['id_first']))
   {
      $id_first = $_REQUEST['id_first'];
      settype($id_first, 'integer');
   }   
   else $id_first = false;
 
   echo "<html>\n";
   DisplayHead();
   echo "<body>\n";
   DisplayHeadTable($access_level);
   DisplayLocalHead($id_user, $user_name);
 
   DisplayById($id_user, $access_level, $id_trnmnt, $id_first);
   
   echo "\n</body></html>";

   ibase_close($DB);
?>