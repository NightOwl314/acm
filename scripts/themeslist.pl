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

	if ( $id_user && ( checkRight($id_user) eq "true" ) ) {

		$fname = "themeslist_$id_lng.html";

		#откроем шаблон и считаем все строки
		$string_template = '';
		read_file( "$DirTemplates\\$fname", \$string_template );

		insert_themes_list( \$string_template, 0, $id_lng );
		insert_language( \$string_template, $id_lng );
		insert_toolbar_link( \$string_template, $id_lng );

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
		print_err("not allowed");
	}

}

print "\n";
$db->disconnect;
POSIX: _exit(0);

sub insert_language {
	my ( $text, $id_lng ) = @_;

	$$text =~ s/\$insert_lang/$id_lng/ig;

}

sub insert_toolbar_link {
	my ( $text, $id_lng ) = @_;
	$create_link = "/cgi-bin/edit_tema.pl";
	if ( ( $id_lng != $lng_def ) ) {
		$create_link = $create_link . "?id_lng=$id_lng";
	}
	$$text =~ s/\$ins_createlink/$create_link/ig;

}

sub insert_themes_list {
	my ( $text, $id_par, $id_lng ) = @_;
	my $rez_tm       = 0;
	my $small_root   = "is null";
	my $add_info     = "";
	my $sth          = 0;
	my $query        = "";
	my $checkbox_ST  = "<input type = 'checkbox' name = 'themechek' value = '";
	my $checkbox_END = "'>";
	my $cur_pg       = $ENV{"SCRIPT_NAME"};
	if ( $id_par > 0 ) {
		$small_root = " = " . $id_par;
	}
	$query = <<SQL;
  	select tema.id_tm, tema.order_pos, tema_lng.name, tema.prb_cnt  from tema, tema_lng 
  	where tema.small_root $small_root 
  	and tema_lng.id_tm = tema.id_tm 
  	and tema_lng.id_lng= '$id_lng' 
  	order by order_pos;
SQL

	$sth = $db->prepare($query);
	$sth->execute;

	while ( @row = $sth->fetchrow_array ) {
		my $id_tema   = $row[0];                             # id tema
		my $order_pos = $row[1];
		my $count     = ( $row[3] == -1 ) ? "-" : $row[3];

		$add_info .= "<table  class =''>
						<col id='c_one' />
						<col id='c_two' />
						<col id='c_three' />
						<col id='c_four' />
						<col id='c_five' />
						<col id='c_six' />";
		$add_info = $add_info . "<tr>";
		$add_info .=
"<td onclick = 'getTemaContent(this,$id_tema);'><button  class = 'openButton' >+</button></td>";
		$add_info =
		    $add_info . "<td>"
		  . $checkbox_ST
		  . $id_tema
		  . $checkbox_END . "</td>";
		$add_info = $add_info
		  . "<td><a href='/cgi-bin/edit_tema.pl?id_tema=$id_tema'>$id_tema</a></td>";
		$add_info = $add_info . "<td>$order_pos</td>";
		$add_info = $add_info . "<td>$row[2]</td>";
		$add_info = $add_info . "<td>$count</td>";
		$add_info = $add_info . "</tr>";
		$add_info .= "</table>";
	}
	$$text =~ s/\$insertthemeslist/$add_info/ig;

	return $rez_tm;
}

sub checkRight {
	my ($user_id) = @_;
	$query = <<SQL;
  	select groups.id_grp from groups, groups_authors
      where groups.id_grp = groups_authors.id_grp
      and groups_authors.id_publ = $user_id
      and groups.F_CREATE_TM = 1
  	;
SQL

	$sth = $db->prepare($query);
	$sth->execute;

	@row = $sth->fetchrow_array;

	if ( $row[0] ) {
		return "true";
	}
	else {
		return "false";
	}
}
