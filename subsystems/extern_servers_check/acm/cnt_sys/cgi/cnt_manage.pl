#!C:\Perl\bin\perl.exe

use IO;
use DBI;
use CGI qw(:standard);
use FCGI;
use CGI::FastTemplate;
use CGI::Cookie;

require "cnt_shared.pl";
require "../../scripts/common_func.pl";

# Main programm ================================================================

$ThisScript='cnt_manage.pl';

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

my $inpar=$ENV{QUERY_STRING};
my $cur_link='cnt_manage.pl?'.$inpar;
%cookies = parse CGI::Cookie($ENV{HTTP_COOKIE});
$incgi = new CGI($inpar);

#Authentication
$user=authenticate_process(0,'is_admin($id_publ)')+0;
if (!$user) { next work_cycle; }

# Проверим кукисы
if (defined($cookies{'cnt_lang'})) {
  $CurLang=$cookies{'cnt_lang'}->value;
}
$last_link='cnt_common.pl';
if (defined($cookies{'last_link'})) {
  $last_link=$cookies{'last_link'}->value;
}
to_log("cnt_manage.pl: Cookies checked: CurLang='$CurLang'; last_link='$last_link'.");

$OutTpl = new CGI::FastTemplate("$Path{Templates}\\$CurLang");
$OutTpl->clear_all();
$OutTpl->define(
  main => 'main_admin.tpl',
  css => 'css_admin.tpl'
);
$Redir='';

my $action=$incgi->param('action');

if ($action eq 'change') {change_contest();}
elsif ($action eq 'update') {update_contest();}
elsif ($action eq 'update_problems') {update_problems();}
elsif ($action eq 'add_problems') {add_problems();}
elsif ($action eq 'change_comp') {change_comp();}
elsif ($action eq 'add') {add_contest_dlg();}
elsif ($action eq 'insert') {add_contest_db();}
elsif ($action eq 'serv_act') {server_actions();}
elsif ($action eq 'manage_teams') {manage_teams();}
elsif ($action eq 'update_teams') {update_teams();}
elsif ($action eq 'add_team') {add_team();}
elsif ($action eq 'del_team') {delete_team();}
elsif ($action eq 'manage_auths') {manage_authors();}
elsif ($action eq 'add_auth') {add_author();}
elsif ($action eq 'del_auths') {delete_authors();}
elsif ($action eq 'manage_all') {manage_all();}
elsif ($action eq 'sync_auth') {sync_authors();}
elsif ($action eq 'close_cont') {close_contest();}
else {main_admin();}

$cookie2 = new CGI::Cookie(-name=>'last_link',-value=>$cur_link);
print header(-charset=>"Windows-1251", -cookie=>$cookie2);
$OutTpl->assign(REDIR => $Redir);
$OutTpl->parse(CSS => 'css');
$OutTpl->parse(MAIN => 'main');
$OutTpl->print();

#} #work_cycle

db_disconnect();

# Functions ====================================================================

#Выводит главную станицу админа
sub main_admin
{
  #Read template
  $OutTpl->define(main_admin => 'main_admin\main_admin.tpl');
  if (-e 'main_admin\css.tpl') {$OutTpl->define(css => 'main_admin\css.tpl');}
  $OutTpl->assign(TITLE => "Administrator\'s main page");

  my ($qry_str,$qry);
  $qry_str="select name,current_timestamp from Authors where id_publ=$user";
  $qry=$db->prepare($qry_str) || exit_err($db->errstr);
  $qry->execute || exit_err($db->errstr);
  my @qryres=();
  @qryres=$qry->fetchrow_array;
  $qry->finish();

  #Замена параметров в шаблоне
  $OutTpl->assign(
    ADMIN_NAME => $qryres[0],
    SERVER_TIME => $qryres[1]
  );
  $OutTpl->parse(MAIN => 'main_admin');
}

