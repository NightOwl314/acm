#!c:\perl\bin\perl.exe

use DBI;
use FCGI;
use IO;
use CGI qw(:standard);
use CGI::Cookie;
use CGI::Carp qw(fatalsToBrowser);
use POSIX;
use Time::Local;

require 'common_func.pl';
use vars qw($request $db $DirTemplates $incgi %cookies %ENV);

read_config();
connect_db();

#язык по умолчанию
$sth = $db->prepare("select def_lng from const");
$sth->execute;
@row     = $sth->fetchrow_array;
$lng_def = $row[0];
$sth->finish;

$incgi       = new CGI;
$action_name = $incgi->param('action');

$result = "";
if ( $action_name eq "getGroupForTema" ) {
	$result .= getGroupsForTema($incgi);
}
elsif ($action_name eq "getUsersForTemaAndGroup") {
	$result .= getUsersForTemaAndGroup($incgi);
} elsif ($action_name eq "getProblemsForUser"){
	$result = getProblemsForUser($incgi);
} elsif ($action_name eq "getUsersForGroup") {
	$result = getUsersForGroup($incgi);
} elsif ($action_name eq "getTemaProblems") {
	$result = getTemaProblems($incgi);
} elsif ($action_name eq "getStProblemsForThemes") {
	$result = getStProblemsForThemes($incgi);
} elsif ($action_name eq "getUsersForGroupEdit") {
	$result = getUsersForGroupEdit($incgi);
} elsif ($action_name eq "getChildGroups") {
	$result = getChildGroups($incgi);
}
print "Content-Type: text/html;  charset=windows-1251\n\n";
print $result;
print "\n";
$db->disconnect;
POSIX: _exit(0);




#возвращаем группы студентов для темы, для которых назначены задания
sub getGroupsForTema {
	my ($incgi)  = @_;
	my $id_tema  = $incgi->param('id_tema');
	my $id_lng   = $incgi->param('id_lng');
	my $id_user  = authenticate_process("true");
	my $add_info = "";
	my $sth      = 0;
	my $query    = "";
	$query = <<SQL;
  	select distinct grp.id_grp, grp_l.name
	from groups grp
		inner join groups_lng grp_l on
		grp.id_grp = grp_l.id_grp and grp_l.id_lng = '$id_lng'
		inner join groups_authors grp_a on
		grp.id_grp = grp_a.id_grp 
		and grp_a.id_publ in 
			(select asg.id_user from assigned_problems asg 
				where asg.id_boss = $id_user
				and asg.id_tm = $id_tema
			)
	where grp.parent = 3		
  	 ;
SQL

	$sth = $db->prepare($query);
	$sth->execute;

	$add_info .= "<div><table  class ='groupTable'>
						<col id='c_one' />
						<col id='c_two' />
						<tr>
						<th></th>
						<th>Группа</th>
						</tr></table>";

	while ( @row = $sth->fetchrow_array ) {
		$add_info = $add_info . "<table  class ='groupTable'>
						<col id='c_one' />
						<col id='c_two' />
						<tr>";
		$add_info = $add_info
		  . "<td align = \"center\" onclick = \"getUsersForTema(this, $id_tema ,$row[0]);\">+</td>";
		$add_info = $add_info . "<td><a href = \"statistica.pl?id_grp=$row[0]\">$row[1]</a></td>";
		$add_info = $add_info . "</tr></table>";

	}
	$add_info .= "</table></div>";

	return $add_info;
}


