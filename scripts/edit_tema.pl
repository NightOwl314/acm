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

	
	CGI::_reset_globals;
	$incgi = new CGI;

	#а может прислали cookies
	%cookies = parse CGI::Cookie( $ENV{'HTTP_COOKIE'} );

	GetLanguage( \$id_lng, \$cookie1 );

	$id_user = authenticate_process("true");
	next main_cik if ( $id_user . '' eq 'end' );

	if ( $id_user && ( checkRight($id_user) eq "true" ) ) { 

		$action_name = $incgi->param("action");

		$id_tema = $incgi->param("id_tema") + 0;

		$have_errors = "";
		if (   $action_name eq "s_new"
			|| $action_name eq "s_update" )
		{
			$have_errors = save_tema( \$action, $incgi, $id_lng );
			if ( length($have_errors) > 0 ) {
				$action_name = substr( $action_name, 2 );
			}
			else {
				print redirect("/cgi-bin/themeslist.pl");
			}
		}
		if (   !$action_name
			|| $action_name eq "new"
			|| $action_name eq "update" )
		{
			if ($id_tema) {
				$action_name = "update";
			}
			else {
				$action_name = "new";
			}

			$fname = "themes_edit_$id_lng.html";

			#откроем шаблон и считаем все строки
			$string_template = '';
			read_file( "$DirTemplates\\$fname", \$string_template );

			if ( $have_errors . length > 0 ) {
				$action_name = substr( $action_name, 2 );
			}
			insert_error_msg( \$string_template, $have_errors );
			$save_action = "s_" . $action_name;
			$string_template =~ s/\$edit_action/$save_action/ig;

			insert_theme_id( \$string_template, $id_tema );
			insert_parent( \$string_template, $id_lng, $action_name, $id_tema );
			insert_lng_edit( \$string_template, $id_lng, $id_tema,
				$action_name );
			insert_position( \$string_template, $id_tema, $action_name );

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
		print_err("Not Allowed")
	}
}

print "\n";
$db->disconnect;
POSIX: _exit(0);

#--------------------------------------
#Вставка редактирования эдитов
sub insert_lng_edit {
	my ( $text, $id_lng, $id_tema, $action_name ) = @_;

	my $edits_lng = "";
	my @lng_row;

	$query = <<SQL;
  	select id_lng  from langs; 
SQL
	$sthlng = $db->prepare($query);
	$sthlng->execute;

	while ( my @lng_row = $sthlng->fetchrow_array ) {
		my $it_lng = $lng_row[0];

		$edits_lng = $edits_lng
		  . "<tr><td>"
		  . get_language_text( $it_lng, $id_lng ) . "</td>";
		$edits_lng = $edits_lng
		  . "<td><input style=\"width: 500px; \" class='ui-widget' type='text' name='lng_edit_$it_lng'";
		if ($id_tema) {
			$queryvalue = <<SQL;
  	select name  from tema_lng 
  	where id_lng = '$it_lng'
  	and id_tm = $id_tema; 
SQL
			$sthval = $db->prepare($queryvalue);
			$sthval->execute;
			@rowval    = $sthval->fetchrow_array;
			$edits_lng = $edits_lng . " value = '$rowval[0]' ";
		}
		$edits_lng = $edits_lng . "></td>";
		$edits_lng = $edits_lng . "</tr>";
	}

	$$text =~ s/\$insert_lang_edits/$edits_lng/ig;
}

sub insert_error_msg {
	my ( $text, $err_msg ) = @_;

	$$text =~ s/\$error_msg/$err_msg/ig;
}

sub insert_parent {
	my ( $text, $id_lng, $action_name, $id_tema ) = @_;
	my $static_parent;
	my $parent_theme = 0;
	if ($id_tema) {
		$queryvalue = <<SQL;
  	select small_root  from tema 
  	where id_tm = $id_tema; 
SQL
		$sthval = $db->prepare($queryvalue);
		$sthval->execute;
		@rowval       = $sthval->fetchrow_array;
		$parent_theme = $rowval[0] + 0;
	}
	$static_parent = "<select id ='parentselect' name=\"parent_id\" >";
	$static_parent .= "<option value = '0'> </option>";
	$static_parent .=
	  go_deep_parent( \$static_parent, " is null", $id_lng, "", $parent_theme );
	$static_parent .= "</select>";
	$$text =~ s/\$insert_parent/$static_parent/ig;

}

