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

$ThisScript='cnt_master.pl';

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

$inpar=$ENV{QUERY_STRING};
my $cur_link='cnt_master.pl?'.$inpar;
%cookies = parse CGI::Cookie($ENV{HTTP_COOKIE});
$incgi=new CGI($inpar);

#Authentication
$user=authenticate_process(0,'is_master($id_publ)')+0;
if (!$user) { next work_cycle; }

# Проверим кукисы
if (defined($cookies{'cnt_lang'})) {
  $CurLang=$cookies{'cnt_lang'}->value;
}
$last_link='cnt_common.pl';
if (defined($cookies{'last_link'})) {
  $last_link=$cookies{'last_link'}->value;
}
to_log("cnt_master.pl: Cookies checked: CurLang='$CurLang'; last_link='$last_link'.");

#Debug
#$db=$db;
#$inpar='action=rejudge_sbm&cont_id=50&stat_id=115';
#$inpar='action=rejudge_prb&prob_id=1';
#/Debug

$OutTpl = new CGI::FastTemplate("$Path{Templates}\\$CurLang");
$OutTpl->clear_all();
$OutTpl->define(
  main => 'main_master.tpl',
  css => 'css_admin.tpl'
);
$Redir='';

$action=$incgi->param('action');

if ($action eq 'judge') {judge_contest();}
elsif ($action eq 'view_rep') {view_report();}
elsif ($action eq 'del_stat') {delete_status();}
elsif ($action eq 'change_res') {change_result();}
elsif ($action eq 'rejudge_sbm') {rejudge_subm();}
elsif ($action eq 'rejudge_prb') {rejudge_problem();}
elsif ($action eq 'update_authors') {update_authors();}
elsif ($action eq 'add_authors') {add_authors();}
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

#Выводит список активных турниров
sub active_contests
{
  #Read template
  $OutTpl->define(
    active_contests => 'active_contests_master\active_contests_master.tpl',
    contest => 'active_contests_master\contest.tpl'
  );
  if (-e 'active_contests_master\css.tpl') {$OutTpl->define(css => 'active_contests_master\css.tpl');}
  $OutTpl->assign(TITLE => 'Active contests');

  tmp_act_contests_list();
  $OutTpl->parse(MAIN => active_contests);
}

#Заменяет $act_contests_list на список турниров
sub tmp_act_contests_list
{
my $qry_str=<<SQL;
  select cnm.cn_name,cnt.type_id,
         cnt.start,cnt.stop,cnt.duration,
         cnt.freeze_time,cnt.cont_id,cnt.selfreg,
         (cnt.Start-current_timestamp)*24 lz,
         (cnt.Stop-current_timestamp)*24 gz,
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

  my $qry=$db->prepare($qry_str);
  $qry->execute;
  my $out='';
  my @cnts=();
  $OutTpl->assign(CONTESTS => '');
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
      CONT_VIRT => $cnts[10],
      CONT_TEAM => $cnts[11],
      CONT_SELFREG => $cnts[7]
    );
    $OutTpl->parse(CONTESTS => '.contest');
  }
  $qry->finish;
}

#-------------------------------------------------------------------------------