#Возвращаем пользователей, которым назначены задачи, для определенной группы и темы
sub getUsersForTemaAndGroup {
	my ($incgi)  = @_;
	my $id_group = $incgi->param('id_group');
	my $id_tema = $incgi->param('id_tema');
	my $id_lng  = $incgi->param('id_lng');

	my $id_user = authenticate_process("true");

	my $add_info = "";
	my $sth      = 0;
	my $query    = "";
	$query = <<SQL;
    select authors.id_publ, cast(authors.name as varchar(1000)) 
    ,(select count(assigned_problems.id_asgn) from assigned_problems 
    	where assigned_problems.id_user = authors.id_publ 
    	and assigned_problems.id_boss = $id_user 
    	and assigned_problems.ID_TM = $id_tema ) as "prb_cnt"
    from authors
    where (authors.surname is null or authors.uname is null or authors.patname is null or authors.surname='')
    and authors.id_publ in 
    (	select distinct assigned_problems.id_user 
    	from assigned_problems  
    	inner join groups_authors on
    	assigned_problems.id_user = groups_authors.id_publ 
    	and groups_authors.id_grp = $id_group 
    	where assigned_problems.id_boss = $id_user 
    	and assigned_problems.ID_TM = $id_tema)
    union
    select authors.id_publ, cast( authors.surname||' '||authors.uname||' '||authors.patname as varchar(1000) )
    ,(select count(assigned_problems.id_asgn) from assigned_problems 
    	where assigned_problems.id_user = authors.id_publ 
    	and assigned_problems.id_boss = $id_user 
    	and assigned_problems.ID_TM = $id_tema ) as "prb_cnt"
    from authors 
    where  (authors.surname is  not null and authors.uname is not null and authors.patname is not null and authors.surname <> '')
    and authors.id_publ in 
    (	select distinct assigned_problems.id_user 
    	from assigned_problems
    	inner join groups_authors on
    	assigned_problems.id_user = groups_authors.id_publ 
    	and groups_authors.id_grp = $id_group 
    	where assigned_problems.id_boss = $id_user 
    	and assigned_problems.ID_TM = $id_tema) 
    ;
SQL

	$sth = $db->prepare($query);
	$sth->execute;

	$add_info .= "<div><table  class ='userTable'>
						<col id='c_one' />
						<col id='c_two' />
						<col id='c_three' />
						<tr>
						<th></th>
						<th>Студент</th>
						<th>Количество задач</th>
						</tr></table>";

	while ( @row = $sth->fetchrow_array ) {
		$add_info = $add_info . "<table  class ='userTable'>
						<col id='c_one' />
						<col id='c_two' />
						<col id='c_three' /><tr>";
		$add_info = $add_info
		  . "<td align = \"center\" onclick = \"getProblemsForUser(this, $row[0], $id_tema)\">+</td>";
		$add_info = $add_info . "<td><a href =\"statistica.pl?id_publ=$row[0]\">$row[1]</a></td>";
		$add_info = $add_info . "<td>$row[2]</td>";
		$add_info = $add_info . "</tr></table>";

	}
	$add_info .= "</table></div>";
	return $add_info;
}


#Назначенные задачи пользователю
sub getProblemsForUser {
	my ($incgi) = @_;
	
	my $id_student = $incgi->param('id_student');
my $id_tema    = $incgi->param('id_tema');
my $id_lng     = $incgi->param('id_lng');

my $id_user = authenticate_process("true");

( $status_prb[0] ) = $$text =~ /\$notsubmit\s*=\s*\{(.*?)\}/s;
( $status_prb[1] ) = $$text =~ /\$solve\s*=\s*\{(.*?)\}/s;
( $status_prb[2] ) = $$text =~ /\$notsolve\s*=\s*\{(.*?)\}/s;

my $outDate  = "outDate";
my $normal   = "normal";
my $complete = "complete";
my $hurry_up  = "hurry_up";

my $add_info = "";
my $sth      = 0;
my $query    = "";
$query = <<SQL;
    select asg.id_prb, asg.contr_date,
    prbl.name, prb.hardlevel ,
       (select case when min(id_rsl)=0 and count(id_rsl)>0 then 1 
                  when count(id_rsl)=0 then 0 
                  else 2 end
         from status where id_publ = $id_student and id_prb=asg.id_prb ),
       (select count(s.id_stat) from status s where s.id_publ=$id_student and s.id_prb = asg.id_prb group by s.id_stat)  
    from assigned_problems asg
		left join problems_lng prbl on
		asg.id_prb = prbl.id_prb and prbl.id_lng = 'ru'
		left join problems prb on
		asg.id_prb = prb.id_prb
    where  asg.id_boss = $id_user
    and asg.id_tm = $id_tema
    and asg.id_user = $id_student
    order by asg.contr_date;
SQL

$sth = $db->prepare($query);
$sth->execute;

$add_info .= "<div><table  class ='problemsTable'>
						<col id='c_one' />
						<col id='c_two' />
						<col id='c_three' />
						<col id='c_four' />
						<tr>
						<th>Задача</th>
						<th>Название</th>
						<th>Сложность</th>
						<th>Контрольная дата</th>
						</tr></table>";

while ( @row = $sth->fetchrow_array ) {
	my $solve = $row[4];
	my $classTR = "";
	my $today  = strftime "%d.%m.%Y", localtime;
	my $date = $row[1]; 
	my $s2 = date_to_seconds($date);
	my $s1 = date_to_seconds($today);
	my $beetwin = int(($s2 - $s1)/(24*60*60));
	if ($solve eq "1") {
		$classTR = $complete;
	} elsif ($beetwin <= 0) {
		$classTR = $outDate;
	} elsif ($beetwin > 0 && $beetwin < 7 ) {
		$classTR = $hurry_up;
	} else {
		$classTR = $normal;
	}
	
	$add_info = $add_info . "<table  class ='problemsTable'>
						<col id='c_one' />
						<col id='c_two' />
						<col id='c_three' />
						<col id='c_four' />
						<tr id =  \"$classTR\">";
	$add_info = $add_info . "<td><a href = \"status.pl?id_prb=$row[0]&id_publ=$id_student\">$row[0]<sub>$row[4]</sub></a></td>";
	$add_info = $add_info . "<td><a href = \"arh_problems.pl?id_prb=$row[0]\">$row[2]</a></td>";
	$add_info = $add_info . "<td>$row[3]</td>";
	$add_info = $add_info . "<td>$row[1]</td>";
	$add_info = $add_info . "</tr></table>";

}
$add_info .= "</table></div>";
return $add_info;
	
}

