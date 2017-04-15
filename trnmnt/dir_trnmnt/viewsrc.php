<?php

   require_once("autor.php");

   function DisplaySrc($id_user, $access, $id_src)
   {
      global $DB, $host, $dir_trnmnt;

      $query_str = "select gm_slv.* from gm_slv where gm_slv.id={$id_src}";
      $query = ibase_query($DB, $query_str);
      $row = ibase_fetch_object($query);
      ibase_free_result($query);
      
      if(!$row) return NULL;

      echo "<pre>\n";

      ibase_blob_echo($row->CODE_SOURCE);

      echo "</pre>\n";

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
      $id_src = $_REQUEST['id'];
      settype($id_src, 'integer');
   }   
   else $id_src = false;


   echo "<html>\n";
   DisplayHead();
   echo "<body>\n";
   DisplayHeadTable($access_level);
   DisplayLocalHead($id_user, $user_name);
  
   echo "<h2 align=\"center\">Просмотр исходного текста решения</h2>";

   if($id_src) DisplaySrc($id_user, $access_level, $id_src);

   echo "\n</body></html>";

   ibase_close($DB);
?>