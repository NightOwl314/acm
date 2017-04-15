<!DOCTYPE html PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN">
<html>
<head>
  <meta http-equiv="Content-Type" content="text/html; charset=Windows-1251">
  $REDIR
  <title>$TITLE</title>
  <link rel="StyleSheet" type="text/css" href="$CSS">
</head>
<body>
<table width="100%" height="100%" border="0" cellspacing="0" cellpadding="0"><tr height="100%"><td valign="top">

<table class="tbhead" width="100%" border="1" align="center" cellpadding="10">
 <tr align="center">
   <td width="90">
     <center><b>Language:</b></center><br>
     <a href="cnt_common.pl?action=change_lang&lang=en">English</a><br>
     <a href="cnt_common.pl?action=change_lang&lang=ru">Russian</a>
   </td>
   <td width="*">
     <img src="/title_en.gif">
     <table border="0" width="100%" align="center" cellspacing="15">
<!--
       <tr align="center">
         <td><a class="menu_lnk" href="/cgi-bin/arh_problems.pl">Архив задач</a></td>
         <td><a class="menu_lnk" href="/cgi-bin/submit.pl">Послать задачу</a></td>
         <td><a class="menu_lnk" href="/cgi-bin/status.pl">On-line статус</a></td>
         <td><a class="menu_lnk" href="/cnt-sys/cnt_common.pl?action=active_contests">Турниры</a></td>
       </tr>
-->
     </table>
   </td>
  <FORM ACTION="/cgi-bin/statistica.pl" METHOD="GET">
   <td align="left" width="185" nowrap>
     <center><b>Для участников:</b></center>
     <a href="/cgi-bin/aregister.pl">Регистрация</a>&nbsp;&nbsp;||&nbsp;&nbsp;
     <a href="$LINK_LOGIN">Вход</a><br>
     <a href="cnt_team.pl">Список турниров</a><br>
     $LINK_MASTER
     $LINK_ADMIN
   </td>
  </FORM>
 </tr>

</table>

<table class="other" border="0" width="100%">
<tr><td>
$LOGIN_MSG
</td></tr>
</table>
$MAIN

</td></tr><tr><td valign="bottom">

<table class="other" width="100%" border="0" align="center" cellpadding="1">
<tr>
<td align="center">© Copyright 2004-2011 <a href="http://www.vstu.edu.ru/">ВоГТУ</a>, <a href="http://atpp.vstu.edu.ru/">АВТ</a>, <a href="mailto:dens-spam@yandex.ru">Носов Д.А.</a>, <a href="mailto:nikos@front.ru">Смоленцев К.Н.</a></td>
</tr>
</table>

</td></tr></table>

</body>
</html>
