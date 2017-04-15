<?php

   require_once("autor.php");
   
   function UpdateTrnmnt()
   {
      global $DB, $host, $dir_trnmnt, $id_user, $user_name, $access_level, $RedirectGames, $game_dir;

      if(isset($_REQUEST['id_trnmnt']))
      {
         $id_trnmnt = $_REQUEST['id_trnmnt'];
         settype($id_trnmnt, 'integer');
      }   
      else return NULL;

      if(!isset($_REQUEST['save']) || ($_REQUEST['save'] != "save"))
         return NULL;

      $query_str = "select * from tournaments where id={$id_trnmnt}";
      $query = ibase_query($DB, $query_str);
      $T = ibase_fetch_object($query);
      ibase_free_result($query);
      if(!$T) return NULL;

      if(isset($_REQUEST['cptn']))
      {
         $cptn = $_REQUEST['cptn'];
         settype($cptn, 'string');
         $query_str = "update tournaments set caption='{$cptn}' where id={$T->ID}";
         $query = ibase_prepare($query_str);
         ibase_execute($query);
      }   

      if(isset($_REQUEST['max_plrs']))
      {
         $tmp = $_REQUEST['max_plrs'];
         settype($tmp, 'integer');
         $query_str = "update tournaments set max_players={$tmp} where id={$T->ID}";
         $query = ibase_prepare($query_str);
         ibase_execute($query);
      }   
      
      if(isset($_REQUEST['max_autor']))
      {
         $tmp = $_REQUEST['max_autor'];
         settype($tmp, 'integer');
         $query_str = "update tournaments set max_per_autor={$tmp} where id={$T->ID}";
         $query = ibase_prepare($query_str);
         ibase_execute($query);
      }   

      if(isset($_REQUEST['lvl']))
      {
         $tmp = $_REQUEST['lvl'];
         settype($tmp, 'integer');
         $query_str = "update tournaments set lvl={$tmp} where id={$T->ID}";
         $query = ibase_prepare($query_str);
         ibase_execute($query);
      }   

      if(isset($_REQUEST['mem']))
      {
         $tmp = $_REQUEST['mem'];
         settype($tmp, 'integer');
         $query_str = "update tournaments set max_mem={$tmp} where id={$T->ID}";
         $query = ibase_prepare($query_str);
         ibase_execute($query);
      }   

      if(isset($_REQUEST['time_game']))
      {
         $tmp = $_REQUEST['time_game'];
         settype($tmp, 'integer');
         $query_str = "update tournaments set max_time_game={$tmp} where id={$T->ID}";
         $query = ibase_prepare($query_str);
         ibase_execute($query);
      }   

      if(isset($_REQUEST['time_move']))
      {
         $tmp = $_REQUEST['time_move'];
         settype($tmp, 'integer');
         $query_str = "update tournaments set max_time_move={$tmp} where id={$T->ID}";
         $query = ibase_prepare($query_str);
         ibase_execute($query);
      }   

      if(isset($_REQUEST['move']))
      {
         $tmp = $_REQUEST['move'];
         settype($tmp, 'integer');
         $query_str = "update tournaments set max_move={$tmp} where id={$T->ID}";
         $query = ibase_prepare($query_str);
         ibase_execute($query);
      }   


      Header($RedirectGames);
      exit();
   }




   function InsertTrnmnt()
   {
      global $DB, $host, $dir_trnmnt, $id_user, $user_name, $access_level, $RedirectGames, $game_dir;

      if(isset($_REQUEST['id_game']))
      {
         $id_game = $_REQUEST['id_game'];
         settype($id_game, 'integer');
      }   
      else return NULL;

      if(!isset($_REQUEST['save']) || ($_REQUEST['save'] != "save"))
         return NULL;

      $query_str = "select * from games where id={$id_game}";
      $query = ibase_query($DB, $query_str);
      $G = ibase_fetch_object($query);
      ibase_free_result($query);
      if(!$G) return NULL;

      $query_str = "SELECT GEN_ID(GEN_TRNMNT, 1) FROM RDB\$DATABASE";
      $query = ibase_query($DB, $query_str);
      $row = ibase_fetch_object($query);
      ibase_free_result($query);
      if(!$row) return NULL;
      $id = $row->GEN_ID;

      $Q  = "insert into tournaments(id, id_game, caption, max_players, max_per_autor, lvl, ";
      $Q .= "max_mem, max_time_game, max_time_move, max_move, show_prg, chk_prg, ";
      $Q .= "description, type, state, src_access) values({$id}, {$G->ID}";

      if(isset($_REQUEST['cptn']))
      {
         $tmp = $_REQUEST['cptn'];
         settype($tmp, 'string');
         $Q .= ", '{$tmp}'";
      } else return NULL;
      if(isset($_REQUEST['max_plrs']))
      {
         $tmp = $_REQUEST['max_plrs'];
         settype($tmp, 'integer');
         $Q .= ", {$tmp}";
      } else return NULL;   
      if(isset($_REQUEST['max_autor']))
      {
         $tmp = $_REQUEST['max_autor'];
         settype($tmp, 'integer');
         $Q .= ", {$tmp}";
      } else return NULL;   
      if(isset($_REQUEST['lvl']))
      {
         $tmp = $_REQUEST['lvl'];
         settype($tmp, 'integer');
         $Q .= ", {$tmp}";
      } else return NULL;
      if(isset($_REQUEST['mem']))
      {
         $tmp = $_REQUEST['mem'];
         settype($tmp, 'integer');
         $Q .= ", {$tmp}";
      } else return NULL;           
      if(isset($_REQUEST['time_game']))
      {
         $tmp = $_REQUEST['time_game'];
         settype($tmp, 'integer');
         $Q .= ", {$tmp}";
      } else return NULL;   

      if(isset($_REQUEST['time_move']))
      {
         $tmp = $_REQUEST['time_move'];
         settype($tmp, 'integer');
         $Q .= ", {$tmp}";
      } else return NULL;   

      if(isset($_REQUEST['move']))
      {
         $tmp = $_REQUEST['move'];
         settype($tmp, 'integer');
         $Q .= ", {$tmp}";
      } else return NULL;   

      if(isset($_FILES['show']['tmp_name']) && is_uploaded_file($_FILES['show']['tmp_name']))
      {
         $tmp = "{$game_dir}shw_{$id}.vw";
         copy($_FILES['show']['tmp_name'], $tmp);
         $Q .= ", '{$tmp}'";
      } else return NULL;   

      if(isset($_FILES['chk']['tmp_name']) && is_uploaded_file($_FILES['chk']['tmp_name']))
      {
         $tmp = "{$game_dir}chk_{$id}.exe";
         copy($_FILES['chk']['tmp_name'], $tmp);
         $Q .= ", '{$tmp}'";
      } else return NULL;   

      if(isset($_REQUEST['descr']))
      {
         $tmp = $_REQUEST['descr'];
         $blob = ibase_blob_create();
         ibase_blob_add($blob, $tmp);
         $blob = ibase_blob_close($blob);        
      } else return NULL;   
      
      $Q .= ", ?, 1, 1, 0)";
      $Q = ibase_prepare($Q);
      ibase_execute($Q, $blob);
      
      Header($RedirectGames);
      exit();
   }



   function DisplayForm($id_trnmnt, $id_game, $act)
   {
      global $DB, $host, $dir_trnmnt, $id_user, $user_name, $access_level;
      
      if($id_trnmnt)
      {
         $query_str = "select * from tournaments where id={$id_trnmnt}";
         $query = ibase_query($DB, $query_str);
         $T = ibase_fetch_object($query);
         ibase_free_result($query);
      } else $T = false;
      if($id_game)
      {
         $query_str = "select * from games where id={$id_game}";
         $query = ibase_query($DB, $query_str);
         $G = ibase_fetch_object($query);
         ibase_free_result($query);
      } else $G = false;

      if($T && ($act == ACT_UPDATE))
      {
         $act = ACT_UPDATE;
      } else if ($G)
      {
         $act = ACT_INSERT;
      } else
      {
         Header($RedirectGames);
         exit();
      }

      echo "<html>\n";
      DisplayHead();
      echo "<body>\n";
      DisplayHeadTable($access_level);
      DisplayLocalHead($id_user, $user_name);

      if($act == ACT_UPDATE)
         echo "<h2 align=\"center\">Редактирование турнира</h2><br>\n";
      else
         echo "<h2 align=\"center\">Создание турнира</h2><br>\n";

      echo "<table align=\"center\" border=\"0\" width=\"70%\">\n";
      echo "<tbody><tr><td>\n";


      echo "   <table class=\"tbbd\" align=\"center\" border=\"2\" cellpadding=\"5\" width=\"85%\">\n";
      echo "   <form name=\"form1\" action=\"{$host}{$dir_trnmnt}act_t.php?act={$act}\" method=\"post\" enctype=\"multipart/form-data\">\n";
      echo "   <tbody>\n\n   <tr>\n";
      echo "      <td align=\"right\" width=\"300\"><h5>Название:</h5></td>\n";
      echo "      <td align=\"left\" ><input name=\"cptn\" size=\"50\"";
      if($act == ACT_UPDATE)
         echo " value=\"{$T->CAPTION}\"";
      echo ">\n";
      if($act == ACT_UPDATE)
         echo "      <input type=\"hidden\" name=\"id_trnmnt\" value=\"{$T->ID}\">\n";
      else  echo "      <input type=\"hidden\" name=\"id_game\" value=\"{$G->ID}\">\n";
      echo "      <input type=\"hidden\" name=\"save\" value=\"save\">\n";

      echo "   </tr>\n   <tr>\n";
      echo "      <td align=\"right\" width=\"300\"><h5>Макс. кол-во участников:</h5></td>\n";
      echo "      <td align=\"left\" width=\"300\"><input name=\"max_plrs\" size=\"50\"";
      if($act == ACT_UPDATE)
         echo " value=\"{$T->MAX_PLAYERS}\"";
      echo ">\n";

      echo "   </tr>\n   <tr>\n";
      echo "      <td align=\"right\" width=\"300\"><h5>Макс. кол-во решений одного автора:</h5></td>\n";
      echo "      <td align=\"left\" width=\"300\"><input name=\"max_autor\" size=\"50\"";
      if($act == ACT_UPDATE)
         echo " value=\"{$T->MAX_PER_AUTOR}\"";
      echo ">\n";

      echo "   </tr>\n   <tr>\n";
      echo "      <td align=\"right\" width=\"300\"><h5>Сложность:</h5></td>\n";
      echo "      <td align=\"left\" width=\"300\"><input name=\"lvl\" size=\"50\"";
      if($act == ACT_UPDATE)
         echo " value=\"{$T->LVL}\"";
      echo ">\n";

      echo "   </tr>\n";
      echo "      <td align=\"right\" width=\"300\"><h5>Ограничение по памяти:</h5></td>\n";
      echo "      <td align=\"left\" width=\"300\"><input name=\"mem\" size=\"50\"";
      if($act == ACT_UPDATE)
         echo " value=\"{$T->MAX_MEM}\"";
      echo ">\n";

      echo "   </tr>\n   <tr>\n";
      echo "      <td align=\"right\" width=\"300\"><h5>Ограничение по времени на игру:</h5></td>\n";
      echo "      <td align=\"left\" width=\"300\"><input name=\"time_game\" size=\"50\"";
      if($act == ACT_UPDATE)
         echo " value=\"{$T->MAX_TIME_GAME}\"";
      echo ">\n";

      echo "   </tr>\n   <tr>\n";
      echo "      <td align=\"right\" width=\"300\"><h5>Ограничение по времени на ход:</h5></td>\n";
      echo "      <td align=\"left\" width=\"300\"><input name=\"time_move\" size=\"50\"";
      if($act == ACT_UPDATE)
         echo " value=\"{$T->MAX_TIME_MOVE}\"";
      echo ">\n";

      echo "   </tr>\n   <tr>\n";
      echo "      <td align=\"right\" width=\"300\"><h5>Ограничение на кол-во ходов:</h5></td>\n";
      echo "      <td align=\"left\" width=\"300\"><input name=\"move\" size=\"50\"";
      if($act == ACT_UPDATE)
         echo " value=\"{$T->MAX_MOVE}\"";
      echo ">\n";

      echo "   </tr>\n   <tr>\n";
      echo "      <td align=\"right\" width=\"300\"><h5>Визуализатор:</h5></td>\n";
      echo "      <td align=\"left\" width=\"300\"><input type=\"hidden\" name=\"MAX_FILE_SIZE\" value=\"1000000\"><input type=\"file\" name=\"show\" size=\"50\"";
      echo ">\n";

      echo "   </tr>\n   <tr>\n";
      echo "      <td align=\"right\" width=\"300\"><h5>Проверяющая программа:</h5></td>\n";
      echo "      <td align=\"left\" width=\"300\"><input type=\"hidden\" name=\"MAX_FILE_SIZE\" value=\"1000000\"><input type=\"file\" name=\"chk\" size=\"50\"";
      echo ">\n";

      echo "   </tr>\n   <tr>\n";
      echo "      <td align=\"center\" colspan=\"2\"><h5>Описание:</h5></td>\n";
      echo "   </tr><tr><td colspan=\"2\" align=\"left\"><textarea name=\"descr\" cols=\"80\" rows=\"25\" wrap=\"off\">";
      if($act == ACT_UPDATE)
         ibase_blob_echo($T->DESCRIPTION);

      echo "</textarea></td>\n";
 
      echo "   </tr><tr><td colspan=\"2\" align=\"center\"><hr><input value=\"Сохранить\" class=\"submit_btn\" type=\"submit\"></td>\n";

      echo "   </tr>\n\n";
      echo "   </tbody></form></table>\n";


      echo "</td></tr></tbody></table>\n";
      echo "\n</body></html>";
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

   if(isset($_REQUEST['act']))
   {
      $act = $_REQUEST['act'];
      settype($act, 'integer');
   }   
   else $act = 0;

   if(isset($_REQUEST['id_game']))
   {
      $id_game = $_REQUEST['id_game'];
      settype($id_game, 'integer');
   }   
   else $id_game = false;

   if($act == ACT_INSERT) InsertTrnmnt();
   else UpdateTrnmnt();

   DisplayForm($id_trnmnt, $id_game, $act);
   


   ibase_close($DB);   
?>