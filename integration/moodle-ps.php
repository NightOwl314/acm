<?php include("#config.php"); ?>
<html>
<head>
<title>������� � ����������� ������� ������� ���</title>
</head>
<body>
<?php 
// ��������� id_section �� ������� GET
$id_section=$_GET['id_section'];
$urlhost=$_SERVER['HTTP_HOST'];
if (isset ($id_section)) 
{
//����������� � ��
$dbh = mysql_connect($m_host, $m_username, $m_password) 
or die ("���������� ������������ � �� MySQL");
mysql_select_db($m_database, $dbh);
// SQL-������
$sql =mysql_query("SELECT ID_PS_TEMA FROM mdl_course_sections WHERE id='$id_section'"); 
while ($dbh = mysql_fetch_object($sql))
{
$id_tm=$dbh ->ID_PS_TEMA;
}
//������� � ������ ���� � ����������� �������
header( "Location: http://$urlhost/cgi-bin/arh_problems.pl?id_tm=$id_tm" );
}
else
{
echo "������ ��� ���������� id_section �� ������� GET<br>";
//������� � ������� ��������  � ����������� �������
header( "Location: http://$urlhost/cgi-bin/arh_problems.pl?id_tm=-1" );
};
mysql_close($dbh);
?>
</body>
</html>