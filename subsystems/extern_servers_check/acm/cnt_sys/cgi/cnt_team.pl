#!C:\Perl\bin\perl.exe

use IO;
use DBI;
use CGI qw(:standard);
use FCGI;
use CGI::FastTemplate;
use CGI::Cookie;
use CGI::Carp  qw(fatalsToBrowser);

require "cnt_shared.pl";
require "../../scripts/common_func.pl";

# Main programm ================================================================

$ThisScript='cnt_team.pl';

#Read configuration
configurate();

#Connect to DB
db_connect();

# Fast CGI -------
fcgi_init();

#Start logging
to_log('Started.');

work_cycle:
#while($Request->Accept() >= 0) {

$incgi=new CGI($ENV{QUERY_STRING});
my $cur_link='cnt_team.pl?'.$inpar;
%cookies = parse CGI::Cookie($ENV{HTTP_COOKIE});

#Authentication
$user=authenticate_process(0,'1')+0;
if (!$user) { next work_cycle; }

# Проверим кукисы
if (defined($cookies{'cnt_lang'})) {
  $CurLang=$cookies{'cnt_lang'}->value;
}
$last_link='cnt_common.pl';
if (defined($cookies{'last_link'})) {
  $last_link=$cookies{'last_link'}->value;
}
to_log("cnt_team.pl: Cookies checked: CurLang='$CurLang'; last_link='$last_link'.");

#Debug
#$db=$db;
#$inpar='action=reg&cont_id=47';
#$inpar='action=reg&cont_id=20';
#/Debug

$OutTpl = new CGI::FastTemplate("$Path{Templates}\\$CurLang");
$OutTpl->clear_all();
$OutTpl->define(
  main => 'main_team.tpl',
  css => 'css_team.tpl'
);
template_main_team($user);

$Redir='';

$action=$incgi->param('action');

if ($action eq 'reg') {reg_auth();}
elsif ($action eq 'cont_auth') {contest_auth();}
elsif ($action eq 'active_contests') {active_contests();}
else {active_contests();}

$cookie2 = new CGI::Cookie(-name=>'last_link',-value=>$cur_link);
print header(-charset=>"Windows-1251", -cookie=>$cookie2);
$OutTpl->assign(REDIR => $Redir);
$OutTpl->parse(CSS => 'css');
$OutTpl->parse(MAIN => 'main');
$OutTpl->print();

#} #work cycle

db_disconnect();
      
# Functions ====================================================================

#Регистрирует участника на турнире
sub reg_auth {
  my $cont_id=$incgi->param('cont_id');
  my $qry_str;
  if (is_reg($cont_id,$user)) {
    exit_err("User already registred.");
  };
  my $user_is_team=is_team($user);
  $qry_str="select is_team,is_virtual,start-current_timestamp,stop-current_timestamp from contests where cont_id=$cont_id";
  my ($is_team,$is_virt,$is_start,$is_stop)=$db->selectrow_array($qry_str);
  $is_start=$is_start<0?1:0;
  $is_stop=$is_stop>0?0:1;
  if (($is_team+0)!=($user_is_team+0)) {
    exit_err("Individual/team conflict!");
  }
  to_log("is_virt=$is_virt; is_start=$is_start");
  if ($is_virt+0 && !($is_start+0)) {
    exit_err("Registration to virtual contests before it was not started not allowed!");
  }
  if ($is_stop) {
    exit_err("Contest already stoped.");
  }

  $qry_str="insert into Regauth (user_id,cont_id,reg_time) ";
  $qry_str.="values ($user,$cont_id,current_timestamp)";
  to_log("qry=$qry_str");
  $db->do($qry_str) || exit_err($db->errstr);
  $Redir="<meta http-equiv=\"Refresh\" content=\"0; URL=$Path{VirtCGI}/cnt_team.pl\">";
}

#-------------------------------------------------------------------------------

#Выводит список активных турниров
sub active_contests
{
  #Read template
  $OutTpl->define(
    active_contests => 'active_contests_team\active_contests_team.tpl',
    contest => 'active_contests_team\contest.tpl',
    team0 => 'active_contests_team\team0.tpl',
    team1 => 'active_contests_team\team1.tpl',
    virt0 => 'active_contests_team\virt0.tpl',
    virt1 => 'active_contests_team\virt1.tpl',
    stand_link => 'active_contests_team\stand_link.tpl',
    reg_link => 'active_contests_team\reg_link.tpl',
    priv_page_link => 'active_contests_team\priv_page_link.tpl'
  );
  if (-e 'active_contests_team\css.tpl') {$OutTpl->define(css => 'active_contests_team\css.tpl');}
  $OutTpl->assign(TITLE => 'Active contests');

  tmp_act_contests_list();
  $OutTpl->parse(MAIN => active_contests);
}