#-------------------------------------------------------------------------------
#Создает HTML-страницу для редактирования турнира
sub change_contest
{
  my $cont_id=$incgi->param('cont_id');

  #Read template
  $OutTpl->define(
    change_contest => 'change_contest\change_contest.tpl',
    type => 'change_contest\contest_type.tpl',
    reg_problem => 'change_contest\reg_problem.tpl',
    nreg_problem => 'change_contest\nreg_problem.tpl',
    compiler => 'change_contest\compiler.tpl',
    title => 'change_contest\title.tpl'
  );
  if (-e 'change_contest\css.tpl') {$OutTpl->define(css => 'change_contest\css.tpl');}
  $OutTpl->assign(TITLE => "Contest managing");

my $qry_str=<<SQL;
  select cnt.cont_id,cnm.cn_name,cnt.type_id,
         cnt.start,cnt.stop,cnt.duration,
         cnt.freeze_time,cnt.selfreg,
         cnt.is_virtual,cnt.is_team,cnt.theme
  from Contests cnt
       left join Contnames cnm
         on (cnt.cont_id=cnm.cont_id) and (cnm.lang_id='$CurLang')
  where cnt.cont_id=$cont_id
SQL

  my $qry=$db->prepare($qry_str);
  $qry->execute;
  my @cont=$qry->fetchrow_array;

  foreach (@cont) {$_=~ s/ *$//ig;}

  #Замена параметров в шаблоне
  $OutTpl->assign(
    CONTEST_ID => $cont_id,
    CONTEST_NAME => $cont[1],
    CONTEST_START => $cont[3],
    CONTEST_STOP => $cont[4],
    CONTEST_DURATION => conv_to_str(parse_hours($cont[5])),
    CONTEST_FREEZE => conv_to_str(parse_hours($cont[6])),
    CONTEST_SELFREG => $cont[7]?'checked':'',
    CONTEST_ISTEAM => $cont[9]?'checked':'',
    CONTEST_ISVIRTUAL => $cont[8]?'checked':'',
    CONTEST_THEME => $cont[10]
  );

  tmp_contest_names($cont_id);
  tmp_contest_types($cont[2]);
  tmp_reg_problems($cont_id);
  tmp_nreg_problems($cont_id,$cont[10]);
  tmp_compilers($cont_id);

  $OutTpl->parse(MAIN => 'change_contest');
}

#Заменяет $CONTEST_TITLES
sub tmp_contest_names
{
  my ($cont_id)=@_;
my $qry_str=<<SQL;
    select L.id_lng,CN.cn_name
    from Langs L left outer join Contnames CN
    on L.id_lng=CN.lang_id and CN.cont_id=$cont_id
SQL
  my $qry=$db->prepare($qry_str) || exit_err($db->errstr);
  $qry->execute() || exit_err($db->errstr);
  while (@titles=$qry->fetchrow_array) {
    if ($titles[1] eq '') {$titles[1]='&nbsp';}
    $titles[1]=~ s/ *$//;
    $OutTpl->assign(
      LANG => $titles[0],
      CONTEST_TITLE => $titles[1]
    );
    $OutTpl->parse(CONTEST_TITLES => '.title');
  }
}

#Заменяет $contest_type
sub tmp_contest_types
{
  my ($type)=@_;
  my $qry_str="select type_id,tp_name from Conttypes_$CurLang";
  my $qry=$db->prepare($qry_str) || exit_err($db->errstr);
  $qry->execute() || exit_err($db->errstr);
  my $checked;
  while (@types=$qry->fetchrow_array) {
    if ($types[1] eq '') {$types[1]='&nbsp';}
    $OutTpl->assign(
      TYPE_ID => $types[0],
      TYPE_NAME => $types[1],
      TP_CHECK => $type==$types[0]?'checked':''
    );
    $OutTpl->parse(CONTEST_TYPES => '.type');
  }
}

#Заменяет $reg_problems
sub tmp_reg_problems
{
  my ($cont_id)=@_;

my $qry_str=<<SQL;
select Problems.id_prb,Cont_prob.pr_num,Problems_lng.name,
       Problems.time_lim,Problems.mem_lim
from Problems, Cont_prob, Problems_lng
where Cont_prob.prob_id=Problems_lng.id_prb and
      Problems.id_prb=Cont_prob.prob_id and
      Cont_prob.cont_id=$cont_id and
      Problems_lng.id_lng='$CurLang'
order by Cont_prob.pr_num
SQL

  my $qry=$db->prepare($qry_str) || exit_err($db->errstr);
  $qry->execute() || exit_err($db->errstr);

  my @prbs=();
  my $flag=1;
  while (@prbs=$qry->fetchrow_array) {
    $prbs[2]=~ s/ *$//;
    $OutTpl->assign(
      PRB_ID => $prbs[0],
      PRB_NUM => $prbs[1],
      PRB_TITLE => $prbs[2],
      PRB_TLIM => $prbs[3],
      PRB_MLIM => $prbs[4]
    );
    $OutTpl->parse(REG_PROBLEMS => '.reg_problem');
    $flag=0;
  }
  if ($flag) {$OutTpl->assign(REG_PROBLEMS => '');}
}

#Заменяет $nreg_problems
sub tmp_nreg_problems
{
  my ($cont_id,$theme)=@_;

my $qry_str=<<SQL;
select Problems.id_prb,Problems_lng.name,
       Problems.time_lim,Problems.mem_lim
from Problems, Problems_lng
where Problems.id_prb=Problems_lng.id_prb and
      Problems_lng.id_lng='$CurLang' and
      Problems.id_prb not in (
         select Cont_prob.prob_id
         from Cont_prob
         where Cont_prob.cont_id=$cont_id
      ) and
      Problems.id_prb in (
         select id_prb from tm_prb where id_tm=$theme
      )
order by Problems.id_prb
SQL

  my $qry=$db->prepare($qry_str) || exit_err($db->errstr);
  $qry->execute() || exit_err($db->errstr);

  my @prbs=();
  my $flag=1;
  while (@prbs=$qry->fetchrow_array) {
    $prbs[1]=~ s/ *$//;
    $OutTpl->assign(
      PRB_ID => $prbs[0],
      PRB_TITLE => $prbs[1],
      PRB_TLIM => $prbs[2],
      PRB_MLIM => $prbs[3]
    );
    $OutTpl->parse(NREG_PROBLEMS => '.nreg_problem');
    $flag=0;
  }
  if ($flag) {$OutTpl->assign(NREG_PROBLEMS => '');}
}

#Заменяет $compilers
sub tmp_compilers
{
  my ($cont_id)=@_;

my $qry_str=<<SQL;
select Compil.id_cmp, Compil.name, 1 is_reg
from Compil, Cont_comp
where Compil.id_cmp=Cont_comp.comp_id and
      Cont_comp.cont_id=$cont_id

union

select Compil.id_cmp, Compil.name, 0 is_reg
from Compil
where not Compil.id_cmp in
      (
        select Cont_comp.comp_id
        from Cont_comp
        where Cont_comp.cont_id=$cont_id
      )
SQL

  my $qry=$db->prepare($qry_str) || exit_err($db->errstr);
  $qry->execute() || exit_err($db->errstr);

  my @cmps=();
  my $flag=1;
  while (@cmps=$qry->fetchrow_array) {
    $OutTpl->assign(
      CMP_ID => $cmps[0],
      CMP_TITLE => $cmps[1],
      CMP_CHECK => $cmps[2]?'checked':''
    );
    $OutTpl->parse(COMPILERS => '.compiler');
    $flag=0;
  }
  if ($flag) {$OutTpl->assign(COMPILERS => '');}
}

#-------------------------------------------------------------------------------

#Изменяет параметры турнира в БД
sub update_contest
{
  my $cont_id=$incgi->param("cont_id");
  $incgi->delete("cont_id");
  my $start=$incgi->param("start");
  $incgi->delete("start");
  my $stop=$incgi->param("stop");
  $incgi->delete("stop");
  my $dur=$incgi->param("duration");
  $incgi->delete("duration");
  my $freeze=$incgi->param("freeze_time");
  $incgi->delete("freeze_time");
  my $type=$incgi->param("type_id");
  $incgi->delete("type_id");
  my $theme=$incgi->param('theme')+0;
  $incgi->delete('theme');

  my $selfreg=$incgi->param("selfreg");
  $incgi->delete("selfreg");
  if ($selfreg eq "on") { $selfreg=1; }
  else { $selfreg=0; }

  my $isteam=$incgi->param("isteam");
  $incgi->delete("isteam");
  if ($isteam eq "on") { $isteam=1; }
  else { $isteam=0; }

  my $isvirtual=$incgi->param("isvirtual");
  $incgi->delete("isvirtual");
  if ($isvirtual eq "on") { $isvirtual=1; }
  else { $isvirtual=0; }

  $dur=conv_to_hours(parse_str($dur));
  $freeze=conv_to_hours(parse_str($freeze));

  $db->begin_work;

my $qry_str=<<SQL;
  update Contests
    set type_id=$type,
        start='$start',
        stop='$stop',
        duration=$dur,
        freeze_time=$freeze,
        selfreg=$selfreg,
        is_virtual=$isvirtual,
        is_team=$isteam,
        theme=$theme
  where cont_id=$cont_id
SQL

  $db->do($qry_str) || exit_err($db->errstr);

  #Читаем имена параметров в массив
  my @prms=$incgi->param();

  $db->begin_work();
  my $cn_name;
  foreach (@prms) {
    if ($_ =~ m/(cn_name_(\w\w))/ ) {
      $cn_name=$incgi->param($1);
my $qry_str=<<SQL;
        update Contnames
          set cn_name='$cn_name'
        where cont_id=$cont_id and
          lang_id='$2'
SQL
      $db->do($qry_str) || exit_err($db->errstr);
    }
  }

  $db->commit();

  $Redir="<meta http-equiv=\"Refresh\" content=\"0; URL=$Path{VirtCGI}/cnt_manage.pl?action=change&cont_id=$cont_id\">";
}
#-------------------------------------------------------------------------------

#Создает HTML-страницу для просмотра всех турниров
sub manage_all
{
  #Read template
  $OutTpl->define(
    manage_all => 'manage_all\manage_all.tpl',
    contest => 'manage_all\contest.tpl'
  );
  if (-e 'manage_all\css.tpl') {$OutTpl->define(css => 'manage_all\css.tpl');}
  $OutTpl->assign(TITLE => "Contests managing");

  tmp_contests();

  $OutTpl->parse(MAIN => 'manage_all');
}

#Заменяет $CONTESTS на список турниров
sub tmp_contests
{

my $qry_str=<<SQL;
  select cnm.cn_name,cnt.type_id,
         cnt.start,cnt.stop,cnt.duration,
         cnt.freeze_time,cnt.cont_id,cnt.selfreg,
         cnt.is_virtual, cnt.is_team, ct.tp_name
  from (Contests cnt
       left join Contnames cnm
         on (cnt.cont_id=cnm.cont_id) and (cnm.lang_id='$CurLang')
       )
       join
       Conttypes_$CurLang ct
       on cnt.type_id=ct.type_id
  where cnt.status='A'
  order by cnt.start desc
SQL

  $OutTpl->assign(CONTESTS => '');
  my $qry=$db->prepare($qry_str) || exit_err($db->errstr);
  $qry->execute || exit_err($db->errstr);
  my $out="";
  my @cnts=();
  while (@cnts=$qry->fetchrow_array()) {
    foreach (@cnts) {
      $_=~ s/ *$//;
      if ($_ eq "") {$_='&nbsp'};
    }
    $OutTpl->assign(
      CNT_ID => $cnts[6],
      CNT_TITLE => $cnts[0],
      CNT_TYPE => $cnts[10],
      CNT_TEAM => $cnts[9],
      CNT_VIRT => $cnts[8],
      CNT_START => $cnts[2],
      CNT_STOP => $cnts[3],
      CNT_DUR => conv_to_str(parse_hours($cnts[4])),
      CNT_FREEZE => conv_to_str(parse_hours($cnts[5])),
      CNT_SELFREG => $cnts[7]
    );
    $OutTpl->parse(CONTESTS => '.contest');
  }
  $qry->finish;
}

#-------------------------------------------------------------------------------

#Создает HTML-страницу для добавления нового турнира
sub add_contest_dlg
{
  #Read template
  $OutTpl->define(
    add_contest => 'add_contest\add_contest.tpl',
    type => 'add_contest\contest_type.tpl',
    title => 'add_contest\title.tpl'
  );
  if (-e 'add_contest\css.tpl') {$OutTpl->define(css => 'add_contest\css.tpl');}
  $OutTpl->assign(TITLE => "Contests adding");

  tmp_contest_names(-1);
  tmp_contest_types(1);

  $OutTpl->parse(MAIN => 'add_contest');

}

#-------------------------------------------------------------------------------

#Добавляет новый турнир в БД
sub add_contest_db
{
  my $start=$incgi->param("start");
  $incgi->delete("start");
  my $stop=$incgi->param("stop");
  $incgi->delete("stop");
  my $dur=$incgi->param("duration");
  $incgi->delete("duration");
  my $freeze=$incgi->param("freeze_time");
  $incgi->delete("freeze_time");
  my $type=$incgi->param("type_id")+0;
  $incgi->delete("type_id");
  my $theme=$incgi->param('theme')+0;
  $incgi->delete('theme');

  my $selfreg=$incgi->param("selfreg");
  $incgi->delete("selfreg");
  if ($selfreg eq "on") { $selfreg=1; }
  else { $selfreg=0; }

  my $isteam=$incgi->param("isteam");
  $incgi->delete("isteam");
  if ($isteam eq "on") { $isteam=1; }
  else { $isteam=0; }

  my $isvirtual=$incgi->param("isvirtual");
  $incgi->delete("isvirtual");
  if ($isvirtual eq "on") { $isvirtual=1; }
  else { $isvirtual=0; }

  $dur=conv_to_hours(parse_str($dur));
  $freeze=conv_to_hours(parse_str($freeze));

  #to_log("add_contest_db. dur=$dur freeze=$freeze");

  $db->begin_work();

  my $tm_exist=1;
  if ($theme==0) {
    $qry_str="select theme_id from Add_contest_theme($DBprm{ContTmID})";
    to_log($qry_str);
    $theme=$db->selectrow_array($qry_str) || exit_err($db->errstr);
    $tm_exist=0;
  }
  
  $qry_str="select cont_id from Add_contest($type,$isteam,$isvirtual,'$start','$stop',$dur,$freeze,$selfreg,$theme)";
  to_log($qry_str);
  my $cont_id=$db->selectrow_array($qry_str) || exit_err($db->errstr);

  #Читаем имена параметров в массив
  my @prms=$incgi->param();

  $db->begin_work();
  my $cn_name;
  foreach (@prms) {
    if ($_ =~ m/(cn_name_(\w\w))/ ) {
      $cn_name=$incgi->param($1);
      $qry_str="insert into Contnames(cont_id,lang_id,cn_name) ";
      $qry_str.="values ($cont_id,'$2','$cn_name')";
      $db->do($qry_str) || exit_err($db->errstr);

      if (!$tm_exist) {
        $qry_str="insert into Tema_lng(id_tm,id_lng,name) ";
        $qry_str.="values ($theme,'$2','$cn_name')";
        to_log($qry_str);
        $db->do($qry_str) || exit_err($db->errstr);
      }
    }
  }

  $db->commit();

  $Redir="<meta http-equiv=\"Refresh\" content=\"0; URL=$Path{VirtCGI}/cnt_manage.pl?action=change&cont_id=$cont_id\">";
}

#-------------------------------------------------------------------------------

#Изменяет/удаляет зарегистрированные на турнир задачи
sub update_problems
{
  my $cont_id=$incgi->param('cont_id');

  #Удаляем уже прочитанные параметры из строки броузера
  $incgi->delete('action');
  $incgi->delete('cont_id');

  #Читаем имена параметров в массив
  my @prms=$incgi->param();

  #Отключаем автокоммит
  $db->begin_work();

  my $qry_str='';
  $qry_str="select max(pr_num) from Cont_prob where cont_id=$cont_id";
  my $max_num=$db->selectrow_array($qry_str);
  $qry_str="update Cont_prob set pr_num=pr_num+$max_num where cont_id=$cont_id";
  $db->do($qry_str) || exit_err($db->errstr);
  
  foreach (@prms) {
    if ($_ =~ m/num(\d+)/ ) {
      $qry_str="update Cont_prob set pr_num=".$incgi->param($_)." ";
        $qry_str.="where cont_id=$cont_id and prob_id=$1";
       $db->do($qry_str) || exit_err($db->errstr);
    }
  }
  foreach (@prms) {
    if ($_ =~ m/prb(\d+)/ ) {
      $qry_str="delete from Cont_prob where cont_id=$cont_id and prob_id=$1";
      $db->do($qry_str) || exit_err($db->errstr);
    }
  }

  $db->commit();

  $Redir="<meta http-equiv=\"Refresh\" content=\"0; URL=$Path{VirtCGI}/cnt_manage.pl?action=change&cont_id=$cont_id\">";
}

#-------------------------------------------------------------------------------

#Добавляет задачи к турниру
sub add_problems
{
  my $cont_id=$incgi->param('cont_id');

  #Удаляем уже прочитанные параметры из строки броузера
  $incgi->delete('action');
  $incgi->delete('cont_id');

  #Читаем имена параметров в массив
  my @prms=$incgi->param();

my $qry_str=<<SQL;
  select pr_num
  from Cont_prob
  where cont_id=$cont_id
  order by pr_num desc
SQL
  my $count=$db->selectrow_array($qry_str);
  $count++;

  #Отключаем автокоммит
  $db->begin_work();

  foreach (@prms) {
    if ($_ =~ m/prb(\d+)/ ) {
      $qry_str="insert into Cont_prob(cont_id, prob_id, pr_num) ";
      $qry_str.="values ($cont_id, $1, $count)";
        $db->do($qry_str) || exit_err($db->errstr);
      $count++;
    }
  }

  $db->commit();

  $Redir="<meta http-equiv=\"Refresh\" content=\"0; URL=$Path{VirtCGI}/cnt_manage.pl?action=change&cont_id=$cont_id\">";
}

#-------------------------------------------------------------------------------

#Разрешает/запрещает компиляторы на турнире
sub change_comp
{
  my $cont_id=$incgi->param('cont_id');

  #Удаляем уже прочитанные параметры из строки броузера
  $incgi->delete('action');
  $incgi->delete('cont_id');

  #Читаем имена параметров в массив
  my @prms=$incgi->param();

  #Отключаем автокоммит
  $db->begin_work();

  my $qry_str="delete from Cont_comp where cont_id=$cont_id";
  $db->do($qry_str) || exit_err($db->errstr);
  foreach (@prms) {
    if ($_ =~ m/cmp(\d+)/ ) {
     $qry_str="insert into Cont_comp(comp_id,cont_id) values ($1,$cont_id)";
       $db->do($qry_str) || exit_err($db->errstr);
   }
  }

  $db->commit();

  $Redir="<meta http-equiv=\"Refresh\" content=\"0; URL=$Path{VirtCGI}/cnt_manage.pl?action=change&cont_id=$cont_id\">";
}

#-------------------------------------------------------------------------------

sub server_actions
{
  #my $act=$incgi->param('act');
  #if ($act eq 'start') {server_manager(1);}
  #elsif ($act eq 'stop') {server_manager(2);}
  #elsif ($act eq 'restart') {server_manager(3);}
  #elsif ($act eq 'rescan') {server_manager(4);}

  $Redir="<meta http-equiv=\"Refresh\" content=\"0; URL=$Path{VirtCGI}/cnt_manage.pl\">";
}

#-------------------------------------------------------------------------------

sub manage_teams
{
  #Read template
  $OutTpl->define(
    change_teams => 'change_teams\change_teams.tpl',
    team => 'change_teams\team.tpl',
    author => 'change_teams\author.tpl'
    #member => 'member.tpl'
  );
  if (-e 'change_teams\css.tpl') {$OutTpl->define(css => 'change_teams\css.tpl');}
  $OutTpl->assign(TITLE => "Managing teams");

  tmp_teams_list();
  tmp_tm_auth_list();

  #Замена параметров в шаблоне
  #$OutTpl->parse(MAIN =>
  $OutTpl->parse(MAIN => 'change_teams');
}

sub tmp_teams_list
{
  #Отключаем автокоммит
  $db->begin_work();

  #Чтение информации из БД
$qry_str=<<SQL;
  select id_publ, name, login
  from Authors
  where auth_team='T'
  order by name
SQL

  $qry=$db->prepare($qry_str) || exit_err($db->errstr);
  $qry->execute() || exit_err($db->errstr);

  my (@teams,$qry_str2,$qry2,@mems);
  my $out='';
  while (@teams=$qry->fetchrow_array) {
    $teams[1]=~ s/ *$//;
    $teams[2]=~ s/ *$//;
$qry_str2=<<SQL;
    select Authors.name from Authors, Team_auth
    where Authors.id_publ=Team_auth.auth_id and Team_auth.team_id=$teams[0]
    order by Authors.name
SQL
    $qry2=$db->prepare($qry_str2) || exit_err($db->errstr);
    $qry2->execute() || exit_err($db->errstr);
    my $nbsp='&nbsp';
    $out='';
    while (@mems=$qry2->fetchrow_array) {
      $nbsp='';
      $mems[0]=~ s/ *$//;
      $out.="$mems[0]<br>";
    }        
    $out.="$nbsp";
    $OutTpl->assign(
      TM_ID => $teams[0],
      TM_NAME => $teams[1],
      TM_LOGIN => $teams[2],
      TM_MEMBERS => $out
    );
    $OutTpl->parse(TEAMS => '.team');
  }

  $db->commit();
}

sub tmp_tm_auth_list
{
  #Отключаем автокоммит
  $db->begin_work();

  #Чтение информации из БД
$qry_str=<<SQL;
  select id_publ, name, login
  from Authors 
  where auth_team='A'
  order by name
SQL

  $qry=$db->prepare($qry_str) || exit_err($db->errstr);
  $qry->execute() || exit_err($db->errstr);

  my (@auths,$qry_str2,$qry2,@mems);
  my $out='';
  while (@auths=$qry->fetchrow_array()) {
    $auths[1]=~ s/ *$//;
    $auths[2]=~ s/ *$//;
$qry_str2=<<SQL;
    select Authors.name from Authors, Team_auth
    where Authors.id_publ=Team_auth.team_id and Team_auth.auth_id=$auths[0]
    order by Authors.name
SQL
    $qry2=$db->prepare($qry_str2) || exit_err($db->errstr);
    $qry2->execute || exit_err($db->errstr);

    my $nbsp='&nbsp';
    $out='';
    while (@mems=$qry2->fetchrow_array) {
      $nbsp='';
      $mems[0]=~ s/ *$//;
      $out.="$mems[0]<br>";
    }        
    $out.="$nbsp</td></tr>";
    $OutTpl->assign(
      AUTH_ID => $auths[0],
      AUTH_NAME => $auths[1],
      AUTH_LOGIN => $auths[2],
      AUTH_MBR => $out
    );
    to_log("auth_id=$auths[0]");
    $OutTpl->parse(AUTHORS => '.author');
  }

  $db->commit();
}

#-------------------------------------------------------------------------------

sub update_teams
{
  my $team_id=$incgi->param('team_id');

  #Удаляем уже прочитанные параметры из строки броузера
  $incgi->delete('action');
  $incgi->delete('team_id');

  #Читаем имена параметров в массив
  my @prms=$incgi->param();

  #Отключаем автокоммит
  $db->begin_work();

  my $qry_str='';
  foreach (@prms) {
    if ($_ =~ m/auth(\d+)/ ) {
      $qry_str="insert into Team_auth(auth_id,team_id) values ($1,$team_id)";
      $db->do($qry_str) || exit_err($db->errstr);
    }
  }

  $db->commit();

  $Redir="<meta http-equiv=\"Refresh\" content=\"0; URL=$Path{VirtCGI}/cnt_manage.pl?action=manage_teams\">";
}

#-------------------------------------------------------------------------------

sub delete_team
{
  my $team_id=$incgi->param('team_id');
  my $qry_str="delete from Authors where id_publ=$team_id";

  $db->do($qry_str) || exit_err($db->errstr);

  $Redir="<meta http-equiv=\"Refresh\" content=\"0; URL=$Path{VirtCGI}/cnt_manage.pl?action=manage_teams\">";
}

#-------------------------------------------------------------------------------

sub add_team
{
  my $name=$incgi->param('tm_name');
  my $login=$incgi->param('tm_login');
  my $psw=$incgi->param('tm_psw');
  
  my $qry_str="insert into Authors(name,login,pwd,auth_team) values (\'$name\',\'$login\',\'$psw\',\'T\')";

  $db->do($qry_str) || exit_err($db->errstr);

  $Redir="<meta http-equiv=\"Refresh\" content=\"0; URL=$Path{VirtCGI}/cnt_manage.pl?action=manage_teams\">";
}

#-------------------------------------------------------------------------------

sub manage_authors
{
  #Read template
  $OutTpl->define(
    change_auths => 'change_auths\change_auths.tpl',
    author => 'change_auths\author.tpl'
  );
  if (-e 'change_auths\css.tpl') {$OutTpl->define(css => 'change_auths\css.tpl');}
  $OutTpl->assign(TITLE => "Contests managing");

  #Замена параметров в шаблоне
  tmp_auth_list();

  $OutTpl->parse(MAIN => 'change_auths');
}

sub tmp_auth_list
{
  #Отключаем автокоммит
  $db->begin_work();

  #Чтение информации из БД
$qry_str=<<SQL;
  select id_publ, name, login
  from Authors
  where auth_team='A'
  order by name
SQL

  $qry=$db->prepare($qry_str) || exit_err($db->errstr);
  $qry->execute() || exit_err($db->errstr);

  my (@auths,$qry_str2,$qry2,@mems);
  my $out='';
  while (@auths=$qry->fetchrow_array()) {
    $auths[1]=~ s/ *$//;
    $auths[2]=~ s/ *$//;
$qry_str2=<<SQL;
    select Authors.name from Authors, Team_auth
    where Authors.id_publ=Team_auth.team_id and Team_auth.auth_id=$auths[0]
    order by Authors.name
SQL
    $qry2=$db->prepare($qry_str2) || exit_err($db->errstr);
    $qry2->execute || exit_err($db->errstr);

    my $nbsp='&nbsp';
    $out='';
    while (@mems=$qry2->fetchrow_array) {
      $nbsp='';
      $mems[0]=~ s/ *$//;
      $out.="$mems[0]<br>";
    }
    $out.="$nbsp</td></tr>";
    $OutTpl->assign(
      AUTH_ID => $auths[0],
      AUTH_NAME => $auths[1],
      AUTH_LOGIN => $auths[2],
      AUTH_MBR => $out
    );
    $OutTpl->parse(AUTHORS => '.author');
  }

  $db->commit();
}

#-------------------------------------------------------------------------------

sub add_author
{
  my $name=$incgi->param('au_name');
  my $login=$incgi->param('au_login');
  my $psw=$incgi->param('au_psw');

  my $qry_str="insert into Authors(name,login,pwd) values (\'$name\',\'$login\',\'$psw\')";

  $db->do($qry_str) || exit_err($db->errstr);

  $Redir="<meta http-equiv=\"Refresh\" content=\"0; URL=$Path{VirtCGI}/cnt_manage.pl?action=manage_auths\">";
}

#-------------------------------------------------------------------------------

sub delete_authors
{
  #Удаляем уже прочитанные параметры из строки броузера
  $incgi->delete('action');

  #Читаем имена параметров в массив
  my @prms=$incgi->param();

  #Отключаем автокоммит
  $db->begin_work();

  my $qry_str='';
  foreach (@prms) {
    if ($_ =~ m/auth(\d+)/ ) {
      $qry_str="delete from Team_auth where auth_id=$1";
      $db->do($qry_str) || exit_err($db->errstr);
      $qry_str="delete from Authors where id_publ=$1";
      $db->do($qry_str) || exit_err($db->errstr);
    }
  }

  $db->commit();

  $Redir="<meta http-equiv=\"Refresh\" content=\"0; URL=$Path{VirtCGI}/cnt_manage.pl?action=manage_auths\">";
}

#-------------------------------------------------------------------------------

sub sync_authors
{
  #Коннектимся к базе архива задач
  my $dsn;
  $dsn = "dbi:InterBase:dbname=$DBprmA{Name};ib_dialect=3";
  my $ADB = DBI->connect("$dsn", "$DBprmA{User}", "$DBprmA{Password}",{LongReadLen=>1048576});

  my $qry_str="select id_publ,name,login,pwd from Authors order by login";

  my $qry=$ADB->prepare($qry_str) || exit_err($ADB->errstr);

  $qry->execute() || exit_err($ADB->errstr);

  #Отключаем автокоммит
  $db->begin_work();
  
  my @auth;
  while (@auth=$qry->fetchrow_array) {
    $auth[1]=~ s/ *$//; $auth[2]=~ s/ *$//; $auth[3]=~ s/ *$//;
    $qry_str="insert into Authors(auth_id,au_name,au_login,au_psw) ";
    $qry_str.="values ($auth[0],\'$auth[1]\',\'$auth[2]\',\'$auth[3]\')";
    $db->do($qry_str) || exit_err($db->errstr);
  }
  
  $db->commit();
  $ADB->disconnect();
  
  $Redir="<meta http-equiv=\"Refresh\" content=\"0; URL=$Path{VirtCGI}/cnt_manage.pl?action=manage_auths\">";
}

#-------------------------------------------------------------------------------

sub close_contest
{
  my ($cont_id)=$incgi->param('cont_id')+0;
  my $qry_str="select stop-current_timestamp from contests where cont_id=$cont_id";
  my $isstop=$db->selectrow_array($qry_str)+0;
  $isstop=$isstop<0?1:0;
  if (!$isstop) {
    exit_err("Contest can not be closed before it was ended.");
  }
  $qry_str="update contests set status='S' where cont_id=$cont_id";
  $db->do($qry_str) || exit_err($db->errstr);

  $Redir="<meta http-equiv=\"Refresh\" content=\"0; URL=$Path{VirtCGI}/cnt_manage.pl?action=manage_all\">";
}
