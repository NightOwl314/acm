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

	if ($id_user) {

		$fname = "assigned_problems_$id_lng.html";

		#откроем шаблон и считаем все строки
		$string_template = '';
		read_file( "$DirTemplates\\$fname", \$string_template );

		insert_themes_list( \$string_template, $id_user, $id_lng );
		
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
	else {

	}
}

print "\n";
$db->disconnect;
POSIX: _exit(0);




sub insert_themes_list {
	my ($text, $id_user ,$id_lng) = @_;
	my $add_text = "";
		$query=<<SQL;
  		select distinct assigned_problems.id_tm, tema_lng.name
  		from assigned_problems, tema_lng 
  		where assigned_problems.id_boss = $id_user
  		and assigned_problems.id_tm = tema_lng.id_tm
  		and tema_lng.id_lng = '$id_lng'
  		order by tema_lng.name;
SQL

 	$sth = $db->prepare($query);
	$sth->execute;
		
	while (@row = $sth->fetchrow_array) {
		$add_text .= "<table class = \"themesTable\">
		<col id =\"c_one\">
   		 <col id = \"c_two\" >";
		$add_text .= "<tr><td align =\"center\" onclick = \"getGroupsForThemes(this, $row[0]);\"><p>+</p></td>";
		$add_text .= "<td><a href =\"arh_problems.pl?id_tm=$row[0]\">$row[1]</a></td></tr>";
		$add_text .= "</table>";
	}
	
	
	$$text =~ s/\$insert_thema_list/$add_text/ig;
	
	
}