#Заменяет $act_contests_list на список турниров
sub tmp_act_contests_list 
{
  my $user_is_team=is_team($user);
my $qry_str=<<SQL;
  select cnm.cn_name,cnt.type_id,
         cnt.start,cnt.stop,cnt.duration,
         cnt.freeze_time,cnt.cont_id,cnt.selfreg, 
         (cnt.Start-current_timestamp)*24 lz,
         (cnt.Stop-current_timestamp)*24 gz,
         cnt.is_virtual, cnt.is_team, ct.tp_name,
         ra.reg_time, (current_timestamp-ra.reg_time)*24
  from
     (
       (Contests cnt
       left join Contnames cnm 
           on (cnt.cont_id=cnm.cont_id) and (cnm.lang_id='$CurLang')
       )
    join
       Conttypes_$CurLang ct
    on cnt.type_id=ct.type_id
    )
    left join Regauth ra
    on cnt.cont_id=ra.cont_id and ra.user_id=$user
  where cnt.status='A'
  order by cnt.start desc
SQL
#  to_log($qry_str);
  $OutTpl->assign(CONTESTS => '');
  my $qry=$db->prepare($qry_str);
  $qry->execute;
  my $out='';
  my @cnts=();
  while (@cnts=$qry->fetchrow_array) {
    foreach (@cnts) {
	   $_=~ s/ *$//;
	   if ($_ eq "") {$_='&nbsp'};
    }
    $OutTpl->assign(
      CONT_ID => $cnts[6],
      CONT_TITLE => $cnts[0],
      CONT_TYPE => $cnts[12],
      CONT_START => $cnts[2],
      CONT_STOP => $cnts[3],
      CONT_DUR => conv_to_str(parse_hours($cnts[4])),
      CONT_FREEZE => conv_to_str(parse_hours($cnts[5])),
      CONT_SELFREG => $cnts[7],
      REG_PRIV_LINK => '',
      STAND_LINK => ''
    );
    if ($cnts[10]) {
      $OutTpl->parse(CONT_VIRT => 'virt1');
    } else {
      $OutTpl->parse(CONT_VIRT => 'virt0');
    }
    if ($cnts[8]<0) {
      if ($cnts[10]) {
        if ($cnts[13]+0) {$OutTpl->parse(STAND_LINK => 'stand_link');}
      } else {
        $OutTpl->parse(STAND_LINK => 'stand_link');
      }
    }
    if ($cnts[11]) {
      $OutTpl->parse(CONT_TEAM => 'team1');
    } else {
      $OutTpl->parse(CONT_TEAM => 'team0');
    }

    if (($cnts[11]+0)==($user_is_team+0)) {
      #Reged or not
      if ($cnts[13]+0) {
        #Started?
        if ($cnts[8]<0) {
          $OutTpl->parse(REG_PRIV_LINK => 'priv_page_link');
        }
      } else {
        #Stoped?
        if ($cnts[9]>0) {
          $OutTpl->parse(REG_PRIV_LINK => 'reg_link');
        }
      }
    }
    $OutTpl->parse(CONTESTS => '.contest');
  }
  $qry->finish;
}

#-------------------------------------------------------------------------------