sub judge_contest 
{
  my $cont_id=$incgi->param('cont_id');
  my $auth_flt=$incgi->param('auth_flt');
  my ($qry_str,$qry);

  #Read template
  $OutTpl->define(
    master_page => 'master_page\master_page.tpl',
    problem_list => 'master_page\problem_list.tpl',
    reg_author => 'master_page\reg_author.tpl',
    all_author => 'master_page\all_author.tpl',
    author_combo => 'master_page\author_combo.tpl',
    status => 'master_page\status.tpl'
  );
  if (-e 'master_page\css.tpl') {$OutTpl->define(css => 'master_page\css.tpl');}
  $OutTpl->assign(TITLE => 'Judge contest');

  #Чтение информации из БД
$qry_str=<<SQL;
  select cnm.cn_name, cnt.start, cnt.stop,
         cnt.duration, cnt.freeze_time, cnt.type_id,
         cnt.is_virtual, cnt.is_team
  from Contests cnt
       left join Contnames cnm 
		   on (cnt.cont_id=cnm.cont_id) and (cnm.lang_id='$CurLang')
  where cnt.cont_id=$cont_id
SQL
  $qry=$db->prepare($qry_str) || exit_err($db->errstr);
  $qry->execute() || exit_err($db->errstr);
  my @cont=$qry->fetchrow_array();
  $cont[0]=~ s/ *$//;

  #Замена параметров в шаблоне
  $OutTpl->assign(
    CONT_ID => $cont_id,
    CONT_NAME => $cont[0],
    CONT_START => $cont[1],
    CONT_STOP => $cont[2],
    CONT_DUR => conv_to_str(parse_hours($cont[3])),
    CONT_FREEZE => conv_to_str(parse_hours($cont[4]))
  );
  tmp_problems_list($cont_id);
  tmp_status($cont_id,$cont[7],$incgi->param('auth_id'));
  tmp_authors($cont_id,$cont[7]);
  tmp_reg_authors($cont_id,$cont[7]);
  tmp_all_authors($cont_id,$cont[7],$auth_flt);
  $OutTpl->parse(MAIN => 'master_page');
}

sub tmp_problems_list
{
  my ($cont_id)=@_;

  #Чтение списка задач из БД
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
  
  #Формирование списка в виде хтмл-кода
  my ($out,@prbs)=('',());
  $OutTpl->assign(PROBLEMS_LIST => '');
  while (@prbs=$qry->fetchrow_array) {
    $prbs[2]=~ s/ *$//;
    $OutTpl->assign(
      PROB_ID => $prbs[0],
      PROB_NAME => $prbs[2],
      PROB_NUM => $prbs[1],
      PROB_TIMELIM => $prbs[3],
      PROB_MEMLIM => $prbs[4]
    );
    $OutTpl->parse(PROBLEMS_LIST => '.problem_list');
  }
}