sub go_deep_parent {

	my ( $select, $id_cur, $id_lng, $otst, $id_prnt ) = @_;
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
		$select .= "<option value=\"$row[0]\"";
		$select .=
		  ( $row[0] == $id_prnt ? "selected=\"selected\"" : "" )
		  . ">$otst $row[1]</option>";
		$select .= go_deep_parent( \$select, " = " . $row[0],
			$id_lng, $otst . " - ", $id_prnt );
	}

	return "" . $select;
}

sub insert_theme_id {
	my ( $text, $id_tema ) = @_;
	my $add_text = " - ";
	if ($id_tema) {
		$add_text = $id_tema;
	}
	$$text =~ s/\$insert_tm_id/$add_text/ig;
}

sub insert_position {
	my ( $text, $id_tema, $action_name ) = @_;
	my $add_text = "0";
	if ($id_tema) {
		$queryvalue = <<SQL;
  	select order_pos  from tema 
  	where id_tm = $id_tema 
SQL
		$sthval = $db->prepare($queryvalue);
		$sthval->execute;
		@rowval   = $sthval->fetchrow_array;
		$add_text = $rowval[0];
	}
	$$text =~ s/\$insert_pos/$add_text/ig;
}

sub save_tema {
	my ( $action, $cgi, $id_lng ) = @_;
	my $errorStr = "";

	my @lng_row;

	$query = <<SQL;
  	select id_lng  from langs; 
SQL
	$sthlng = $db->prepare($query);
	$sthlng->execute;

	my $save_query       = "";
	my $id_tm            = $cgi->param("id_tema");
	my $small_root       = $cgi->param("parent_id");
	my $order_pos        = $cgi->param("position");
	my $id_moodle_course = $cgi->param("id_moodle");
	if ( !$small_root ) {
		$small_root = "null";
	}
    my %lang_hash = ();
	while ( my @lng_row = $sthlng->fetchrow_array ) {
		my $it_lng     = $lng_row[0];
		my $field_name = "lng_edit_$it_lng";
		my $lang_text  = $cgi->param($field_name);
		$lang_hash{$it_lng} = $lang_text;
		if ( length($lang_text) == 0 ) {
			$errorStr .= "Поле "
			  . get_language_text( $it_lng, $id_lng )
			  . " должно быть заполнено<br>";
		}
	}
	if ( !( length($errorStr) > 0 ) ) {
		if ( $action_name eq "s_new" ) {
			$id_tema   = get_next_tema_id() + 0;
			$querytema = <<SQL;
	insert into tema (id_tm, small_root, order_pos) 
  	values ($id_tema, $small_root, $order_pos);
SQL
			$sthtema = $db->prepare($querytema);
			$sthtema->execute;
			$db->commit();
			$errorStr .= save_language($action_name,$id_tema, %lang_hash);
			$db->commit();
		}
		elsif ( $action_name eq "s_update" ) {
			$querytema = <<SQL;
	update tema set small_root= $small_root, order_pos = $order_pos
	where id_tm = $id_tema;
SQL
			$sthtema = $db->prepare($querytema);
			$sthtema->execute;
			$errorStr .= save_language($action_name,$id_tema, %lang_hash);		
			$db->commit();
		}
	}

	return $errorStr;
}

sub get_next_tema_id {
	my $querynextid = <<SQL;
	SELECT gen_id(tema_gen, 1) FROM RDB\$DATABASE;
SQL
	my $sthnextid = $db->prepare($querynextid);
	$sthnextid->execute;
	my @generatorRes = $sthnextid->fetchrow_array;
	my $gen_id_tema  = $generatorRes[0];

	return $gen_id_tema;
}

sub get_language_text {
	my ( $it_lng, $id_lng ) = @_;
	$querylgn = <<SQL;
  	select name  from langs_lng 
  	where id_lng1 = '$id_lng'
  	and id_lng2 = '$it_lng'; 
SQL
	$sthlgnm = $db->prepare($querylgn);
	$sthlgnm->execute;
	@rowlgnm = $sthlgnm->fetchrow_array;
	return $rowlgnm[0];
}

sub save_language {
	my ( $action_name, $id_tema, %lang_hash ) = @_;
	my $query_lng = "dafas";
	for my $lang_key (keys %lang_hash){ 
			
				if ($action_name eq "s_new") {
					$query_lng = <<SQL;
					insert into tema_lng (id_tm, id_lng, name)
					values ($id_tema, '$lang_key', '$lang_hash{$lang_key}');
SQL
				} elsif ($action_name eq "s_update" ) {
					$query_lng = <<SQL;
					update tema_lng set  name = '$lang_hash{$lang_key}'
					where id_tm = $id_tema and id_lng = '$lang_key';
SQL
				}
				my $sth_lng = $db->prepare($query_lng);
				$sth_lng->execute;
	}
	
	
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
