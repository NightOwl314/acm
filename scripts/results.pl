#!c:\perl\bin\perl.exe

#������������ ����������� ������ �������� ������ "�����������"

use DBI;
use IO;
use POSIX;

require 'common_func.pl';
use vars qw($request $db $DirTemplates $incgi %cookies %ENV);

%stud_list=(
  22101=>"������� ��������� �������������",
  22137=>"��������� ����� ���������",
  22106=>"������� ��������� ����������",
  22393=>"������ ������ �����������",
  22398=>"�������� ������ ����������",
  22799=>"������ ������ �����������",
  22542=>"������� ��������� ���������",
  22843=>"����� ����� ���������",
  22842=>"������� ������� ���������",
  22819=>"����� ������ ����������",
  22867=>"���� ������� ����������",
  22868=>"������ �������� ����������"
);

@problems_list=(16,19,97,99,198,199,6,11,38,626,627,624,71,72,82,642,643,644,423,646,647,653,654,655,681,682,683,473,680,684,685,686);


read_config();
connect_db();

print header(-charset=>"Windows-1251",
               -cookie=>[$cookie1,$cookie2],
               -cache_control=>"no-cached",
               -pragma=>"no-cache"
            );

print "<center><b> ������� ���������� ������� ����� � ������� ������ '�����������' </center> </b> <br>";
print "<center>";

#������� ������� � �������������� �����
print "<table border=1 cellspacing=0 cellpadding=0>\n";
print "<tr>\n<td align=center>���������/������</td>";
$prb_list_str="-1";
foreach $i (@problems_list) {
  $prb_list_str.=",$i";
}

$query=<<SQL;
  select id_prb,name from problems_lng where id_prb in ($prb_list_str) and id_lng='ru' order by id_prb
SQL
@prb_ids=();
$n=0;

 $sth = $db->prepare($query);
 $sth->execute;
 while (@row=$sth->fetchrow_array) {
   ($prb_name,$prb_id) = ($row[1],$row[0]);
   $prb_name =~ m/(.*?)\s*$/;

   $prb_ids[$n]=$prb_id;
   $n++;

   print "<td width=30 align=center title='$1'>";
   print "<a href=/cgi-bin/arh_problems.pl";
   print "?id_prb=$prb_id>";
   print "$row[0]";
   print "</a></td>";
 }
print "</tr>";

#������ ������� ������ �� ���������
foreach $i (keys(%stud_list)) {
 $query=<<SQL;
   select distinct id_prb from status where id_publ=$i and id_rsl=0 and id_prb in ($prb_list_str)
SQL

  $sth = $db->prepare($query);
  $sth->execute;
  %stud_sol=();
  while (@row=$sth->fetchrow_array) {
   $stud_sol{$row[0]}=1;  
  }
  print "<tr>\n";
  print "<td>".$stud_list{$i}."</td>";
  foreach $j (@prb_ids) {
    print "<td>";
    if ($stud_sol{$j}) {print  "+";} else {print "&nbsp;"}
    print "</td>";

  }
  print "</tr>\n";
}


print "</table>\n";

print "</center>";

