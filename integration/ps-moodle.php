<?php include("#config.php"); ?>
<html>
<head>
<title>������� � Moodle</title>
</head>
<body>
<?php 
$url=getenv("HTTP_REFERER"); 
$urlpath=parse_url($url, PHP_URL_PATH);
$urlhost=$_SERVER['HTTP_HOST'];
if ($urlpath=="/cgi-bin/arh_problems.pl") 
{
//����������� � ��
$dbh = ibase_connect($f_host, $f_username, $f_password) 
or die("���������� ������������ � �� Firebird ". ibase_error()); 
//�������� ����������� ������� ��������
$query  = parse_url($url, PHP_URL_QUERY);
$array = parse_query($query);
//���� ������� �������� � �����
if (isset ($array[id_tm])) 
{
$id_tm=$array[id_tm];
$sql = "SELECT * FROM TEMA WHERE ID_TM='$id_tm'"; 
$result = ibase_query($dbh, $sql); 
if ($result==0) echo "������ ��� ��������� ������ �� ��<br>"; 
while ($row = ibase_fetch_object($result))
{ 
echo $row ->ID_TM, "<br>", $row ->ID_MOODLE_COURSE, "<br>";
$id_moodle_course=$row ->ID_MOODLE_COURSE;
}
}
//���� ������� �������� � �������
elseif (isset ($array[id_prb]))
{
$id_prb=$array[id_prb];
$sql = "SELECT * FROM PROBLEMS WHERE ID_PRB='$id_prb'"; 
$result = ibase_query($dbh, $sql); 
if ($result==0) echo "������ ��� ��������� ������ �� ��<br>"; 
while ($row = ibase_fetch_object($result)) 
{
echo $row ->ID_PRB, "<br>", $row ->ID_MOODLE_COURSE, "<br>";
$id_moodle_course=$row ->ID_MOODLE_COURSE;
}
}
else $id_moodle_course=1;
//������� � ������� �����
header( "Location: http://$urlhost/moodle/course/view.php?id=$id_moodle_course" );
//�������� ������ ����� � ��
ibase_close ($dbh);
}
else header( "Location: http://$urlhost/moodle/" );

//������� ��������������  ������ � ����������� ����������� � ������������� ������
function parse_query($var)
{ 
$var  = html_entity_decode($var);
$var  = explode('&', $var);
$arr  = array();
foreach($var as $val)
   {
    $x = explode('=', $val);
    $arr[$x[0]] = $x[1];
   }
unset($val, $x, $var);
return $arr;
}
?>
</body>
</html>