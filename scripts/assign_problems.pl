#!c:\perl\bin\perl.exe

use DBI;
use FCGI;
use IO;
use CGI qw(:standard);
use CGI::Cookie;
use CGI::Carp qw(fatalsToBrowser);
use POSIX;

require 'construct_dt_and_classify_one_sample.pl';
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

fcgi_init();

main_cik:
while ( next_request() ) {

	$db->commit;

	CGI::_reset_globals;
	$incgi = new CGI;

	#а может прислали cookies
	%cookies = parse CGI::Cookie( $ENV{'HTTP_COOKIE'} );

	GetLanguage( \$id_lng, \$cookie1 );

	$id_user = authenticate_process("true");
	next main_cik if ( $id_user . '' eq 'end' );

	if ($id_user && is_can_assign_problems($id_user) eq '1' ) {

		$action_name = $incgi->param("action");

		if ( $action_name eq "assign_problems" ) {
			save_data($id_user, $incgi);
		}
		else {
			$fname = "assign_problem_$id_lng.html";

			#откроем шаблон и считаем все строки
			$string_template = '';
			read_file( "$DirTemplates\\$fname", \$string_template );

			insert_themes_list( \$string_template, $id_lng );
			insert_groups_list( \$string_template, $id_lng );

			#обработаем $include_files(x)
			include_files( \$string_template );

			login_info( \$string_template, $id_user );

			#обработаем $current_page
			current_page( \$string_template );

			#$string_template =~ s/<!--.*?-->//sg;

			print header(
				-charset       => "Windows-1251",
				-cookie        => [ $cookie1, $cookie2 ],
				-cache_control => "no-cached",
				-pragma        => "no-cache"
			);
			print "$string_template";
		}
	}
	else {
		print_err("not allowed");
	}
}

print "\n";
$db->disconnect;
POSIX: _exit(0);

#--------------------------------------

sub insert_themes_list {
	my ( $text, $id_lng ) = @_;
	my $static_parent;
	my $parent_theme = 0;
	$static_parent .= "<option value = '0'> </option>";
	$static_parent .=
	  go_deep_parent( \$static_parent, " is null", $id_lng, "" );
	$static_parent .= "</select>";

	my $theme_list =
"<select onchange =\"getTemaProblems(this); \"  id ='main_theme_select' name=\"main_theme\" >"
	  . $static_parent;

	my $spec_theme_list =
	  "<select style =\"display : none;\" id ='spec_theme_select' name=\"spec_theme\" >" . $static_parent;

	$$text =~ s/\$insert_themes_list/$theme_list/ig;
	$$text =~ s/\$insert_spec_themes_list/$spec_theme_list/ig;

}

sub go_deep_parent {

	my ( $select, $id_cur, $id_lng, $otst ) = @_;
	my $query = <<SQL;
  	select tema.id_tm, tema_lng.name, tema.order_pos  from tema, tema_lng 
  	where tema.small_root $id_cur 
  	and tema_lng.id_tm = tema.id_tm 
  	and tema_lng.id_lng= '$id_lng' 
  	order by order_pos;
SQL
	my $sth = $db->prepare($query);
	$sth->execute;
	while ( my @row = $sth->fetchrow_array ) {
		$select .= "<option value=\"$row[0]\">$otst $row[1]</option>";
		$select .=
		  go_deep_parent( \$select, " = " . $row[0], $id_lng, $otst . " - " );
	}

	return "" . $select;
}

sub insert_groups_list {
	my ( $text, $id_lng ) = @_;

	my $select;
	$select =
"<select onchange =\"getGroupUsers(this); \" id ='groupselect' name=\"student_group\" >";
	$select .= "<option value = '0'> </option>";
	my $query = <<SQL;
  	select groups.id_grp, groups_lng.name  from groups, groups_lng 
  	where groups.parent = 3 
  	and groups_lng.id_grp = groups.id_grp 
  	and groups_lng.id_lng= '$id_lng' 
  	order by groups_lng.name;
SQL
	my $sth = $db->prepare($query);
	$sth->execute;
	while ( my @row = $sth->fetchrow_array ) {
		$select .= "<option value=\"$row[0]\">$row[1]</option>";

	}
	$select .= "</select>";

	$$text =~ s/\$insert_group_list/$select/ig;

}

##__-----------------------------------------------------------------------

sub save_data {
	my ( $id_boss, $cgi) = @_;
	my @users  = $cgi->param('student_check');
	my @problems = $cgi->param ('problems_check');
	my $date = $cgi->param ('contr_date');
	my $isSpec = $cgi->param ('spec_tema_check');
	my $tema;
	if ($isSpec eq "on") {
		$tema = $cgi->param('spec_theme');
	} else {
		$tema = $cgi->param('main_theme');
	}
	
	foreach my $id_student (@users) {
  		foreach my $id_problem (@problems) {
  			
  			$querytema = <<SQL;
  			insert into ASSIGNED_PROBLEMS 
  			(id_tm, id_boss, id_user, id_prb, contr_date)
  			values ($tema , $id_boss, $id_student, $id_problem, '$date');
SQL
			$sthtema = $db->prepare($querytema);
			$sthtema->execute;
			
  			
  		}
  	} 
  	$db->commit();
	print redirect("/cgi-bin/assigned_problems_list.pl");
	print "\n";
}




