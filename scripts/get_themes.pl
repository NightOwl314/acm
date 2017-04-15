#!c:\perl\bin\perl.exe

use DBI;
use FCGI;
use IO;
use CGI qw(:standard);
use CGI::Cookie;
use CGI::Carp  qw(fatalsToBrowser);
use POSIX;

require 'common_func.pl';
use vars qw($request $db $DirTemplates $incgi %cookies %ENV);


read_config();
connect_db();

#язык по умолчанию
$sth = $db->prepare("select def_lng from const");
$sth->execute;
@row = $sth->fetchrow_array;
$lng_def=$row[0];
$sth->finish;


my $cgi = new CGI;
my $id_par = $cgi->param('id_tema');
my $id_lng = $cgi->param('id_lng');
	my $small_root = "is null";
	my $add_info = "";
	my $sth=0;
	my $query="";
	my $checkbox_ST = "<input type = 'checkbox' name = 'themechek' value = '";
	my $checkbox_END = "'>";
	if ($id_par > 0) {
		$small_root = " = ".$id_par;
	}
	$query=<<SQL;
  	select tema.id_tm, tema.order_pos, tema_lng.name, tema.prb_cnt  from tema, tema_lng 
  	where tema.small_root $small_root 
  	and tema_lng.id_tm = tema.id_tm 
  	and tema_lng.id_lng= '$id_lng' 
  	order by order_pos;
SQL
  	
  	$sth = $db->prepare($query);
	$sth->execute;
		
	while (@row = $sth->fetchrow_array) {
  		my $id_tema = $row[0]; # id tema
  		my $order_pos = $row[1];
  		my $count = ($row[3] == -1) ? "-" : $row[3]; 
  		
  		$add_info .= "<table  class ='themetable'>
						<col id='c_one' />
						<col id='c_two' />
						<col id='c_three' />
						<col id='c_four' />
						<col id='c_five' />
						<col id='c_six' />";
		$add_info = $add_info."<tr>";
		$add_info .= "<td onclick = 'getTemaContent(this,$id_tema);'><button  class = 'openButton' >+</button></td>";
		$add_info = $add_info."<td>".$checkbox_ST.$id_tema.$checkbox_END."</td>";
		$add_info = $add_info."<td><a href='/cgi-bin/edit_tema.pl?id_tema=$id_tema'>$id_tema</a></td>";
		$add_info = $add_info."<td>$order_pos</td>";
		$add_info = $add_info."<td>$row[2]</td>";
		$add_info = $add_info."<td>$count</td>";
		$add_info = $add_info."</tr>";
		$add_info .= "</table>";
  	}
	print "Content-Type: text/html;  charset=windows-1251\n\n";	
  	print $add_info;
  	print "\n";
$db->disconnect;
POSIX:_exit(0);