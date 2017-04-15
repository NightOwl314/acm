<?php

   require_once("autor.php");

   function DisplayCmpl($id_user, $access, $id)
   {
      global $DB, $host, $dir_trnmnt;

      $query_str = "select gm_slv.* from gm_slv where gm_slv.id={$id}";
      $query = ibase_query($DB, $query_str);
      $row = ibase_fetch_object($query);
      ibase_free_result($query);
      
      if(!$row) return NULL;

      echo "<hr><pre>\n";
      $row->COMPILFILE = trim($row->COMPILFILE);
      if(file_exists($row->COMPILFILE))
         include "{$row->COMPILFILE}";
      else echo "Файл не найден: {$row->COMPILFILE}\n";
      echo "</pre><hr>\n";
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
 
   if(isset($_REQUEST['id']))
   {
      $id = $_REQUEST['id'];
      settype($id, 'integer');
   }   
   else $id = false;


   echo "<html>\n";
   DisplayHead();
   echo "<body>\n";
   DisplayHeadTable($access_level);
   DisplayLocalHead($id_user, $user_name);
  
   if($id) DisplayCmpl($id_user, $access_level, $id);

   echo "\n</body></html>";

   ibase_close($DB);
?>