#Выводит персональную страницу автора/команды для работы с турниром
sub contest_auth
{
  my ($qry_str,$qry,$tab_name);
  my $cont_id=$incgi->param('cont_id');
  my $user_is_team=is_team($user);

  $qry_str="select type_id, selfreg, is_team, is_virtual, current_timestamp-start ";
  $qry_str.="from Contests where cont_id=$cont_id";
  $qry=$db->prepare($qry_str) || exit_err($db->errstr);
  $qry->execute() || exit_err($db->errstr);
  my ($type_id,$selfreg,$isteam,$isvirt,$isstart)=$qry->fetchrow_array();
  $qry->finish();

  #Проверяем начался ли турнир
  if ($isstart<0) {exit_err('Contest is not started yet.');}
  
  #Проверяем соответствие автор/команда между турнром и пользователем
  if (($isteam+0)!=($user_is_team+0)) {
    exit_err("Individual/team conflict!");
  }

 #Проверка регистрации пользователя на турнир
  $qry_str=
    "select count(*) from Regauth where cont_id=$cont_id and user_id=$user";
  $isreg=$db->selectrow_array($qry_str)+0;
  if (!$isreg) {exit_err('Your are not registered!');}

 #Вывод личной странички
  #Read template
  $OutTpl->define(
    private_page => 'private_page\private_page.tpl',
    problem_list => 'private_page\problem_list.tpl',
    problem_combo => 'private_page\problem_combo.tpl',
    compiler => 'private_page\compiler.tpl',
    status => 'private_page\status.tpl',
    team_staff => 'private_page\team_staff.tpl',
    team_member => 'private_page\team_member.tpl'
  );
  if (-e 'private_page\css.tpl') {$OutTpl->define(css => 'private_page\css.tpl');}
  $OutTpl->assign(TITLE => 'Private page');

  #Чтение информации из БД
$qry_str=<<SQL;
  select cnm.cn_name, cnt.start,cnt.stop,
         cnt.duration, cnt.freeze_time
  from Contests cnt
       left join Contnames cnm 
		   on (cnt.cont_id=cnm.cont_id) and (cnm.lang_id='$CurLang')
  where cnt.cont_id=$cont_id
SQL
  $qry=$db->prepare($qry_str) || exit_err($db->errstr);
  $qry->execute() || exit_err($db->errstr);
  my @cont=$qry->fetchrow_array();
  $cont[0]=~ s/ *$//;

  my $user_name='';
  $qry_str="select name from Authors where id_publ=$user";
  $user_name=$db->selectrow_array($qry_str) || exit_err($db->errstr);
  $user_name=~ s/ *$//;

  #Замена параметров в шаблоне
  $OutTpl->assign(
    USER_ID => $user,
    CONT_ID => $cont_id,
    CONT_TEAM => $isteam,
    CONT_VIRT => $isvirt,
    CONT_TITLE => $cont[0],
    CONT_START => $cont[1],
    CONT_STOP => $cont[2],
    CONT_DUR => conv_to_str(parse_hours($cont[3])),
    CONT_FREEZE => conv_to_str(parse_hours($cont[4])),
    USER_NAME => $user_name
  );
  tmp_disabled($cont_id,$user,$type_id,$isteam,$isvirt);
  tmp_problems_list($cont_id);
  tmp_compilers_list($cont_id);
  tmp_status($cont_id,$user,$isteam,$isvirt);
  if ($isteam) {
    tmp_team_staff($cont_id,$user);
  } else {
    $OutTpl->assign(TEAM_STAFF => '');
  }
  $OutTpl->parse(MAIN => 'private_page');
}

sub tmp_problems_list
{
  my ($cont_id)=@_;

  #Чтение имен задач из БД
my $qry_str=<<SQL;
  select CP.prob_id,CP.pr_num,PL.name
  from Cont_prob CP JOIN Problems_lng PL ON PL.id_prb=CP.prob_id and PL.id_lng='$CurLang'
  where CP.cont_id=$cont_id
  order by CP.pr_num  
SQL

  my $qry=$db->prepare($qry_str) || exit_err($db->errstr);
  $qry->execute() || exit_err($db->errstr);
  my ($out1,$out2,@prbs)=('','',());
  
  #Формирование списка в виде хтмл-кода
  $OutTpl->assign(PROBLEM_LIST => '', PROBLEM_COMBO => '');
  while (@prbs=$qry->fetchrow_array()) {
    $prbs[2]=~ s/ *$//;
    $OutTpl->assign(
      PROB_ID => $prbs[0],
      PROB_NUM => $prbs[1],
      PROB_NAME => $prbs[2]
    );
    $OutTpl->parse(PROBLEMS_LIST => '.problem_list');
    $OutTpl->parse(PROBLEMS_COMBO => '.problem_combo');
  }
}

sub tmp_compilers_list
{
  my ($cont_id)=@_;
  
  #Чтение имен компиляторов из БД
my $qry_str=<<SQL;
  select Compil.id_cmp,Compil.name
  from Compil,Cont_comp
  where Compil.id_cmp=Cont_comp.comp_id and Cont_comp.cont_id=$cont_id
SQL

  #Формирование списка в виде хтмл-кода
  my $qry=$db->prepare($qry_str) || exit_err($db->errstr);
  $qry->execute() || exit_err($db->errstr);
  my ($out,@cmps)=('',());
  $OutTpl->assign(COMPILERS => '');
  while (@cmps=$qry->fetchrow_array()) {
    $cmps[1]=~ s/ *$//;
    $OutTpl->assign(
      COMP_ID => $cmps[0],
      COMP_NAME => $cmps[1]
    );
    $OutTpl->parse(COMPILERS => '.compiler');
  }
}

