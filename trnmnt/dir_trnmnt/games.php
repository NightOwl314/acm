<?php

   require_once("autor.php");


   function ActGame($act, $id_game, $id_user, $user_name, $access_level)
   {
      global $DB, $host, $dir_trnmnt, $game_dir, $RedirectGames;

      if($act != ACT_UPDATE)
      {
         $id_game = 0;
         $act = ACT_INSERT;
      }

      if(isset($_REQUEST['gamename']))
      {
         $gamename = $_REQUEST['gamename'];
         settype($gamename, 'string');
      } else $gamename = "";

      if(isset($_REQUEST['gmdescr']))
      {
         $gmdescr = $_REQUEST['gmdescr'];
         settype($gmdescr, 'string');
      } else $gmdescr = "";

      $row = false;
      if($id_game)
      {
         $query_str = "select * from games where id={$id_game}";
         $query = ibase_query($DB, $query_str);
         $row = ibase_fetch_object($query);
         ibase_free_result($query);
      }
      if($gamename && isset($_FILES['gamefile']['tmp_name']) && is_uploaded_file($_FILES['gamefile']['tmp_name']))
      {
         if($row && ($act == ACT_UPDATE))
         {
            $id = $row->ID;
            $gmfl = "{$game_dir}gm_{$id}.htm";
            copy($_FILES['gamefile']['tmp_name'], $gmfl);            
            $query_str = "update games set caption='{$gamename}', gamefile='{$gmfl}' where id={$id}";
            $query = ibase_prepare($query_str);
            ibase_execute($query);
            Header($RedirectGames);
            exit();
         } else
         {
            $query_str = "SELECT GEN_ID(GEN_GAMES, 1) FROM RDB\$DATABASE";
            $query = ibase_query($DB, $query_str);
            $row = ibase_fetch_object($query);
            ibase_free_result($query);
            $id = $row->GEN_ID;
            $gmfl = "{$game_dir}gm_{$id}.htm";
            copy($_FILES['gamefile']['tmp_name'], $gmfl);            
            $query_str = "insert into games(id, caption, gamefile) values({$id}, '{$gamename}', '{$gmfl}')";
            $query = ibase_prepare($query_str);
            ibase_execute($query);
            Header($RedirectGames);
            exit();
         }
      } else
      {
         echo "<html>\n";
         DisplayHead();
         echo "<body>\n";
         DisplayHeadTable($access_level);
         DisplayLocalHead($id_user, $user_name);

         if($act == ACT_UPDATE) echo " <h2 align=\"center\">Редактирование игры</h2>\n";
         else                   echo " <h2 align=\"center\">Добавление игры</h2>\n";
         
         echo "\n<table align=\"center\" border=\"0\">\n";
         echo "<tbody><tr><td>\n";
 
         echo "   <table class=\"tbbd\" align=\"center\" border=\"2\" cellpadding=\"5\">\n";
         echo "   <form name=\"form1\" action=\"{$host}{$dir_trnmnt}games.php?act={$act}\" method=\"post\" enctype=\"multipart/form-data\">\n";
         echo "   <tbody>\n\n";

         echo "   <tr>\n";
         if($row) echo"      <input name=\"id_game\" type=\"hidden\" value=\"{$row->ID}\"></input>\n";
         echo "      <td align=\"right\" width=\"140\"><h5>Название игры:</h5></td>\n";
         echo "      <td align=\"left\" width=\"590\"><input name=\"gamename\" size=\"64\" type=\"text\" ";
         if($row)
         {
            $row->CAPTION = trim($row->CAPTION);
            echo "value=\"{$row->CAPTION}\"";
         }
         echo "></td>\n";
         echo "   </tr>\n\n";

         echo "   <tr><td colspan=\"2\" class=\"separ\" align=\"left\"><hr></td></tr>\n";
/*
         echo "   <tr>\n";
         echo "      <td align=\"left\" width=\"140\"><h5>Описание:</h5></td>\n";
         echo "   </tr>\n\n";

*/
/*
         echo "   <tr><td colspan=\"2\" align=\"left\"><textarea name=\"gmdescr\" cols=\"90\" rows=\"25\" wrap=\"off\">";
         if($row)
         {
            $row->GAMEFILE = trim($row->GAMEFILE);
            if(file_exists($row->GAMEFILE))
            {
               include "{$row->GAMEFILE}";
            }
         }
         echo "</textarea></td>\n";
         echo "   </tr>\n\n";
*/

         echo "   <tr><td align=\"right\" width=\"180\"><h5>Загрузить описание из файла:</h5></td>\n";
         echo "      <td width=\"590\"><input type=\"hidden\" name=\"MAX_FILE_SIZE\" value=\"1000\"><input name=\"gamefile\" size=\"80\" type=\"file\"></td>\n";
         echo "   </tr>\n\n";

         echo "   <tr><td colspan=\"2\" align=\"center\"><hr><input value=\"Сохранить\" class=\"submit_btn\" type=\"submit\"></td>\n";
         echo "   </tr>\n\n";

         echo "   </tbody></form></table>\n";

         echo "</td></tr></tbody></table>\n";      

         echo "\n</body></html>";         
      }
      exit();
      return NULL;
   }
   


   function  DisplayGameById($access_level, $id_game)
   {
      global $DB, $host, $dir_trnmnt;

      $query_str = "select games.* from games where id={$id_game}";
      $query = ibase_query($DB, $query_str);
      $row = ibase_fetch_object($query);

      $row->CAPTION = trim($row->CAPTION);
      echo "<h2 align=\"center\">{$row->CAPTION}</h2>";
      $row->GAMEFILE = trim($row->GAMEFILE);
      if(file_exists($row->GAMEFILE))
      {
         //echo "<pre>\n";
         include "{$row->GAMEFILE}";
         //echo "\n</pre>";
      }

      if($access_level >= LVL_ADMIN)
      {
      /*
         echo "<table class=\"other\" width=\"97%\" border=\"0\"><tbody>\n<tr>";
         echo "   <td align=\"left\"><a href=\"{$host}{$dir_trnmnt}games.php?id_game={$id_game}&act=1\">Редактировать игру</a></td>\n";
         echo "   <td align=\"right\"><a href=\"{$host}{$dir_trnmnt}games.php?act=2\">Добавить игру</a></td>\n";
         echo "</tr>\n</tbody></table>\n\n";
      */
      }

      ibase_free_result($query);
      return NULL;
   }



   function DisplayGames($access)
   {
      global $DB, $host, $dir_trnmnt;

      $query_str = "select games.* from games order by games.caption";
      $query = ibase_query($DB, $query_str);
      $row = ibase_fetch_object($query);

      echo "<br>\n<h2 align=\"center\">Игры</h2>\n";
      if($access >= LVL_ADMIN)
      {
         echo "<table class=\"other\" width=\"97%\" border=\"0\"><tbody>\n<tr>";
         echo "   <td align=\"right\"><a href=\"{$host}{$dir_trnmnt}games.php?act=2\">Добавить игру</a></td>\n";
         echo "</tr>\n</tbody></table>\n\n";
      }
      echo "<table class=\"tbbd2\" align=\"center\" border=\"1\" cellspacing=\"1\" width=\"97%\">\n";
      echo "<tbody>\n";
      echo " <tr><th align=\"center\" width=\"75\">Номер</th>\n";
      echo "     <th align=\"center\" width=\"175\">Название</th>\n";
      echo "     <th align=\"center\" width=\"40%\">Турниры</th>\n";
      if($access >= LVL_ADMIN) echo "     <th align=\"center\" width=\"75\">Редактировать</th>\n";
      echo " </tr>\n\n";
      while($row)
      {
         echo "\n <tr>\n";
         echo "     <td align=\"center\">{$row->ID}</td>\n";
         $row->CAPTION = trim($row->CAPTION);
         echo "     <td align=\"center\"><a href=\"{$host}{$dir_trnmnt}games.php?id_game={$row->ID}\">{$row->CAPTION}</a></td>\n";
         echo "     <td align=\"center\"><a href=\"{$host}{$dir_trnmnt}trnmnt.php?id_game={$row->ID}\">Турниры по игре</a>";
         if($access >= LVL_ADMIN)
         {
            echo "&nbsp \ &nbsp <a href=\"{$host}{$dir_trnmnt}act_t.php?id_game={$row->ID}&act=2\">Создать турнир</a>";
         }
         echo "</td>\n";
         if($access >= LVL_ADMIN) echo "     <td align=\"center\"><a href=\"{$host}{$dir_trnmnt}games.php?id_game={$row->ID}&act=1\">Редактировать</a></td>\n";
         echo " </tr>\n";
         $row = ibase_fetch_object($query);
     }

     echo "\n</tbody></table>\n";
     echo "\n<br><br>\n\n";
     ibase_free_result($query);

     return NULL;
   }
   
   
   //точка входа
   session_start();
   $DB = ibase_pconnect($db_name, $db_user, $db_password);
   if(!$DB)
   {
      Header("");
      exit;
   }
      
   list ($id_user, $user_name, $access_level) = autorize();

   if(isset($_REQUEST['act']))
   {
      $act = $_REQUEST['act'];
      settype($act, 'integer');
   }   
   else $act = false;
   if(isset($_REQUEST['id_game']))
   {
      $id_game = $_REQUEST['id_game'];
      settype($id_game, 'integer');
   }   
   else $id_game = false;

   if($act && $access_level>=LVL_ADMIN)
      ActGame($act, $id_game, $id_user, $user_name, $access_level);

   echo "<html>\n";
   DisplayHead();
   echo "<body>\n";
   DisplayHeadTable($access_level);
   DisplayLocalHead($id_user, $user_name);

   if($id_game)
      DisplayGameById($access_level, $id_game);
   else
      DisplayGames($access_level);

   ibase_close($DB);
   echo "\n</body></html>";
?>