
<html><head>
<meta http-equiv="Content-Type" content="text/html; charset=windows-1251"><title>АВТ ВоГТУ - Турниры игровых компьютерных пограмм</title>
   <link rel="STYLESHEET" type="text/css" href="trnmnt.css"></head><body>
<table border="0" cellpadding="0" cellspacing="0" width="100%">
<tbody>
<tr><td valign="top">
   <table class="tbhead" align="center" border="1" cellpadding="5" width="100%"><tbody>
   <tr align="center">
      <td width="90"><a href="http://atpp.vstu.edu.ru/" style="border: 0px none ;"><img alt="AVT" src="atpphead2.gif" align="middle" border="0" height="69" width="73"></a></td>
      <td width="*"><h1 style="font-size: 24pt;" align="center"><a href="http://localhost:8000/dir_trnmnt/trnmnt.php">Турниры игровых компьютерных программ</a></h1></td>
      <td align="center" nowrap="nowrap" width="200"><a href="http://localhost:8000/dir_trnmnt/login.php">Вход</a><br><a href="http://atpp.vstu.edu.ru/cgi-bin/aregister.pl">Регистрация</a><br><a href="http://localhost:8000/dir_trnmnt/stats.php">Рейтинг авторов</a><br>      </td>
   </tr>
   </tbody></table>
</td></tr></tbody></table>


<br><br>

<table id='X0' ></table>

<table align="center" width="200">
  <tr>
   <td align="left">
     <input type="button" value=" << " style="font-size:14pt" onclick="prev();">
   </td>
   <td align="right">
     <input type="button" value=" >> "  style="font-size:14pt" onclick="next();">
   </td>
  </tr>
</table>

</body></html>

<script>
var s= "";
var patt=/(\d+)(\s+)(\d+)/g;
var z= patt.exec(a1[0]);
var N=z[1],M=z[3];
var I=-1;
for(inn=0;inn<N;inn++)
{
  s=s+"<tr>";
  for(var im=0;im<M;im++)
  {
    s=s+"<td>&nbsp&nbsp</td>"
  } 
  s=s+"</tr>";
}
X0.outerHTML="<table id=\'X0\' class=\"tbbd2\" align=\"center\" >"+s+"</table>"

function prev()
{
  if(I<=0) return;
  var patt1=/(\d+)(\s+)(\d+)/g;
  var patt2=/(\d+)(\s+)(\d+)/g;
  cord1 = patt1.exec(a3[I].Move);
  if(cord1)
  { 
    X0.rows(parseInt(cord1[1])-1).cells(parseInt(cord1[3])-1).innerHTML="&nbsp&nbsp";
    I--;
    cord2 = patt2.exec(a3[I].Move);
    if(cord2)
        X0.rows(parseInt(cord2[1])-1).cells(parseInt(cord2[3])-1).style.color='red';
  }
}

function next()
{
  if(I>=(a3.length-1))     return;
  I++;
  var patt1=/(\d+)(\s+)(\d+)/g;
  var patt2=/(\d+)(\s+)(\d+)/g;
  cord1 = patt1.exec(a3[I].Move);
  if(cord1) 
  {
    X0.rows(parseInt(cord1[1])-1).cells(parseInt(cord1[3])-1).innerHTML=a2[a3[I].Player];
    X0.rows(parseInt(cord1[1])-1).cells(parseInt(cord1[3])-1).style.color='red';
    if(I>0)
    { 
      cord2 = patt2.exec(a3[I-1].Move);
      if(cord1) 
        X0.rows(parseInt(cord2[1])-1).cells(parseInt(cord2[3])-1).style.color='blue';
    }
  }
}
</script>
