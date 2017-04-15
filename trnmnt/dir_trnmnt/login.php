<?php

   require_once("autor.php");



   function login_trnmnt($user_login, $user_pwd)
   {
      global $DB, $dir_trnmnt, $host, $RedirectGames;

      $user_login = trim($user_login);
      $user_pwd   = trim($user_pwd);

      $query_str = "select * from authors where login='{$user_login}' and pwd='{$user_pwd}'";
      $query = ibase_query($DB, $query_str);
      $row = ibase_fetch_object($query);
      //var_export($row);
      if($row)
      {
         $_SESSION['trnmnt_user'] = $row->ID_PUBL;
         ibase_free_result($query);
         Header($RedirectGames);
         return true;
      }
      ibase_free_result($query);
      return false;
   }



   //точка входа

   /*
   @$_SESSION = array();
   @unset($_COOKIE[session_name()]);
   @session_destroy();
   */

   //ini_set("session.use_trans_sid", true);
   session_start();
   $DB = ibase_pconnect($db_name, $db_user, $db_password);
   if(!$DB)
   {
      echo "Ошибка соединения с базой данных...";
      exit;
   }

   if(isset($_REQUEST['user_login']))
   {
      $user_login = $_REQUEST['user_login'];
      settype($user_login, 'string');
   }   
   else $user_login = "";
   if(isset($_REQUEST['user_pwd']))
   {
      $user_pwd = $_REQUEST['user_pwd'];
      settype($user_pwd, 'string');
   }   
   else $user_pwd = false;

   $ok = false;
   if($user_login && $user_pwd)
   {
      $ok = login_trnmnt($user_login, $user_pwd);
   }

   echo "<html>\n";
   DisplayHead();
   echo "<body>\n";
   DisplayHeadTable(LVL_GUEST);

   echo "\n<br>\n";

   echo "<br><br>\n\n";
   echo "<form name='form1' action=\"{$host}{$dir_trnmnt}login.php\" method=\"post\" enctype=\"multipart/form-data\">\n";
   echo "<table class=\"tbbd\" align=\"center\" border=\"2\" cellpadding=\"5\">\n";
   echo "<tbody>\n<tr>\n   <td colspan=\"2\"><h5 align=\"center\">Вход</h5></td>\n</tr>\n";
   echo "<tr><td colspan=\"2\" class=\"separ\" align=\"left\"><hr></td></tr>\n<tr>\n";
   echo "   <td align=\"right\" width=\"120\"><h5>Имя:</h5></td>\n";
   echo "   <td align=\"left\" width=\"300\"><input name=\"user_login\" size=\"32\" type=\"text\"></td>\n</tr>\n<tr>\n";
   echo "   <td align=\"right\" width=\"120\"><h5>Пароль:</h5></td>\n";
   echo "   <td align=\"left\" width=\"300\"><input name=\"user_pwd\" size=\"32\" type=\"password\"></td>\n</tr>\n";
   echo "<tr><td colspan=\"2\" class=\"separ\" align=\"left\"><hr></td></tr>\n<tr>\n";
   echo "<tr><td colspan=\"2\" align=\"center\"><input value=\"Войти\" class=\"submit_btn\" type=\"submit\" style=\"font-size: 12pt\"></td></tr>\n";
   echo "</tbody></table>";
   echo "\n</form>";
   echo "\n\n</body></html>";
?>