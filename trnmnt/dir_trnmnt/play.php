<?php
   require_once("autor.php");

   //точка входа в скрипт
   session_start();
   $DB = ibase_pconnect($db_name, $db_user, $db_password);
   if(!$DB)
   {
      exit;
   }
   if(isset($_REQUEST['id']))
   {
      $id_playing = $_REQUEST['id'];
      settype($id_playing, 'integer');
   }   
   else exit();

   $query_str = "select * from playing where id = {$id_playing}";
   $query = ibase_query($DB, $query_str);
   $G = ibase_fetch_object($query);
   if(!$G) exit();

   $query_str = "select tournaments.show_prg ".
                "from tournaments, slv_play, gm_slv ".
                "where tournaments.id=gm_slv.id_trnmnt and slv_play.id_playing={$id_playing} and slv_play.id_gm_slv=gm_slv.id";
   $query = ibase_query($DB, $query_str);
   $T = ibase_fetch_object($query);
   if(!$T) exit();

   $G->LOGFILE = trim($G->LOGFILE);
   if(file_exists($G->LOGFILE))
   {
      echo "<script>\n";
      include "{$G->LOGFILE}";
      echo "</script>\n\n";
   }
   
   $T->SHOW_PRG = trim($T->SHOW_PRG);
   if(file_exists($T->SHOW_PRG))
   {
      include "{$T->SHOW_PRG}";
   }

?>