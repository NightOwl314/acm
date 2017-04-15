<?php

   require_once("autor.php");
   

   function MaySubmit($id_user, $id_trnmnt)
   {
      global $DB;

      if(!$id_user || !$id_trnmnt) return false;
      
      $query_str = "select id from tournaments where (id = {$id_trnmnt}) and (dt_finish >= CURRENT_TIMESTAMP) and (dt_start <= CURRENT_TIMESTAMP)";
      $query = ibase_query($DB, $query_str);
      $row = ibase_fetch_object($query);

      if($row) return true;
      return false;
   }

   
   function AccessTrnmnt($id_user, $id_trnmnt)
   {
      return true;
   }
   

   
   function LoadSourceCode($id_user, $id_trnmnt, $id_compiler, $source, $name_prg)
   {

      global $DB, $host, $dir_trnmnt;
      $ok = true;

      //проверить $id_compiler
      $query_str = "select * from tournaments where id={$id_trnmnt}";
      $query = ibase_query($DB, $query_str);
      $row = ibase_fetch_object($query);
      if(!$row)
      {
         return "Турнир не найден";
      }
      ibase_free_result($query);
      $query_str = "select count(*) as cnt from gm_slv where id_trnmnt={$id_trnmnt} and id_player={$id_user} and test_result<=0";
      $query = ibase_query($DB, $query_str);
      $cnt = ibase_fetch_object($query);
      if($row->MAX_PLAYERS && ($row->MAX_PLAYERS <= $row->COUNT_PLAYERS))
      {
         return "Превышен лимит решений";
      }
      ibase_free_result($query);
      if(($row->MAX_PER_AUTOR) && ($row->MAX_PER_AUTOR <= $cnt->CNT))
      {
         return "Превышен лимит решений автора: {$cnt->CNT}/{$row->MAX_PER_AUTOR}";
      }

      //проверить остальное


      //все проверки пройдены добавить программу
      /*
      IBASE_READ (integer)
      IBASE_COMMITTED (integer)
      IBASE_CONSISTENCY (integer)
      */
      $tr_id = ibase_trans(IBASE_WRITE | IBASE_CONCURRENCY | IBASE_NOWAIT, $DB);

      $blob = ibase_blob_create();
      //$arr = array();
      //$arr[] = $source;
      //ibase_blob_add($blob, $arr[0]);
      ibase_blob_add($blob, $source);
      $blob = ibase_blob_close($blob);
            
      if($name_prg) $query = "insert into gm_slv(id_trnmnt, id_player, compiler, caption, code_source) values(?, ?, ?, ?, ?)";
      else $query = "insert into gm_slv(id_trnmnt, id_player, compiler, code_source) values(?, ?, ?, ?)";
      $query = ibase_prepare($query);
      if($name_prg)
         $ok = ibase_execute($query, $id_trnmnt, $id_user, $id_compiler, $name_prg, $blob);
      else
         $ok = ibase_execute($query, $id_trnmnt, $id_user, $id_compiler, $blob);

      if($ok)
      {
          ibase_commit($tr_id);
          Header("Location: {$host}{$dir_trnmnt}solves.php?id_trnmnt={$id_trnmnt}");
          return "";//нет ошибки
      }
      else
      {
         ibase_rollback($tr_id);
         return "Ошибка вставки записи в базу данных";
      }
   }



   function LoadSourceFile($id_user, $id_trnmnt, $id_compiler, $file_name, $name_prg)
   {
      global $DB, $host, $dir_trnmnt;
      $ok = true;

      //проверки


      $query_str = "select * from tournaments where id={$id_trnmnt}";
      $query = ibase_query($DB, $query_str);
      $row = ibase_fetch_object($query);
      if(!$row)
      {
         return "Турнир не найден";
      }
      ibase_free_result($query);
      $query_str = "select count(*) as cnt from gm_slv where id_trnmnt={$id_trnmnt} and id_player={$id_user} and test_result<=0";
      $query = ibase_query($DB, $query_str);
      $cnt = ibase_fetch_object($query);
      if($row->MAX_PLAYERS && ($row->MAX_PLAYERS <= $row->COUNT_PLAYERS))
      {
         return "Превышен лимит решений";
      }
      ibase_free_result($query);
      if(($row->MAX_PER_AUTOR) && ($row->MAX_PER_AUTOR <= $cnt->CNT))
      {
         return "Превышен лимит решений автора: {$cnt->CNT}/{$row->MAX_PER_AUTOR}";
      }


      $id_file = fopen($file_name, "rt");

      $tr_id = ibase_trans(IBASE_WRITE | IBASE_COMMITTED | IBASE_NOWAIT | IBASE_REC_NO_VERSION, $DB);
      $blob = ibase_blob_import($DB, $id_file);

      if($name_prg) $query = "insert into gm_slv(id_trnmnt, id_player, compiler, caption, code_source) values(?, ?, ?, ?, ?)";
      else $query = "insert into gm_slv(id_trnmnt, id_player, compiler, code_source) values(?, ?, ?, ?)";
      $query = ibase_prepare($query);
      if($name_prg)
         $ok = ibase_execute($query, $id_trnmnt, $id_user, $id_compiler, $name_prg, $blob);
      else
         $ok = ibase_execute($query, $id_trnmnt, $id_user, $id_compiler, $blob);

      if($ok)
      {
          ibase_commit($tr_id);
          Header("Location: {$host}{$dir_trnmnt}solves.php?id_trnmnt={$id_trnmnt}");
          return "";//нет ошибки
      }
      else
      {
         //ibase_rollback($tr_id);
         return "Ошибка вставки записи в базу данных";
      }
   }
   


   function DisplaySubmit($id_user, $id_trnmnt, $error_str)
   {
      global $host, $dir_trnmnt, $DB;

      settype($error_str, 'string');

      $error_str = trim($error_str);

      if($error_str)
      {
         echo "\n<br><hr>$error_str<br><hr><br>\n";
      }

      $query_str = "select * from tournaments where id={$id_trnmnt}";
      $query = ibase_query($DB, $query_str);
      $row = ibase_fetch_object($query);
      ibase_free_result($query);

      echo " <h2 align=\"center\">Отправить программу на проверку</h2>\n";
   
      echo "<table align=\"center\" border=\"0\">\n";
      echo "<tbody><tr><td>\n";
 
      echo "   <table class=\"tbbd\" align=\"center\" border=\"2\" cellpadding=\"5\">\n";
      echo "   <form name=\"form1\" action=\"{$host}{$dir_trnmnt}submit.php\" method=\"post\" enctype=\"multipart/form-data\">\n";
      echo "   <tbody>\n\n   <tr>\n";
      echo "      <td align=\"right\" width=\"140\"><h5>Турнир:</h5></td>\n";
      echo "      <td align=\"left\" width=\"590\">{$row->CAPTION}</td>\n";
      echo "      <input type=\"hidden\" name=\"id_trnmnt\" value=\"{$id_trnmnt}\">";
      echo "   </tr>\n\n";
      echo "   <tr>\n";
      echo "      <td align=\"right\" width=\"140\"><h5>Компилятор:</h5></td>\n";
      echo "      <td align=\"left\" width=\"590\">\n";
      echo "         <select name=\"id_compiler\" size=\"1\" style=\"width: 500px;\">\n";

      $query_str = "select compil.* from compil, compil_trnmnt where compil_trnmnt.id_compil=compil.id_cmp and id_trnmnt={$id_trnmnt}";
      $query = ibase_query($DB, $query_str);
      $row = ibase_fetch_object($query);
      if($row)
      {
         $row->NAME = trim($row->NAME);
         echo "            <option value=\"{$row->ID_CMP}\" selected=\"selected\">{$row->NAME}</option>\n";
         $row = ibase_fetch_object($query);
      }
      while($row)
      {
         $row->NAME = trim($row->NAME);
         echo "            <option value=\"{$row->ID_CMP}\">{$row->NAME}</option>\n";
         $row = ibase_fetch_object($query);
      }
      ibase_free_result($query);

      echo "         </select>\n";
      echo "      </td>\n";
      echo "   </tr>\n\n";
      echo "   <tr><td colspan=\"2\" class=\"separ\" align=\"left\"><hr></td></tr>\n";

      echo "   <tr>\n";
      echo "      <td align=\"right\" width=\"140\"><h5>Название программы:</h5></td>\n";
      echo "      <td align=\"left\" width=\"590\"><input name=\"name_prg\" size=\"64\" type=\"text\"></td>\n";
      echo "   </tr>\n\n";

      echo "   <tr><td colspan=\"2\" class=\"separ\" align=\"left\"><hr></td></tr>\n";
      echo "   <tr>\n";
      echo "      <td align=\"left\" width=\"140\"><h5>Исходный текст:</h5></td>\n";
      //echo "      <td align=\"right\" width=\"590\"><a href=\"{$host}{$dir_trnmnt}submit.php?mode=load_src\">Загрузить последний отправленный исходник</a></td>\n";
      echo "   </tr>\n\n";
      echo "   <tr><td colspan=\"2\" align=\"left\"><textarea name=\"source\" cols=\"90\" rows=\"25\" wrap=\"off\"></textarea></td>\n";
      echo "   </tr>\n\n";
      echo "   <tr><td align=\"right\" width=\"140\"><h5>Исходный файл:</h5></td>\n";
      echo "      <td width=\"590\"><input type=\"hidden\" name=\"MAX_FILE_SIZE\" value=\"1000000\"><input name=\"sourcefile\" size=\"80\" type=\"file\"></td>\n";
      echo "   </tr>\n\n";
      echo "   <tr><td colspan=\"2\" align=\"center\"><hr><input value=\"Отправить\" class=\"submit_btn\" type=\"submit\"></td>\n";
      echo "   </tr>\n\n";
      echo "   </tbody></form></table>\n";
      echo "</td></tr></tbody></table>\n";      
 
      return NULL;
   }
   
   
   //точка входа в скрипт
   session_start();
 /*
   echo "<pre>\n";
   phpinfo();
   echo "</pre>";
 */
   //int ibase_pconnect (string database [, string username [, string password [, string charset [, int buffers [, int dialect [, string role]]]]]])
   $DB = ibase_pconnect($db_name, $db_user, $db_password, "WIN1251", 1000000, 3);
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

   $ok = true;
   $error_str = "";
  
   if(isset($_REQUEST['id_compiler']))
   {
      $id_compiler = $_REQUEST['id_compiler'];
      settype($id_compiler, 'integer');
   } else $id_compiler = false;

   if(isset($_REQUEST['id_trnmnt']))
   {
      $id_trnmnt = $_REQUEST['id_trnmnt'];
      settype($id_trnmnt, 'integer');
   } else $id_trnmnt = false;

   if(isset($_REQUEST['name_prg']))
   {
      $name_prg = $_REQUEST['name_prg'];
      settype($name_prg, 'string');
   } else $name_prg = NULL;

   if($ok && $id_trnmnt && $id_compiler && isset($_FILES['sourcefile']['tmp_name']) && is_uploaded_file($_FILES['sourcefile']['tmp_name']))
   {
      $ok = false;
      $error_str = LoadSourceFile($id_user, $id_trnmnt, $id_compiler, $_FILES['sourcefile']['tmp_name'], $name_prg);
   }

   if($ok && $id_trnmnt && $id_compiler && isset($_REQUEST['source']) && trim($_REQUEST['source']))
   {
      $ok = false;
      $error_str = LoadSourceCode($id_user, $id_trnmnt, $id_compiler, trim($_REQUEST['source']), $name_prg);
   }

 
   echo "<html>\n";
   DisplayHead();
   echo "<body>\n";
   DisplayHeadTable($access_level);
   DisplayLocalHead($id_user, $user_name);

   if($ok || $error_str)
      DisplaySubmit($id_user, $id_trnmnt, $error_str);
     
   echo "\n</body></html>";
   
   ibase_close($DB);
?>