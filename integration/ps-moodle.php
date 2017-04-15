<?php include("#config.php"); ?>
<html>
<head>
<title>Переход к Moodle</title>
</head>
<body>
<?php 
$url=getenv("HTTP_REFERER"); 
$urlpath=parse_url($url, PHP_URL_PATH);
$urlhost=$_SERVER['HTTP_HOST'];
if ($urlpath=="/cgi-bin/arh_problems.pl") 
{
//Подключение к БД
$dbh = ibase_connect($f_host, $f_username, $f_password) 
or die("Невозможно подключиться к БД Firebird ". ibase_error()); 
//Проверка переданного массива значений
$query  = parse_url($url, PHP_URL_QUERY);
$array = parse_query($query);
//Если открыта страница с темой
if (isset ($array[id_tm])) 
{
$id_tm=$array[id_tm];
$sql = "SELECT * FROM TEMA WHERE ID_TM='$id_tm'"; 
$result = ibase_query($dbh, $sql); 
if ($result==0) echo "Ошибка при получении данных из БД<br>"; 
while ($row = ibase_fetch_object($result))
{ 
echo $row ->ID_TM, "<br>", $row ->ID_MOODLE_COURSE, "<br>";
$id_moodle_course=$row ->ID_MOODLE_COURSE;
}
}
//Если открыта страница с задачей
elseif (isset ($array[id_prb]))
{
$id_prb=$array[id_prb];
$sql = "SELECT * FROM PROBLEMS WHERE ID_PRB='$id_prb'"; 
$result = ibase_query($dbh, $sql); 
if ($result==0) echo "Ошибка при получении данных из БД<br>"; 
while ($row = ibase_fetch_object($result)) 
{
echo $row ->ID_PRB, "<br>", $row ->ID_MOODLE_COURSE, "<br>";
$id_moodle_course=$row ->ID_MOODLE_COURSE;
}
}
else $id_moodle_course=1;
//Переход к нужному курсу
header( "Location: http://$urlhost/moodle/course/view.php?id=$id_moodle_course" );
//Закрытие сеанса связи с БД
ibase_close ($dbh);
}
else header( "Location: http://$urlhost/moodle/" );

//Функция преобразования  строки с переданными параметрами в ассоциативный массив
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