#Конвертим дату в секунды
sub date_to_seconds {
    	my ($curdate) = @_;
    	my ($day, $month, $year) = split('[/.-]', $curdate);
    	#return midnight on the day in question in 
    	#seconds since the epoch
    	return timelocal(0,0,0,$day,$month - 1,$year);;
}

#Возвращает студентов для группы
sub getUsersForGroup {
	my ($incgi ) = @_;
	my $id_group = $incgi->param('id_gpoup');
	my $id_lng = $incgi->param('id_lng');
	my $add_info = "";
	my $sth=0;
	my $query="";
	my $checkbox_ST = "<input type = 'checkbox' name = 'student_check' value = '";
	my $checkbox_END = "'>";
	$query=<<SQL;
	select authors.id_publ, cast(authors.name as varchar(1000)) 
    from authors, groups_authors
    where (authors.surname is null or authors.uname is null or authors.patname is null or authors.surname='')
    and authors.id_publ = groups_authors.id_publ and groups_authors.id_grp = $id_group
    union
    select authors.id_publ, cast( authors.surname||' '||authors.uname||' '||authors.patname as varchar(1000) )
    from authors ,groups_authors
    where  (authors.surname is  not null and authors.uname is not null and authors.patname is not null and authors.surname <> '')
    and authors.id_publ = groups_authors.id_publ and groups_authors.id_grp = $id_group
    ;
SQL
  	
 	$sth = $db->prepare($query);
	$sth->execute;
		
	$add_info .= "<div><table  class ='userTable'>
						<col id='c_one' />
						<col id='c_two' />
						<tr>
						<th><input type=\"checkbox\" onclick =\"selectAllUser\"></th>
						<th>Студент</th>
					
						</tr>";
			
	while (@row = $sth->fetchrow_array) {
 		$add_info = $add_info."<tr>";
		$add_info = $add_info."<td>".$checkbox_ST.$row[0].$checkbox_END."</td>";
		$add_info = $add_info."<td><a href =\"statistica.pl?id_publ=$row[0]\">$row[1]</td>";
		#$add_info = $add_info."<td></td>";
		$add_info = $add_info."</tr>";
		
    }
  	$add_info .= "</table></div>";
	return $add_info;
	
}

sub getTemaProblems {
	my ($incgi) = @_;
	my $id_tema = $incgi->param('id_tema');
	my $id_lng = $incgi->param('id_lng');
	my $add_info = "";
	my $sth=0;
	my $query="";
	my $checkbox_ST = "<input type = 'checkbox' name = 'problems_check' value = '";
	my $checkbox_END = "'>";
	$query=<<SQL;
  select pr.id_prb,pl.name,st.cnt,pr.subms_cnt,pr.asolv_cnt,pr.id_creator, 
      pr.hardlevel, tp.order_pos
     from tm_prb tp inner join problems pr on tp.id_prb=pr.id_prb 
          inner join statistica st on st.id_prb=pr.id_prb
          inner join problems_lng pl on pl.id_prb=pr.id_prb and pl.id_lng='$id_lng'
     where st.id_rsl=0 and tp.id_tm=$id_tema 
     order by tp.order_pos, pl.name
SQL

 	$sth = $db->prepare($query);
	$sth->execute;
		
	$add_info .= "<div><table  class ='problemsTable'>
						<col id='c_one' />
						<col id='c_two' />
						<col id='c_three' />
						<col id='c_four' />
						<tr>
						<th></th>
						<th>Номер</th>
						<th>Название</th>
						<th>Баллы</th>
						</tr>";
			
	while (@row = $sth->fetchrow_array) {
 		$add_info = $add_info."<tr>";
		$add_info = $add_info."<td>".$checkbox_ST.$row[0].$checkbox_END."</td>";
		$add_info = $add_info."<td>$row[0]</td>";
		$add_info = $add_info."<td><a href = \"/arh_problems.pl?id_prb=$row[0]\">$row[1]</a></td>";
		$add_info = $add_info."<td>$row[6]</td>";
		$add_info = $add_info."</tr>";
		
    }
  	$add_info .= "</table></div>";
	return $add_info;
	
}