sub tmp_status
{
  my ($cont_id,$isteam,$auth_id)=@_;

  #Чтение online-статуса из БД
  #my $tbl=$isteam?'Teams':'Authors';
  #my $fld_id=$isteam?'team_id':'auth_id';
  #my $fld_nm=$isteam?'tm_name':'au_name';
  my $condition='';
  if ($auth_id) {
    $condition="where s.id_publ=$auth_id";
  }

my $qry_str=<<SQL;
  select s.id_stat, s.dt_tm, cp.pr_num, pl.name,
         cm.name, rl.name, s.test_no, s.time_work,
		    s.mem_use, (s.dt_tm-cn.start)*24, a.name
  from ((((((Status s join cont_status cs on s.id_stat=cs.id_stat and cs.cont_id=$cont_id)
       join compil cm on s.id_cmp=cm.id_cmp)
       join cont_prob cp on s.id_prb=cp.prob_id and cp.cont_id=$cont_id)
       join authors a on a.id_publ=s.id_publ)
       join results_lng rl on rl.id_rsl=s.id_rsl and rl.id_lng='$CurLang')
       join problems_lng pl on pl.id_prb=s.id_prb and pl.id_lng='$CurLang')
       join contests cn on cn.cont_id=cs.cont_id
  $condition
  order by s.dt_tm desc
SQL
 
  #Формирование списка в виде хтмл-кода
  my $qry=$db->prepare($qry_str) || exit_err($db->errstr);
  $qry->execute() || exit_err($db->errstr);
  my ($out,@stat)=('',());
  my $eleps_time;
  $OutTpl->assign(STATUS_TABLE => '');
  while (@stat=$qry->fetchrow_array()) {
    foreach (@stat) {$_=~ s/ *$//;}
	  if ($stat[6] eq '') {$stat[6]='n/a';}
	  if ($stat[7] eq '') {$stat[7]='n/a';}
	  if ($stat[8] eq '') {$stat[8]='n/a';}
    $OutTpl->assign(
      CONT_ID => $cont_id,
      STAT_ID => $stat[0],
      STAT_TIME => $stat[1],
      STAT_ELEPTIME => conv_to_str(parse_hours($stat[9])),
      STAT_AUTH => $stat[10],
      STAT_PROBNUM => $stat[2],
      STAT_PROBNAME => $stat[3],
      STAT_COMP => $stat[4],
      STAT_RES => $stat[5],
      STAT_TEST => $stat[6],
      STAT_WORKTIME => $stat[7],
      STAT_USEMEM => $stat[8]
    );
    $OutTpl->parse(STATUS_TABLE => '.status');
  }
}

sub tmp_authors
{
  my ($cont_id)=@_;
  my $qry_str='';

  #Чтение имен авторов/команды из БД
$qry_str=<<SQL;
  select Authors.id_publ, Authors.name
  from Authors, Regauth
  where Authors.id_publ=Regauth.user_id and
        Regauth.cont_id=$cont_id
  order by Authors.name
SQL

  my $qry=$db->prepare($qry_str) || exit_err($db->errstr);
  $qry->execute() || exit_err($db->errstr);
  my ($out,@auth)=('',());
  
  #Формирование списка в виде хтмл-кода
  $OutTpl->assign(AUTHORS_COMBO => '');
  while (@auth=$qry->fetchrow_array()) {
  	$auth[1] =~ s/ *$//;
  	$OutTpl->assign(
      AUTH_ID_C => $auth[0],
      AUTH_NAME_C => $auth[1]
    );
    $OutTpl->parse(AUTHORS_COMBO => '.author_combo');
  }
}

#Заменяет $reg_authors
sub tmp_reg_authors
{
  my ($cont_id)=@_;
  my $qry_str='';
  
  #Чтение инфы об авторах/командах из БД
$qry_str=<<SQL;
  select Authors.id_publ, Authors.name, Authors.login, Regauth.reg_time
  from Authors, Regauth
  where Authors.id_publ=Regauth.user_id and
        Regauth.cont_id=$cont_id
  order by Authors.name
SQL

  my $qry=$db->prepare($qry_str) || exit_err($db->errstr);
  $qry->execute() || exit_err($db->errstr);
  
  my ($out,@auths)=('',());
  $OutTpl->assign(REG_AUTHORS => '');
  while (@auths=$qry->fetchrow_array) {
    $auths[1]=~ s/ *$//;
    $auths[2]=~ s/ *$//;
    if ($auth[3]=='') {$auths[3]='&nbsp';}
    $OutTpl->assign(
      AUTH_ID_R => $auths[0],
      AUTH_NAME_R => $auths[1],
      AUTH_LOGIN_R => $auths[2],
      AUTH_REGTIME_R => $auths[3]
    );
    $OutTpl->parse(REG_AUTHORS => '.reg_author');
  }
}

#Заменяет $all_authors
sub tmp_all_authors
{
  my ($cont_id,$isteam,$filter)=@_;
  my $qry_str='';

  $OutTpl->assign(ALL_AUTHORS => '');
  $OutTpl->assign(FILTER => '');
  if ($filter eq '') {
    return;
  }
  $OutTpl->assign(FILTER => $filter);

  #Чтение инфы об авторах/командах из БД
$qry_str=<<SQL;
  select Authors.id_publ, Authors.name, Authors.login
  from Authors
  where Authors.id_publ not in (
           select Regauth.user_id
           from Regauth
           where Regauth.cont_id=$cont_id
        ) and Authors.name like '$filter'
  order by Authors.name
SQL

  my $qry=$db->prepare($qry_str) || exit_err($db->errstr);
  $qry->execute() || exit_err($db->errstr);
  
  my ($out,@auths)=('',());
  while (@auths=$qry->fetchrow_array) {
    $auths[1]=~ s/ *$//;
    $auths[2]=~ s/ *$//;
    $OutTpl->assign(
      AUTH_ID_A => $auths[0],
      AUTH_NAME_A => $auths[1],
      AUTH_LOGIN_A => $auths[2]
    );
    $OutTpl->parse(ALL_AUTHORS => '.all_author');
  }
}

#-------------------------------------------------------------------------------

#Выводит репорт по сабмишансу
sub view_report
{
  to_log("Make report...");
  my $stat_id=$incgi->param('stat_id');
  my $qry_str;

  #Read template
  my $tmp_flname="submit_report_$CurLang.html";
  read_file("$Path{Templates}\\$tmp_flname",\$outhtml);
  $OutTpl->define(
    submit_report => 'submit_report\submit_report.tpl',
    result => 'submit_report\result.tpl',
    result_cur => 'submit_report\result_cur.tpl',
    report => 'submit_report\report.tpl'
  );
  if (-e 'submit_report\css.tpl') {$OutTpl->define(css => 'submit_report\css.tpl');}
  $OutTpl->assign(TITLE => 'Submition report');
	
  #Чтение информации из БД
	$qry_str="select cont_id from Cont_status where id_stat=$stat_id";
	my $cont_id=$db->selectrow_array($qry_str);

$qry_str=<<SQL;
  select s.dt_tm, cp.pr_num, pl.name,
         cm.name, rl.name, s.test_no, s.time_work,
		     s.mem_use, a.name, s.id_rsl
  from ((((((Status s join cont_status cs on s.id_stat=cs.id_stat and cs.cont_id=$cont_id and s.id_stat=$stat_id)
       join compil cm on s.id_cmp=cm.id_cmp)
       join cont_prob cp on s.id_prb=cp.prob_id and cp.cont_id=$cont_id)
       join authors a on a.id_publ=s.id_publ)
       join results_lng rl on rl.id_rsl=s.id_rsl and rl.id_lng='$CurLang')
       join problems_lng pl on pl.id_prb=s.id_prb and pl.id_lng='$CurLang')
SQL
  $qry=$db->prepare($qry_str) || exit_err($db->errstr);
  $qry->execute() || exit_err($db->errstr);
  my @stat=$qry->fetchrow_array();
  $cont[0]=~ s/ *$//;
	my $idhex=sprintf('%X',$stat_id);
	my $serv_rep='';
	
	#Читаем репорт сервера
  read_file("$Path{Source}\\$idhex.otch",\$serv_rep);
  #to_log("$serv_rep");
  
	#Читаем исходник
	my $src='';
  read_file("$Path{Source}\\$idhex.src",\$src);
	$src =~ s/&/&amp/gi;
	$src =~ s/</&lt/gi;
	$src =~ s/>/&gt/gi;
	
  #Замена параметров в шаблоне
  if ($stat[5]=='') {$stat[5]='n/a';}
  if ($stat[6]=='') {$stat[6]='n/a';}
  if ($stat[7]=='') {$stat[7]='n/a';}
  $OutTpl->assign(
    STAT_ID => $stat_id,
    STAT_ID_HEX => '0x'.$idhex,
    STAT_TIME => $stat[0],
    AUTHOR => $stat[8],
    TIME => $stat[0],
    PROB_NUM => $stat[1],
    PROB_NAME => $stat[2],
    COMPILER => $stat[3],
    WORK_TIME => $stat[6],
    MEM_USE => $stat[7],
    TEST => $stat[5],
    REPORT => $rep,
    SOURCE => $src,
    SERVER_REPORT => $serv_rep
  );
	tmp_results_list($stat[9]);
	tmp_reports($stat_id);
	$OutTpl->parse(MAIN => 'submit_report');
}

sub tmp_results_list {
  my ($cur_res)=@_;
my $qry_str=<<SQL;
	  select id_rsl, name
		from Results_lng
		where id_lng='$CurLang' and id_rsl<100
SQL
  my $qry=$db->prepare($qry_str) || exit_err($db->errstr);
  $qry->execute() || exit_err($db->errstr);
	my @res;
	my $out='';
	while (@res=$qry->fetchrow_array) {
		$OutTpl->assign(
      RES_ID => $res[0],
      RES_NAME => $res[1]
    );
		if ($res[0]==$cur_res) {
      $OutTpl->parse(RESULTS => '.result_cur');
    } else {
      $OutTpl->parse(RESULTS => '.result');
    }
	}
}

sub tmp_reports
{
  my ($stat_id)=@_;

my $qry_str=<<SQL;
  select r.id_rpt,rl.name,sr.text
  from Status_reports sr join
       (Reports r join Reports_lng rl on r.id_rpt=rl.id_rpt and rl.id_lng='$CurLang')
       on r.id_rpt=sr.id_rpt and sr.id_stat=$stat_id
SQL

  my $qry=$db->prepare($qry_str);
  $qry->execute();
  my ($rep_id,$rep_name,$rep_text);
  $OutTpl->assign(REPORTS => '');
  while (($rep_id,$rep_name,$rep_text)=$qry->fetchrow_array) {
    $OutTpl->assign(
      REP_ID => $rep_id,
      REP_HEADER => $rep_name,
      REP_TEXT => $rep_text
    );
    $OutTpl->parse(REPORTS => '.report');
  }
  $qry->finish();
}

#-------------------------------------------------------------------------------

#Удаляет присланное решение из БД
sub delete_status {
  my $stat_id=$incgi->param('stat_id');
	my $qry_str="select cont_id from Status where id_stat=$stat_id";
	my $cont_id=$db->selectrow_array($qry_str);# || exit_err($db->errstr);
  $qry_str="delete from Status where id_stat=$stat_id";
	$db->do($qry_str) || exit_err($db->errstr);

  $Redir="<meta http-equiv=\"Refresh\" content=\"0; URL=$Path{VirtCGI}/cnt_master.pl?action=judge&cont_id=$cont_id\">";
}

#-------------------------------------------------------------------------------

#Устанавливает результат вручную
sub change_result {
  my $stat_id=$incgi->param('stat_id');
  my $res_id=$incgi->param('res_id');
	my $qry_str="select cont_id from Status where id_stat=$stat_id";
	my $cont_id=$db->selectrow_array($qry_str);# || exit_err($db->errstr);
	$qry_str="update Status set id_rsl=$res_id where id_stat=$stat_id";
	$db->do($qry_str) || exit_err($db->errstr);

  $Redir="<meta http-equiv=\"Refresh\" content=\"0; URL=$Path{VirtCGI}/cnt_master.pl?action=judge&cont_id=$cont_id\">";
}

#-------------------------------------------------------------------------------

#Перепосылает решение на проверку
sub rejudge_subm {
  my $stat_id=$incgi->param('stat_id');
  my $cont_id=$incgi->param('cont_id');
  
  #Читаем весь файл конфигурации компиляторов (compil.cfg)
  my $compile_cfg='';
  read_file($Path{CompCfg},\$compile_cfg);
  
	my $qry_str="select id_cmp from Status where id_stat=$stat_id";
	my $comp_id=$db->selectrow_array($qry_str);# || exit_err($db->errstr);
  if (!comp_id) {exit_err('Record in Status not found!');} 

  #Достаем исходники из архива
  copy_src(\$compile_cfg,$stat_id,$comp_id);  
	
	#Ставим результат в Waiting...
$qry_str=<<SQL;
  update Status set id_rsl=100,
                    test_no=NULL,
                    time_work=NULL,
                    mem_use=NULL                    
  where id_stat=$stat_id";
SQL
	$db->do($qry_str) || exit_err($db->errstr);

  $Redir="<meta http-equiv=\"Refresh\" content=\"0; URL=$Path{VirtCGI}/cnt_master.pl?action=judge&cont_id=$cont_id\">";
}

#Перепосылает все решения конкретной задачи на проверку
sub rejudge_problem {
	my $cont_id=$incgi->param('cont_id');
  my $prob_id=$incgi->param('prob_id');

  #Читаем весь файл конфигурации компиляторов (compil.cfg)
  my $compile_cfg='';
  read_file($Path{CompCfg},\$compile_cfg);

my $qry_str=<<SQL;
  select s.id_stat, s.id_cmp
  from Status s join Cont_status cs
    on s.id_stat=cs.id_stat and cs.cont_id=$cont_id and s.id_prb=$prob_id
SQL

  my $qry=$db->prepare($qry_str) || exit_err($db->errstr);
  $qry->execute() || exit_err($db->errstr);

  #Достаем исходники из архива
  my @stat;
  while (@stat=$qry->fetchrow_array()) {
    copy_src(\$compile_cfg,$stat[0],$stat[1]);  
  }
  
	#Ставим результаты в Waiting...
$qry_str=<<SQL;
  update Status set id_rsl=100,
                    test_no=NULL,
                    time_work=NULL,
                    mem_use=NULL
	where id_prb=$prob_id and id_stat in (select id_stat from cont_status cs where cs.cont_id=$cont_id)
SQL
	$db->do($qry_str) || exit_err($db->errstr);

  $Redir="<meta http-equiv=\"Refresh\" content=\"0; URL=$Path{VirtCGI}/cnt_master.pl?action=judge&cont_id=$cont_id\">";
}

#Копирует исходник из архива во временный директорий (DirTemp)
sub copy_src 
{
  my ($cmp_cfg,$stat_id,$comp_id)=@_;
	my $idhex=sprintf('%x',$stat_id);
  $$cmp_cfg =~ 
    m/\n\s*\[.*?\].*?\n\s*id\s*=\s*$comp_id.*?\n\s*FileIn\s*=\s*([^\n#]*)\[?/s;
  my $src_name=$1;
  $src_name =~ s/\$\(id\)/$idhex/;
  my $src='';
  read_file("$Path{Source}\\$idhex.src",\$src);
  
  to_log("copy_src. $stat_id $comp_id $idhex $src_name \n$src");

  my $fl = new IO::File;
  $fl->open("> $Path{Temp}\\$src_name");
  print $fl $src;
  $fl->close;
}

#-------------------------------------------------------------------------------

#Удаляет авторов с турнира
sub update_authors 
{
  my $cont_id=$incgi->param('cont_id');
  my $qry_str='';
  
  #Удаляем уже прочитанные параметры из строки броузера
  $incgi->delete('action');
  $incgi->delete('cont_id');
  
  #Читаем имена параметров в массив
  my @prms=$incgi->param();
  
  #Отключаем автокоммит
  $db->begin_work(); 
  
  foreach (@prms) {
    if ($_ =~ m/auth(\d+)/ ) {
      $qry_str="delete from Regauth where cont_id=$cont_id and user_id=$1";
      $db->do($qry_str) || exit_err($db->errstr);
	 }
  }

  $db->commit();
  
  $Redir="<meta http-equiv=\"Refresh\" content=\"0; URL=$Path{VirtCGI}/cnt_master.pl?action=judge&cont_id=$cont_id\">";
}

#-------------------------------------------------------------------------------

#Регистрирует авторов на турнир
sub add_authors 
{
  my $cont_id=$incgi->param('cont_id');
  my $qry_str='';
  
  #Удаляем уже прочитанные параметры из строки броузера
  $incgi->delete('action');
  $incgi->delete('cont_id');
  
  #Читаем имена параметров в массив
  my @prms=$incgi->param();

  #Отключаем автокоммит
  $db->begin_work(); 

  foreach (@prms) {
    if ($_ =~ m/auth(\d+)/ ) {
      $qry_str="insert into Regauth(cont_id, user_id, reg_time) ";
      $qry_str.="values ($cont_id, $1, NULL)";
      $db->do($qry_str) || exit_err($db->errstr);
		  $count++;
    }
  }
  
  $db->commit(); 

  $Redir="<meta http-equiv=\"Refresh\" content=\"0; URL=$Path{VirtCGI}/cnt_master.pl?action=judge&cont_id=$cont_id\">";
}

#-------------------------------------------------------------------------------
