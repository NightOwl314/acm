<?php 
	require_once("includes/dbconfig.php");
	require_once("includes/session.php");
	require_once("includes/functions.php");
	require_once("includes/form_functions.php");
	require_once("includes/book_functions.php");
	
	$ldapconfig['ldap_login'] = 'ldap-user';
	$ldapconfig['ldap_pass'] = 'ldap';
	
	
	$ldapconfig['host'] = 'localhost';
	$ldapconfig['port'] = NULL;
	$ldapconfig_dn[0] = "OU=Students,DC=avt,DC=vstu,DC=edu,DC=ru";
	$ldapconfig_dn[1] = "OU=Teachers,DC=avt,DC=vstu,DC=edu,DC=ru";
	$ldapconfig['authrealm'] = 'My Realm';

	if (isset($_POST['submit']) && isset($_POST['login']) ) // form login submitted.
	{
		$errors = array();
		//validate fields
		$required_fields = array("login", "pass");
		
		$username = "";
		$group  = "";
		$errors = array_merge($errors, check_required_fields($required_fields, $_POST));
		$login = $_POST['login'];
		$pass = $_POST['pass'];
		$login = trim(ibase_prep($login));
		//$pass = trim(ibase_prep($pass));
		$hashed_pass = md5($pass);
		
		if (empty($errors))
		{
			//echo $pass;
			$ds=ldap_connect($ldapconfig['host']);
			if ($ds)
				$admin_bind = ldap_bind($ds,$ldapconfig['ldap_login'], 
					$ldapconfig['ldap_pass']);
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
							//echo "count $count";
							$info =  ldap_get_entries($ds, $sr);
							//echo "dn = {$info[0]['dn']}";
							$username = $info[0]["cn"][0];
							
							if(preg_match('/OU=(Students|Teachers),/',
								$info[0]["dn"], $matches))
							{
								$group = $matches[1];
							}
							
							//print_r($info);
							//echo "<br>name=$username";
							break;
							
							
						}
					}
					else if ($count != 1 || !$info)
						$found_user = false;
				}
				
			}
			else
				$found_user = false;
	
			
			if ($ds && $username != "")
			{
				$bind = ldap_bind($ds,$username, $pass);
				if (!$bind)
				{
					$found_user = false;
					//echo "notbind";	
				}
						
			}
			
			//$r = ldap_search($ds, $ldapconfig['basedn'], 'sn=' . $username);
			//echo $r;
			//if ($r)
			//	$result = ldap_get_entries( $ds, $r);
			//else
			//	$found_user = false;
			//print_r($result);

			if (!$found_user)
			{
				$msg = "Неправильное имя пользователя или пароль!";
				$_SESSION['errmsg'] = $msg;
				unset($_SESSION['user_id']); 
				unset($_SESSION['username']);
				unset($_SESSION['group']);
				redirect_to("index.php");
				
				
			}
			else if ($bind && $info)
			{
				$_SESSION['user_id']  = $login;
				$_SESSION['username'] = $username;
				$_SESSION['group'] = $group; 
				$_SESSION['errmsg'] = ""; 
				//unset($_POST['submit']);
				//print_r($_SESSION);
				redirect_to("index.php");
			}
				 	
		}
		else
		{
			echo "Error<br>";
		}
		   
		///echo "<br>{$_POST['login']}<br>";
		///echo "<br>{$_POST['pass']}<br>";
		///exit();
	}
	
?>

<form action="login.php" method="post" >
<input name="login" type="text" size="20" maxlength="100">
<input name="pass" type="password" size="20" maxlength="32">
<!--<input name="remember" type="checkbox" value="запомнить"> запомнить-->
<input name="submit" type="submit" value="Вход">
<?php
	if (isset($_SESSION['errmsg']))
	{
		echo "<div class=\"error\">
		{$_SESSION['errmsg']}
		</div>";
		$_SESSION['errmsg'] = "";
	} 	
?>
</form>