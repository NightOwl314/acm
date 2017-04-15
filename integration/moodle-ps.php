<?php include("#config.php"); ?>
<html>
<head>
<title>Переход к проверяющей системе кафедры АВТ</title>
</head>
<body>
<?php 
// Считываем id_section из массива GET
$id_section=$_GET['id_section'];
$urlhost=$_SERVER['HTTP_HOST'];
if (isset ($id_section)) 
{
//Подключение к БД
$dbh = mysql_connect($m_host, $m_username, $m_password) 
or die ("Невозможно подключиться к БД MySQL");
mysql_select_db($m_database, $dbh);
// SQL-запрос
$sql =mysql_query("SELECT ID_PS_TEMA FROM mdl_course_sections WHERE id='$id_section'"); 
while ($dbh = mysql_fetch_object($sql))
{
$id_tm=$dbh ->ID_PS_TEMA;
}
//Переход к нужной теме в проверяющей системе
header( "Location: http://$urlhost/cgi-bin/arh_problems.pl?id_tm=$id_tm" );
}
else
{
echo "Ошибка при считывании id_section из массива GET<br>";
//Переход к главной странице  в проверяющей системе
header( "Location: http://$urlhost/cgi-bin/arh_problems.pl?id_tm=-1" );
};
mysql_close($dbh);
?>
</body>
</html>