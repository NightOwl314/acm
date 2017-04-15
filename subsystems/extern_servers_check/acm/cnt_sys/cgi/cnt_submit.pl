#!C:\Perl\bin\perl.exe

use IO;
use DBI;
use CGI qw(:standard);
#use CGI::FastTemplate;
use FCGI;

require "cnt_shared.pl";
require "../../scripts/common_func.pl";

#use vars qw(%ENV);

# Main programm ================================================================

$ThisScript='cnt_submit.pl';

#Read configuration
configurate();

#Connect to DB
db_connect();

# Fast CGI -------
fcgi_init();

#Start logging
to_log('-------- cnt_submit.pl started');

work_cycle:
#while($Request->Accept() >= 0) {

#%ENV=%ENV; #REQUEST_METHOD

#($in,$out,$err)=$Request->GetHandles();
$outhtml='';
my %prm=parse_post();

$incgi=new CGI(\%prm);

#Authentication
$user=authenticate_process(0,'1')+0;
if (!$user) { next work_cycle; }

if ($user!=$incgi->param('author_id')) {
  print header(-status=>"401 Unauthorized",
               -WWW_Authenticate=>get_authenticate_header(undef,'true'));
  exit_err("Access denied: user was changed!");
}

submit_prb();
#server_manager(4);

#print header(-charset=>"Windows-1251");
#print $outhtml;
my $cont_id=$incgi->param('contest_id');
#to_log("$Path{VirtCGI}/cnt_team.pl?action=reg&cont_id=$cont_id");
print redirect("$Path{VirtCGI}/cnt_team.pl?action=cont_auth&cont_id=$cont_id");

#} #work cycle

db_disconnect();
      
# Functions ====================================================================
sub submit_prb()
{
  to_log("Solution got.");
  if (!check_data()) {
    exit_err("Illegal submit!");
  }
  to_log("Submition data is valid.");

  my $cont_id=$incgi->param('contest_id');
  my $auth_id=$incgi->param('author_id');
  my $prob_id=$incgi->param('problem_id');
  my $comp_id=$incgi->param('compiler_id');

my $qry_str=<<SQL;
  select stat_id from Add_status($cont_id, $auth_id, $prob_id, $comp_id, 100)
SQL

  my $stat_id=$db->selectrow_array($qry_str) || exit_err($db->errstr);
  to_log("Submition added to DB");

  save_src($comp_id,$stat_id);

  to_log("Solution processed.");
  return 1;
}

sub check_data()
{
  to_log("Checking submition data...");
  my $res=1;
  my $cont_id=$incgi->param('contest_id');
  my $auth_id=$incgi->param('author_id');
  my $prob_id=$incgi->param('problem_id');
  my $comp_id=$incgi->param('compiler_id');
  my $isteam=$incgi->param('is_team');
  my $isvirt=$incgi->param('is_virtual');
  my $source=$incgi->param('source');
  #my $tb_name=$isteam?'Regteam':'Regauth';

  my $qry_str;
  my $cond;
  #Существует ли турнир?
  $qry_str="select COUNT(*) from Contests where cont_id=$cont_id";
  $cond=$db->selectrow_array($qry_str);
  if ($cond==0) {$res=0;}
  to_log("Contest exist?: passed?=$cond");

  #Задача зарегистрирована?
  $qry_str="select count(*) from Cont_Prob where cont_id=$cont_id and prob_id=$prob_id";
  $cond=$db->selectrow_array($qry_str);
  if ($cond==0) {$res=0;}
  to_log("Problem exist?: passed?=$cond");

  #Компилятор зарегистрирован?
  $qry_str="select count(*) from Cont_Comp where cont_id=$cont_id and comp_id=$comp_id";
  $cond=$db->selectrow_array($qry_str);
  if ($cond==0) {$res=0;}
  to_log("Compiler exist?: passed?=$cond");

  #Автор(команда) существует?
  #my $at=$isteam?'T':'A';
  $qry_str="select count(*) from Authors where id_publ=$auth_id";
  $cond=$db->selectrow_array($qry_str);
  if ($cond==0) {$res=0;}
  to_log("User exist?: passed?=$cond");

  #Автор(команда) зарегистрирован?
  $qry_str="select count(*) from Regauth where cont_id=$cont_id and user_id=$auth_id";
  $cond=$db->selectrow_array($qry_str);
  if ($cond==0) {$res=0;}
  to_log("User reget?: passed?=$cond");
  
  #Проверка конфликта индивидульного турнира и команды...
  $cond=$isteam!=is_team($auth_id);
  if ($cond) {
    $res=0;
  }
  to_log ("Ind/team conflict check: passed(must be 0)?=$cond");

  #Турнир запущен?
  $qry_str="select start-current_timestamp from Contests where cont_id=$cont_id";
  $cond=$db->selectrow_array($qry_str);
  if ($cond>0) {$res=0;}
  to_log("Contest started?: passed(must be <0)?=$cond");

  #Запущен ли виртуальный турнир для пользователя?
  if ($isvirt) {
    $qry_str="select cast('1-1-1 0:0:0.0' as timestamp)-reg_time from Regauth where user_id=$auth_id and cont_id=$cont_id";
    $cond=$db->selectrow_array($qry_str);
    if ($cond>0) {$res=0;}
  }
  to_log("Virtual contest started for user?: passed(must be <0)?=$cond");

  #Не закончился ли турнир?
  if ($isvirt) {

$qry_str=<<SQL;
  select current_timestamp-Regauth.reg_time-Contests.duration/24
                  from Contests, Regauth
                  where Contests.cont_id=Regauth.cont_id and
                        Regauth.cont_id=$cont_id and Regauth.user_id=$auth_id
SQL

    $cond=$db->selectrow_array($qry_str);
    if ($cond>0) {$res=0;}
  } else {
    $qry_str="select current_timestamp-stop from Contests where cont_id=$cont_id";
    $cond=$db->selectrow_array($qry_str);
    if ($cond>0) {$res=0;}
  }
  to_log("Contest not ended?: passed(must be <0)?=$cond");

  to_log("Submition data checked: result=$res");
  return $res;
}

sub save_src()
{
  my ($comp_id,$stat_id)=@_;
  to_log("Saving source...");
  my $src=$incgi->param('source');
  if ($src eq '') {
    $src=$incgi->param('sourcefile');
  }
  to_log("source=$src");
  my $filename=$CompPrm{$comp_id}{FileIn};
  my $idhex=sprintf('%X',$stat_id);
  $filename =~ s/\$\(id\)/$idhex/sig;
  $filename=$Path{Temp}."\\".$filename;
  to_log("filename=$filename");

  my $fl = new IO::File;
  $fl->open("> $filename");
  #$$text_file='';
  #while (<$fl>) {$$text_file .= $_;}
  print $fl $src;
  $fl->close;

  to_log("Source saved.");
}