sub getStProblemsForThemes {

my ($incgi) = @_;
	
my $id_tema    = $incgi->param('id_tema');
my $id_lng     = $incgi->param('id_lng');

my $id_user = authenticate_process("true");

( $status_prb[0] ) = $$text =~ /\$notsubmit\s*=\s*\{(.*?)\}/s;
( $status_prb[1] ) = $$text =~ /\$solve\s*=\s*\{(.*?)\}/s;
( $status_prb[2] ) = $$text =~ /\$notsolve\s*=\s*\{(.*?)\}/s;

my $outDate  = "outDate";
my $normal   = "normal";
my $complete = "complete";
my $hurry_up  = "hurry_up";

my $add_info = "";
my $sth      = 0;
my $query    = "";
if ($id_tema > 0) {
$query = <<SQL;
    select asg.id_prb, asg.contr_date,
    prbl.name, prb.hardlevel ,
       (select case when min(id_rsl)=0 and count(id_rsl)>0 then 1 
                  when count(id_rsl)=0 then 0 
                  else 2 end
         from status where id_publ = $id_user and id_prb=asg.id_prb ) as "status",
       (select count(s.id_stat) from status s where s.id_publ=$id_user and s.id_prb = asg.id_prb group by s.id_stat)  
    from assigned_problems asg
		left join problems_lng prbl on
		asg.id_prb = prbl.id_prb and prbl.id_lng = 'ru'
		left join problems prb on
		asg.id_prb = prb.id_prb
    where  
    asg.id_tm = $id_tema
    and asg.id_user = $id_user
    order by asg.contr_date
    ;
SQL
} else {
$query = <<SQL;
    select asg.id_prb, asg.contr_date,
    prbl.name, prb.hardlevel ,
       (select case when min(id_rsl)=0 and count(id_rsl)>0 then 1 
                  when count(id_rsl)=0 then 0 
                  else 2 end
         from status where id_publ = $id_user and id_prb=asg.id_prb ) as "status",
       (select count(s.id_stat) from status s where s.id_publ=$id_user and s.id_prb = asg.id_prb group by s.id_stat)  
    from assigned_problems asg
		left join problems_lng prbl on
		asg.id_prb = prbl.id_prb and prbl.id_lng = 'ru'
		left join problems prb on
		asg.id_prb = prb.id_prb
    where  
    asg.id_user = $id_user
    order by asg.contr_date ;
SQL
	
}

$sth = $db->prepare($query);
$sth->execute;

$add_info .= "<div><table  class ='problemsTable'>
						<col id='c_one' />
						<col id='c_two' />
						<col id='c_three' />
						<col id='c_four' />
						<tr>
						<th>Задача</th>
						<th>Название</th>
						<th>Сложность</th>
						<th>Контрольная дата</th>
						</tr></table>";

while ( @row = $sth->fetchrow_array ) {
	my $solve = $row[4];
	my $classTR = "";
	my $today  = strftime "%d.%m.%Y", localtime;
	my $date = $row[1]; 
	my $s2 = date_to_seconds($date);
	my $s1 = date_to_seconds($today);
	my $beetwin = int(($s2 - $s1)/(24*60*60));
	if ($solve eq "1") {
		$classTR = $complete;
	} elsif ($beetwin <= 0) {
		$classTR = $outDate;
	} elsif ($beetwin > 0 && $beetwin < 7 ) {
		$classTR = $hurry_up;
	} else {
		$classTR = $normal;
	}
	
	$add_info = $add_info . "<table  class ='problemsTable'>
						<col id='c_one' />
						<col id='c_two' />
						<col id='c_three' />
						<col id='c_four' />
						<tr id =  \"$classTR\">";
	$add_info = $add_info . "<td><a href = \"status.pl?id_prb=$row[0]&id_publ=$id_user\">$row[0]<sub>$row[4]</sub></a></td>";
	$add_info = $add_info . "<td><a href = \"arh_problems.pl?id_prb=$row[0]\">$row[2]</a></td>";
	$add_info = $add_info . "<td>$row[3]</td>";
	$add_info = $add_info . "<td>$row[1]</td>";
	$add_info = $add_info . "</tr></table>";

}
$add_info .= "</table></div>";
return $add_info;

	
}