sub tmp_status
{
  my ($cont_id,$user_id,$isteam,$isvirt)=@_;

  #Чтение online-статуса из БД
  my $qry_str;
  if ($isvirt) {

$qry_str=<<SQL;
  select S.dt_tm,Cont_prob.pr_num, Problems_lng.name,Compil.name,
         Results_lng.name, S.test_no, S.time_work,
			S.mem_use,(S.dt_tm-Regauth.reg_time)*24
  from (Status S join Cont_Status cs on s.id_stat=cs.id_stat and cs.cont_id=$cont_id),
       Compil,Results_lng,Problems_lng,Cont_prob,Contests,Regauth
  where S.id_prb=Problems_lng.id_prb and
        cs.cont_id=Contests.cont_id and
        S.id_cmp=Compil.id_cmp and
        S.id_rsl=Results_lng.id_rsl and
        S.id_prb=Cont_prob.prob_id and
        cs.cont_id=Cont_prob.cont_id and
        cs.cont_id=Regauth.cont_id and
        S.id_publ=Regauth.user_id and
        Problems_lng.id_lng='$CurLang' and
        Results_lng.id_lng='$CurLang' and
        S.id_publ=$user_id
  order by S.dt_tm desc
  
SQL
  
  } else {
  
$qry_str=<<SQL;
  select Status.dt_tm,Cont_prob.pr_num, Problems_lng.name,Compil.name,
         Results_lng.name, Status.test_no, Status.time_work,
			Status.mem_use,(Status.dt_tm-Contests.start)*24
  from (Status join Cont_Status on Status.id_stat=Cont_Status.id_stat and Cont_Status.cont_id=$cont_id),
       Compil,Results_lng,Problems_lng,Cont_prob,Contests
  where Status.id_prb=Problems_lng.id_prb and
        Cont_Status.cont_id=Contests.cont_id and
        Status.id_cmp=Compil.id_cmp and
        Status.id_rsl=Results_lng.id_rsl and
        Status.id_prb=Cont_prob.prob_id and
        Cont_Status.cont_id=Cont_prob.cont_id and
        Problems_lng.id_lng='$CurLang' and
        Results_lng.id_lng='$CurLang' and
        Status.id_publ=$user_id
  order by Status.dt_tm desc
SQL

  }

  #Формирование списка в виде хтмл-кода
  my $qry=$db->prepare($qry_str) || exit_err($db->errstr);
  $qry->execute() || exit_err($db->errstr);
  my ($out,@stat)=('',());
  $OutTpl->assign(STATUS_TABLE => '');
  while (@stat=$qry->fetchrow_array()) {
    foreach (@stat) {$_=~ s/ *$//;}
    if ($stat[5] eq '') {$stat[5]='n/a';}
    if ($stat[6] eq '') {$stat[6]='n/a';}
    if ($stat[7] eq '') {$stat[7]='n/a';}
    $OutTpl->assign(
      STAT_TIME => $stat[0],
      STAT_ELEPTIME => conv_to_str(parse_hours($stat[8])),
      STAT_PRNUM => $stat[1],
      STAT_PRNAME => $stat[2],
      STAT_COMP => $stat[3],
      STAT_RES => $stat[4],
      STAT_TEST => $stat[5],
      STAT_WORKTIME => $stat[6],
      STAT_USEMEM => $stat[7]
    );
    $OutTpl->parse(STATUS_TABLE => '.status');
  }
}

sub tmp_disabled
{
  my ($cont_id,$user_id,$type_id,$isteam,$isvirt)=@_;

  #Чтение инфы из БД
my $qry_str=<<SQL;
  select Contests.start, Contests.stop, Contests.duration, 
         Regauth.reg_time, current_timestamp,
         (Contests.stop-current_timestamp)*24, (current_timestamp-Regauth.reg_time)*24
  from Contests, Regauth
  where Contests.cont_id=Regauth.cont_id and
        Contests.cont_id=$cont_id and
        Regauth.user_id=$user_id
SQL
to_log($qry_str);
  my $qry=$db->prepare($qry_str) || exit_err($db->errstr);
  $qry->execute() || exit_err($db->errstr);
  my @date=$qry->fetchrow_array();
  my $res='';
  
  if ($isvirt) {
    if ($date[6]<$date[2]) {$res='';} else {$res='disabled';} 
  } else {
    if ($date[5]>0) {$res='';} else {$res='disabled';} 
  }
  $OutTpl->assign(DISABLED => $res);
}

sub tmp_team_staff
{
  my ($cont_id,$team_id)=@_;

  #Чтение имен членов команды из БД
my $qry_str=<<SQL;
  select A.name
  from Authors A JOIN Team_auth TA ON A.id_publ=TA.auth_id
  where TA.team_id=$team_id
SQL
  
  my $qry=$db->prepare($qry_str) || exit_err($db->errstr);
  $qry->execute() || exit_err($db->errstr);
  my ($out,@team)=('',());
  
  #Формирование списка в виде хтмл-кода
  while (@team=$qry->fetchrow_array()) {
    $team[0]=~ s/ *$//;
    $OutTpl->assign(MEMBER_NAME => $team[0]);
    $OutTpl->parse(TEAM_MEMBERS => '.team_member');
  }
  $OutTpl->parse(TEAM_STAFF => 'team_staff');
}
