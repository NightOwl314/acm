<?php

   require_once("autor.php");
   
   
   function viewparties($id_user, $id_trnmnt, $access_level)
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

      $row->CAPTION = trim($row->CAPTION);
      echo "<h2 align=\"center\">Участники турнира \"{$row->CAPTION}\"</h2>\n";
      ibase_free_result($query);

      $query_str = "select gm_slv.*, authors.name as autorname, compil.name as cmpl ".
                   "from gm_slv, authors, compil ".
                   "where id_trnmnt={$id_trnmnt} and test_result=0 ".
                   "and gm_slv.compiler=compil.id_cmp and authors.id_publ=gm_slv.id_player ".
                   "order by gm_slv.points descending, gm_slv.input_dt";
      $query = ibase_query($DB, $query_str);
      $row = ibase_fetch_object($query);
      
      echo "<table class=\"tbbd2\" align=\"center\" border=\"1\" cellspacing=\"1\" width=\"100%\">\n<tbody>\n";
      echo " <tr>\n";
      echo "   <th>Номер</th>\n";
      echo "   <th>Автор</th>\n";
      echo "   <th>Название</th>\n";
      echo "   <th>Очки</th>\n";
      echo "   <th>Дата</th>\n";
      echo "   <th>Компилятор</th>\n";
      echo " </tr>\n";
      while($row)
      {
         echo "\n <tr align=\"center\">\n";
         echo "   <td>{$row->ID}</td>\n";
         $row->AUTORNAME = trim($row->AUTORNAME);
         echo "   <td>{$row->AUTORNAME}</td>\n";
         $row->CAPTION = trim($row->CAPTION);
         echo "   <td><a href=\"{$host}{$dir_trnmnt}viewsrc.php?id={$row->ID}\">{$row->CAPTION}</a></td>\n";
         echo "   <td>{$row->POINTS}</td>\n";
         echo "   <td>{$row->INPUT_DT}</td>\n";
         $row->CMPL = trim($row->CMPL);
         echo "   <td>{$row->CMPL}</td>\n";
         echo " </tr>\n";

         $row = ibase_fetch_object($query);
      }
      echo "\n</tbody>\n</table>";
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
  
   viewparties($id_user, $id_trnmnt, $access_level);
   
   ibase_close($DB);
   echo "\n</body></html>";
?>