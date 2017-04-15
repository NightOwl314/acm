<?php
  exit();
   require_once("autor.php");

	$ldapconfig['ldap_login'] = 'ldap-user';
	$ldapconfig['ldap_pass'] = 'ldap';
	
	$ldapconfig['host'] = 'localhost';
	$ldapconfig['port'] = NULL;
	$ldapconfig_dn[0] = "OU=Students,DC=avt,DC=vstu,DC=edu,DC=ru";
	$ldapconfig_dn[1] = "OU=Teachers,DC=avt,DC=vstu,DC=edu,DC=ru";
	$ldapconfig['authrealm'] = 'My Realm';


function ibase_prep( $value) 
{
	//$magic_quotes_active = get_magic_quotes_gpc();
	// before PHP v4.3.0
	// if magic quotes aren't already on then add slashes manually
	//if( !$magic_quotes_active ) { $value = addslashes( $value ); }
	// if magic quotes are active, then the slashes already exist
    
/* Apostrophes in strings 
If you need to use an apostrophe inside a Firebird string, 
you can "escape" the apostrophe character by preceding it with another apostrophe. 
For example, this string will give an error:
'Joe's Emporium'
because the parser encounters the apostrophe and interprets the string as 
'Joe' followed by some unknown keywords. 
To make this a legal string, double the apostrophe character: 
'Joe''s Emporium'
Notice that this is TWO single quotes, not one double-quote. 
*/

        if (strpos($value, "'"))
            $value = str_replace("'", "''", $value); 
	
    return $value;
}


   function login_trnmnt($user_login, $user_pwd)
   {
      global $DB, $dir_trnmnt, $host, $RedirectGames, $ldapconfig, $ldapconfig_dn;

      $user_login = trim($user_login);
      $user_pwd   = trim($user_pwd);
      /*
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
      */
 echo "!!!!!!";
      //LDAP
      $required_fields = array("login", "pass");
		$username = "";
		$group  = "";
		//$errors = array();
		//$errors = array_merge($errors, check_required_fields($required_fields, $_POST));
		$login = trim(ibase_prep($user_login));
		//$pass = trim(ibase_prep($pass));
		$hashed_pass = md5($user_pwd);
		   $found_user = false;
			$ds=ldap_connect($ldapconfig['host']);
			if ($ds)
				$admin_bind = ldap_bind($ds,$ldapconfig['ldap_login'], $ldapconfig['ldap_pass']);
			else $admin_bind = false;

			if ($admin_bind)
			{
				for ($i=0; $i<count($ldapconfig_dn); $i++)
				{
					$sr = ldap_search($ds, $ldapconfig_dn[$i], 
						'samaccountname=' . $login);
					$count = 0;
					$info = NULL;
					if($sr)
					{
						$count = ldap_count_entries($ds, $sr);
						if ($count > 0) 
						{	
							$found_user = true;
							echo "count $count<br>";
							$info =  ldap_get_entries($ds, $sr);
							echo "dn = {$info[0]['dn']}<br>";
							$username = $info[0]["cn"][0];
							
							if(preg_match('/OU=(Students|Teachers),/',
								$info[0]["dn"], $matches))
							{
								$group = $matches[1];
							}
							
							//print_r($info);
							//echo "<br>name={$username}<br>";
							break;
							
							
						}
					}
					else if ($count != 1 || !$info)
						$found_user = false;
				}
			}
			else
				$found_user = false;
	

			if ($ds && $username !== "")
			{
				$bind = ldap_bind($ds, $username/*, $user_pwd*/);
				//$bind = ldap_bind($ds, $user_login, $user_pwd);
				if (!$bind)
				{
					$found_user = false;
					//echo "notbind";	
				}
						
			}

echo "found_user = {$found_user}<br>";
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
   echo "<form name='form1' action=\"{$host}{$dir_trnmnt}loginEx.php\" method=\"post\" enctype=\"multipart/form-data\">\n";
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