#Возвращает пользователей для группы
sub getUsersForGroupEdit {
	my ($incgi ) = @_;
	my $id_group = $incgi->param('id_group');
	my $id_lng = $incgi->param('id_lng');
	my $add_info = "";
	my $sth=0;
	my $query="";
	my $checkbox_ST = "<input type = 'checkbox' name = 'student_check' value = '";
	my $checkbox_END = "'>";
	$query=<<SQL;
	select authors.id_publ, cast(authors.name as varchar(1000)) 
    from authors, groups_authors
    where (authors.surname is null or authors.uname is null or authors.patname is null or authors.surname='')
    and authors.id_publ = groups_authors.id_publ and groups_authors.id_grp = $id_group
    union
    select authors.id_publ, cast( authors.surname||' '||authors.uname||' '||authors.patname as varchar(1000) )
    from authors ,groups_authors
    where  (authors.surname is  not null and authors.uname is not null and authors.patname is not null and authors.surname <> '')
    and authors.id_publ = groups_authors.id_publ and groups_authors.id_grp = $id_group
    ;
SQL
  	
 	$sth = $db->prepare($query);
	$sth->execute;
		
	$add_info .= "<div><table  class ='userTable'>
						<col id='c_one' />
						<col id='c_two' />
						<tr>
						<th></th>
						<th>Пользователь</th>
					
						</tr>";
			
	while (@row = $sth->fetchrow_array) {
 		$add_info = $add_info."<tr>";
 		$add_info = $add_info."<td></td>";
	$add_info = $add_info."<td><a href =\"manage_access.pl?mode=change_grp&id_publ=$row[0]\">$row[1]</td>";
		
		$add_info = $add_info."</tr>";
		
    }
  	$add_info .= "</table></div>";
	return $add_info;
	
}


sub getChildGroups {
	my ($incgi ) = @_;
	my $id_group = $incgi->param('id_group');
	my $id_lng = $incgi->param('id_lng');
	my $add_text = "";
	my $sth=0;
	my $query="";
	$query=<<SQL;
	select grp.id_grp, grp_l.name
  		from  groups grp
  			inner join groups_lng grp_l on
  			grp.id_grp = grp_l.id_grp 
  			and grp_l.id_lng = '$id_lng'
  		where 
  		grp.parent = $id_group;
SQL
  	
 	$sth = $db->prepare($query);
	$sth->execute;
	$add_text .= " <table class = \"groupsEditTable\">
    <col id =\"c_one\">
    <col id = \"c_two\" >
    <col id = \"c_three\" >
    <col id = \"c_four\" >
    <col id = \"c_five\" >
    <tr>
    	<th>Под-<br>группы</th>
    	<th>П-ли</th>
    	<th>ID</th>
    	<th>Название группы</th>
    	<th>Назначение<br>пользователей</th>
    </tr>
    </table>"	;
	while (@row = $sth->fetchrow_array) {
 		$add_text .= "<table class = \"groupsEditTable\">
		 <col id =\"c_one\">
   		 <col id = \"c_two\">
   		 <col id = \"c_three\" >
    	 <col id = \"c_four\" >
    	 <col id = \"c_five\" >";
		$add_text .= "<tr><td align =\"center\" onclick = \"getChildGroups(this, $row[0]);\"><p>+</p></td>";
		$add_text .= "<td align =\"center\" onclick = \"getUsersForGroupEdit(this, $row[0]);\">+</td>";
		$add_text .= "<td><a href =\"edit_group.pl?action=edit&id_edit=$row[0]\">$row[0]</a></td>";
		$add_text .= "<td>$row[1]</td>";
		$add_text .= "<td><a href =\"edit_group.pl?action=users&id_edit=$row[0]\">>>>></a></td></tr>";
		$add_text .= "</table>";
    }
  	return $add_text;
	
	
}

