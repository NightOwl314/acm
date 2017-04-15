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

$ThisScript='cnt_common.pl';

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
my $dlm; $dlm=$inpar?'?':'';
$cur_link="$ThisScript$dlm$inpar";
to_log("Current link: \'$cur_link\'");
$incgi = new CGI($inpar);
%cookies = parse CGI::Cookie($ENV{HTTP_COOKIE});

$user=authenticate_process(1);
if ($user eq 'end') { next work_cycle; }

# Проверим кукисы
if (defined($cookies{'cnt_lang'})) {
  $CurLang=$cookies{'cnt_lang'}->value;
}
else
{
  $CurLang='ru';
}

$last_link='cnt_common.pl';
if (defined($cookies{'last_link'})) {
  $last_link=$cookies{'last_link'}->value;
}
to_log("cnt_common.pl: Cookies checked: CurLang='$CurLang'; last_link='$last_link'.");

$OutTpl = new CGI::FastTemplate("$Path{Templates}\\$CurLang");
$OutTpl->clear_all();
$OutTpl->define(
  main => 'main_public.tpl',
  css => 'css_public.tpl'
);

template_main_public($user);


$Redir='';

my $action=$incgi->param('action');

#debug
#$action = "active_contests";

if ($action eq 'stand') {show_standings();}
elsif ($action eq 'prob_text') {problem_text();}
elsif ($action eq 'active_contests') {active_contests();}
elsif ($action eq 'change_lang') {change_lang();}
elsif ($action eq 'cont_arch') {cont_arch();}
else {main_page();}

$cookie1 = new CGI::Cookie(-name=>'cnt_lang',-value=>$CurLang);
$cookie2 = new CGI::Cookie(-name=>'last_link',-value=>$cur_link);
print header(-charset=>"Windows-1251", -cookie=>[$cookie1,$cookie2]);
$OutTpl->assign(REDIR => $Redir);
$OutTpl->parse(CSS => 'css');
$OutTpl->parse(MAIN => 'main');
$OutTpl->print();

#} #work_cycle

db_disconnect();      

# Functions ====================================================================

#Выводит главную страницу
sub main_page
{
  $OutTpl->define(main_page => 'main_page\main_page.tpl');
  if (-e 'main_page\css.tpl') {$OutTpl->define(css => 'main_page\css.tpl');}
  $OutTpl->assign(TITLE => "Contest system main page");
  $OutTpl->parse(MAIN => 'main_page');
}

#-------------------------------------------------------------------------------

#Выводит турнирную таблицу
sub show_standings
{
  my $cont_id=$incgi->param('cont_id')+0; #$cont_id - идентификатор турнира
  my $master=$incgi->param('master')+0;
  my ($qry_str,$qry);
  
  if ($master && !is_master($user)) {
    exit_err('Access denied!');
  }

  #Загрузка шаблонов
  $OutTpl->define(
    stand => 'standings_acm\standings.tpl',
    head => 'standings_acm\stand_head.tpl',
    row => 'standings_acm\stand_row.tpl',
    prob_num => 'standings_acm\prob_num.tpl',
    prob_res => 'standings_acm\prob_res.tpl'
  );
  if (-e 'standings_acm\css.tpl') {$OutTpl->define(css => 'standings_acm\css.tpl');}
  if ($master){
    $OutTpl->assign(TITLE => 'Master Standings');
  } else {
    $OutTpl->assign(TITLE => 'Standings');
  }
 
  #Чтение информации о турнире из БД
$qry_str=<<SQL;
  select cnm.cn_name, cnt."START",cnt.stop,
         cnt.duration, cnt.freeze_time, cnt.type_id,
         cnt.is_virtual, cnt.is_team, cnt.status
  from Contests cnt
       left join Contnames cnm 
		   on (cnt.cont_id=cnm.cont_id) and (cnm.lang_id='$CurLang')
  where cnt.cont_id=$cont_id
SQL

  $qry=$db->prepare($qry_str) || exit_err($db->errstr);
  $qry->execute() || exit_err($db->errstr);
  my @cont=$qry->fetchrow_array();
  my $dur=$cont[3];
  $qry->finish();
  $cont[0]=~ s/ *$//;
  my $type=$cont[5];
  my $isteam=$cont[7]; #$isteam - командный (true) или индивидуальный (false) турнир
  my $isvirt=$cont[6]; #$isvirt - виртуальный (true) или нет (false) турнир
  my $isarch=$cont[8] eq 'S'?1:0;
  
  if ($isvirt && !$user && !$isarch) {
    exit_err("Authentication requared.");
  }

  #Опряделяем не заморожен ли турнир и время с начала турнира
  
  if ($isvirt) {

    if ($master || $isarch) {

$qry_str=<<SQL;
  select R.reg_time+C.duration/24-current_timestamp,
         case
           when (current_timestamp-R.reg_time)*24<duration then (current_timestamp-R.reg_time)*24
           when (current_timestamp-R.reg_time)*24>=duration then duration
         end
  from Contests C JOIN Regauth R on C.cont_id=R.cont_id
  where C.cont_id=$cont_id and
        R.user_id=$user
SQL

    } else {

$qry_str=<<SQL;
  select R.reg_time+C.duration/24-C.freeze_time/24-current_timestamp,
         case
           when (current_timestamp-R.reg_time)*24<duration then (current_timestamp-R.reg_time)*24
           when (current_timestamp-R.reg_time)*24>=duration then duration
         end
  from Contests C JOIN Regauth R on C.cont_id=R.cont_id
  where C.cont_id=$cont_id and
        R.user_id=$user
SQL

    }

  } else {

    if ($master || $isarch) {

$qry_str=<<SQL;
  select 1,
         case
           when (current_timestamp-"START")*24<duration then (current_timestamp-"START")*24
           when (current_timestamp-"START")*24>=duration then duration
         end
  from Contests
  where cont_id=$cont_id
SQL

    } else {

$qry_str=<<SQL;
  select stop-freeze_time/24-current_timestamp,
         case
           when (current_timestamp-"START")*24<duration then (current_timestamp-"START")*24
           when (current_timestamp-"START")*24>=duration then duration
         end
  from Contests
  where cont_id=$cont_id
SQL
    }
 
  }
  to_log($qry_str);
  $qry=$db->prepare($qry_str) || exit_err($db->errstr);
  $qry->execute || exit_err($db->errstr);
  my @qry_res=$qry->fetchrow_array;
  my ($freezed,$cur_time)=@qry_res;
  $cur_time=conv_to_str(parse_hours($cur_time));
  if (($isvirt && $master) || $isarch) {$cur_time='00:00:00';}
  $freezed=$freezed>0?0:1;
  my $freeze_text;
  if ($freezed && !$master && !$isarch) {
    $freeze_text='<em>(freezed/заморозка)</em>';
  } else {
    $freeze_text='';
  }

  #Заполнение шаблона
  $OutTpl->assign(
    CONTEST_NAME => $cont[0],
    CONTEST_START => $cont[1],
    CONTEST_STOP => $cont[2],
    CONTEST_DURATION => conv_to_str(parse_hours($cont[3])),
    CONTEST_FREEZE => conv_to_str(parse_hours($cont[4])),
    FREEZED => $freeze_text,
    CUR_TIME => $cur_time
  );
  tmp_stand($cont_id,$isteam,$isvirt,$user,$type,$master);
}

#Замена параметров $stand_head и $stand_body в шаблоне
sub tmp_stand
{
  my ($cont_id,$isteam,$isvirt,$user,$type,$master)=@_;
  my ($qry_str,$qry);

  to_log("Tmp_stand called: cont_id=$cont_id, isteam=$isteam, isvirt=$isvirt, user=$user, type=$type, master=$master");

  #Чтение информации о задачах из БД
my $qry_str=<<SQL;
  select Cont_prob.pr_num
  from Cont_prob
  where Cont_prob.cont_id=$cont_id
  order by Cont_prob.pr_num  
SQL

  my $qry=$db->prepare($qry_str) || exit_err($db->errstr);
  $qry->execute() || exit_err($db->errstr);
  my $prbs=$qry->fetchall_arrayref();
  $qry->finish();
  
  #Чтение информации о посланных решениях из БД
  my $fz_text;
  my $usr_text;

  if ($isvirt) {

    if ($master || $isarch) {
      $fz_text='';
      $usr_text='';
    } else {
      $fz_text='-Contests.freeze_time';
$usr_text=<<SQL;
        and
        Status.dt_tm-Regauth.reg_time<=
           (
             select current_timestamp-reg_time
             from Regauth
             where cont_id=$cont_id and user_id=$user
           )
SQL
  }

$qry_str=<<SQL;
  select Status.id_publ, Cont_prob.pr_num, Status.id_rsl,
        (cast(Status.dt_tm as date)-cast(Regauth.reg_time as date))*24*60+
        (cast(Status.dt_tm as time)-cast(Regauth.reg_time as time))/60 penalty
  from
    (
      (
        (status join cont_status on status.id_stat=cont_status.id_stat and cont_status.cont_id=$cont_id)
      join
        cont_prob
      on
        cont_prob.prob_id=status.id_prb and cont_status.cont_id=cont_prob.cont_id
      )
    join
      contests
    on
      contests.cont_id=cont_status.cont_id
    )
  join
    regauth
  on
    regauth.user_id=status.id_publ and regauth.cont_id=$cont_id
  where Status.id_rsl<100 and
        Status.dt_tm-Regauth.reg_time>=0 and
        Status.dt_tm-Regauth.reg_time<(Contests.duration$fz_text)/24
        $usr_text
  order by Status.id_publ,
           Cont_prob.pr_num,
           Status.dt_tm
SQL
    
  } else {

    if ($master || $isarch) {
      $fz_text='';
    } else {
      $fz_text='-Contests.freeze_time/24';
    }

$qry_str=<<SQL;
  select Status.id_publ, Cont_prob.pr_num, Status.id_rsl,
        (cast(Status.dt_tm as date)-cast(Contests."START" as date))*24*60+
        (cast(Status.dt_tm as time)-cast(Contests."START" as time))/60 penalty
  from
    (
      (status join cont_status on status.id_stat=cont_status.id_stat and cont_status.cont_id=$cont_id)
    join
      cont_prob
    on
      cont_prob.prob_id=status.id_prb and cont_status.cont_id=cont_prob.cont_id
    )
  join
    contests
  on
    contests.cont_id=cont_status.cont_id
  where Status.id_rsl<100 and
        Status.dt_tm-Contests."START">0 and
        Contests.stop$fz_text-Status.dt_tm>0

  order by Status.id_publ,
           Cont_prob.pr_num,
           Status.dt_tm
SQL
  
  }
  to_log($qry_str);
  my $qry=$db->prepare($qry_str) || exit_err($db->errstr);
  $qry->execute() || exit_err($db->errstr);
  my $stand=$qry->fetchall_arrayref(); # $stand
  $qry->finish();
  
  #Чтение зарегистрированных авторов/команд из БД
  $auth=get_auths($cont_id);
  
  my $stand_res;
  if ($type==1) {$stand_res=calc_stand($prbs,$auth,$stand);}
  #elsif ($type==2) {$stand_res=calc_stand($prbs,$auth,$stand);}
  #elsif ($type==3) {$stand_res=calc_stand($prbs,$auth,$stand);}
  #elsif ($type==4) {$stand_res=calc_stand($prbs,$auth,$stand);}
  else {
    exit_err("Contest type $type not supported yet.");
  }

  my $nauth=@$auth;
  my $nprb=@$prbs;

  #Формирование заголовка в виде хтмл-кода
  my ($out1,$out2)=('','');
 $OutTpl->assign(PROB_NUM => '');
 $OutTpl->assign(PROB_NUMS => '');
  for (my $i=0; $i<$nprb; $i++) {
    $OutTpl->assign(PROB_NUM => $$prbs[$i][0]);
    $OutTpl->parse(PROB_NUMS => '.prob_num');
  }
  $OutTpl->parse(STAND_HEAD => 'head');

  #Формирование самой таблицы
 $OutTpl->assign(STAND_ROWS => '');
  for (my $i=0; $i<$nauth; $i++) {
    $OutTpl->clear('PROB_RESS');
    for (my $j=0; $j<$nprb; $j++) {

      # DEBUG!!!
      my $result = $$stand_res[$i][$j+1];
      if ($result eq "0") {
        $result = "&nbsp;";
      }
#      $OutTpl->assign(PROB_RES => $$stand_res[$i][$j+1]);
      $OutTpl->assign(PROB_RES => $result);
      $OutTpl->parse(PROB_RESS => '.prob_res');
    }
    my $auth_name;
    if ($master && $isvirt){
      $auth_name="$$stand_res[$i][0] (".conv_to_str(parse_hours($$stand_res[$i][$nprb+4])).")";
    } else {
      $auth_name="$$stand_res[$i][0]";
    }
    $OutTpl->assign(
      RANK => $$stand_res[$i][$nprb+3],
      NAME => $auth_name,
      PROB_SOLV => $$stand_res[$i][$nprb+1],
      PENALTY => int($$stand_res[$i][$nprb+2])
    );
    $OutTpl->parse(STAND_ROWS => '.row');
  }
  $OutTpl->parse(MAIN => 'stand');
  to_log("Tmp_stand ended.");
}

#Читает авторов/команды на турнире из БД
sub get_auths
{
  my ($qry_str,$qry);
  my ($cont_id)=@_;
$qry_str=<<SQL;
  select ra.user_id, a.name,
         case
           when (current_timestamp-ra.reg_time)*24<c.duration then (current_timestamp-ra.reg_time)*24
           when (current_timestamp-ra.reg_time)*24>=c.duration then c.duration
         end
  from (Regauth ra join Contests c on ra.cont_id=c.cont_id and c.cont_id=$cont_id)
       join Authors a on ra.user_id=a.id_publ
  order by ra.user_id
SQL
  
  $qry=$db->prepare($qry_str) || exit_err($db->errstr);
  $qry->execute() || exit_err($db->errstr);
  my $auth=$qry->fetchall_arrayref();
  
#$qry_str=<<SQL;
#  select id_publ, name
#  from Authors
#  order by id_publ
#SQL
  
#  $qry=$db->prepare($qry_str) || exit_err($db->errstr);
#  $qry->execute() || exit_err($db->errstr);
#  my $auth_nm=$qry->fetchall_arrayref();
  
#  foreach (@$auth) {
#    $$_[1]=$$auth_nm[find_el(@$_[0],$auth_nm)][1];
#	  $$_[1] =~ s/ *$//;
#  }
  return [@$auth];  
}

#Расчет турнирной таблицы по регламенту ACM
sub calc_stand
{
  #Входные данные:
  #$prbs - массив с задачами на турнире
  #$auth - массив с участникамив турнира
  #$stand - массив со всеми решения, посланными на турнире
  my ($prbs,$auth,$stand)=@_;
  my @res=();
  my ($i,$isacc,$cur_auth,$cur_prb)=(0,0,0,0);
  my $nauth=@$auth;
  my $nprb=@$prbs;

  to_log("Calculating standings...");
  
  #Инициализация
  for (my $i=0; $i<$nauth; $i++) {
    $res[$i][0]=$$auth[$i][1];
    $res[$i][$nprb+4]=$$auth[$i][2];
    for (my $j=0; $j<$nprb+2; $j++) {
      $res[$i][$j+1]=0;
    }
    $res[$i][$nprb+3]=1;
  }
  if (@$stand==0) {
    to_log("Standings calculated: no submitions found.");
    return [@res];
  }
  $cur_auth=find_el($$stand[0][0],$auth);
  $cur_prb=find_el($$stand[0][1],$prbs);
  
  #Подсчет попыток и пенальти
cycl:  
  for (my $i=0; $i<@$stand; $i++) {
  
	  if ($$stand[$i][0]!=$$auth[$cur_auth][0] or 
	      $$stand[$i][1]!=$$prbs[$cur_prb][0]) 
	  {
	    if ($isacc) {
	       if ($res[$cur_auth][$cur_prb+1] > 0) {
             $res[$cur_auth][$cur_prb+1]='+'.$res[$cur_auth][$cur_prb+1];
          } else {
             $res[$cur_auth][$cur_prb+1]='+';
          }
		  }
		  else {
         $res[$cur_auth][$cur_prb+1]='-'.$res[$cur_auth][$cur_prb+1];
		  }
	  }

    #Изменился ли автор?
	  if ($$stand[$i][0]!=$$auth[$cur_auth][0]) {
	    $cur_auth=find_el($$stand[$i][0],$auth);
		  $cur_prb=0;
		  $isacc=0;
	  }
	 
    #Изменилась задача?
    if ($$stand[$i][1]!=$$prbs[$cur_prb][0]) {
		  $cur_prb=find_el($$stand[$i][1],$prbs);
   	  $isacc=0;
    }

    #А не ACCEPTED ли?
    if ($$stand[$i][2]==0) {
	    if (!$isacc) {
	      #Плюс одна к Solved
		    $res[$cur_auth][$nprb+1]++;
		    #Плюс к Penalty (кол-во минут от начала + кол-во попыток * 20)
		    $res[$cur_auth][$nprb+2]+=$$stand[$i][3]+$res[$cur_auth][$cur_prb+1]*20;
      }
	    $isacc=1;
	  }
	 
    #Если еще не ACCEPTED - плюс одна попытка!
    if (!$isacc) {$res[$cur_auth][$cur_prb+1]++;}
  }
  
  #Ставим +/- последней задаче
  if ($isacc!=0) {
     if ($res[$cur_auth][$cur_prb+1] > 0) {
       $res[$cur_auth][$cur_prb+1]='+'.$res[$cur_auth][$cur_prb+1];
     } else {
       $res[$cur_auth][$cur_prb+1]='+';
     }
	}
  else {
	  $res[$cur_auth][$cur_prb+1]='-'.$res[$cur_auth][$cur_prb+1];
  }
  
  #Создание копии массива
  my $resref=[@res];
  
  #Сортировка турнирной таблицы
  stand_sort($resref,$nprb);

  to_log("Standings calculated.");

  return $resref;
}

#Поиск элемента в первом столбце(2-ый индекс) двумерного массива 
sub find_el
{
  my ($el,$aref)=@_;
  my $i=0;
  while ($$aref[$i][0]!=$el and $i<@$aref) {$i++;}
  return $$aref[$i][0]==$el?$i:-1;
}

#Сортирует турнирную таблицу
sub stand_sort
{
  my ($stand,$nprb)=@_;
  my $size=@$stand;
  qsort($stand,0,$size-1);
  
  #Проставим ранки
  my ($i,$rank)=(1,1);
  for (;$i<$size; $i++) {
    if ($$stand[$i-1][$nprb+2]!=$$stand[$i][$nprb+2] || $$stand[$i-1][$nprb+1]!=$$stand[$i][$nprb+1]) {
      $rank++;
    }
    $$stand[$i][$nprb+3]=$rank;
  }
  return;
} 

#QuickSort. Рекурсивная реализация. 
sub qsort {
  my ($aref,$ibeg,$iend)=@_;
  if ($ibeg>=$iend) {return 0};
  my ($il,$ir)=($ibeg+1,$iend);
  #Выбор центрального элемента и перенос его в начало
  #exch($aref,$imid,$ibeg);
  while (1) {
    for (;order($aref,$il,$ibeg) and $il<$ir; $il++) {;}
    for (;order($aref,$ibeg,$ir) and $il<=$ir; $ir--) {;}
	  if ($il>=$ir) {last;}
    exch($aref,$il,$ir);
	  $il++; $ir--;
  }
  exch($aref,$ir,$ibeg);
  qsort($aref,$ibeg,$ir-1);
  qsort($aref,$ir+1,$iend);
}

#Обмен местами двух элементов массива
sub exch {
  my ($aref,$i1,$i2)=@_;
  my $tmp;
  $tmp=$$aref[$i1];
  $$aref[$i1]=$$aref[$i2];
  $$aref[$i2]=$tmp;
}

#Функция определения порядка элементов
sub order {
  my ($aref,$i1,$i2)=@_;
  my $res=$$aref[$i1][-4]>$$aref[$i2][-4];
  if ($$aref[$i1][-4]==$$aref[$i2][-4]) {
    $res=$$aref[$i1][-3]<$$aref[$i2][-3];
  }  
  return $res;
}

#-------------------------------------------------------------------------------

sub problem_text
{
  my ($prob_id)=$incgi->param('prob_id');
  
  #Read template
  $OutTpl->define(
    problem_text => 'problem_text\problem_text.tpl'
  );
  if (-e 'problem_text\css.tpl') {$OutTpl->define(css => 'problem_text\css.tpl');}
  $OutTpl->assign(TITLE => 'Problem text');

my $qry_str=<<SQL;
  select Problems_lng.name, Problems.time_lim, Problems.mem_lim
  from Problems, Problems_lng
  where Problems.id_prb=Problems_lng.id_prb and
        Problems.id_prb=$prob_id and
        Problems_lng.id_lng='$CurLang'
SQL
  my $qry=$db->prepare($qry_str) || exit_err($db->errstr);
  $qry->execute() || exit_err($db->errstr);
  my @prob=$qry->fetchrow_array();
  
  #Читаем условия задачи
  my $pr_txt='';
  read_file("$Path{ProbTxt}\\$prob_id\\$CurLang\\index.html",\$pr_txt);

  #Заменим относительный путь к рисукам на абсолютный (from Dens)
  my $abs_path = "";
  $abs_path = "$Path{ProbTxtVirt}/$prob_id/$CurLang/";
  $pr_txt =~ s/(<\s*(?:img|image)\s+.*?src\s*=\s*"?)([^\/"][^>]*?)("?[\s\n>])/
              $1$abs_path$2$3/sig;
  $pr_txt =~ s/(<\s*(?:link)\s+.*?href\s*=\s*"?)([^\/"][^>]*?)("?[\s\n>])/
              $1$abs_path$2$3/sig;
  $OutTpl->assign(
    PROB_NAME => $prob[0],
    PROB_TIMELIM => $prob[1],
    PROB_MEMLIM => $prob[2],
    PROB_TEXT => $pr_txt
  );
  $OutTpl->parse(MAIN => 'problem_text');
}

#-------------------------------------------------------------------------------

#Выводит информацию об активных турнирах
sub active_contests
{
  if ($user) {
    $Redir="<meta http-equiv=\"Refresh\" content=\"0; URL=$Path{VirtCGI}/cnt_team.pl\">";
  }

  #Read template
  $OutTpl->define(
    active_contests => 'active_contests\active_contests.tpl',
    contest => 'active_contests\contest.tpl',
    team0 => 'active_contests\team0.tpl',
    team1 => 'active_contests\team1.tpl',
    virt0 => 'active_contests\virt0.tpl',
    virt1 => 'active_contests\virt1.tpl',
    stand_link => 'active_contests\stand_link.tpl'
  );
  if (-e 'active_contests\css.tpl') {$OutTpl->define(css => 'active_contests\css.tpl');}
  $OutTpl->assign(TITLE => 'Active contests');

  tmp_act_contests_list();
  $OutTpl->parse(MAIN => 'active_contests');
}

#Заменяет $act_contests_list на список турниров
sub tmp_act_contests_list
{
my $qry_str=<<SQL;
  select cnm.cn_name,cnt.type_id,
         cnt."START",cnt.stop,cnt.duration,
         cnt.freeze_time,cnt.cont_id,cnt.selfreg,
         (cnt."START"-current_timestamp)*24 lz,
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
  order by cnt."START" desc
SQL

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
      CONT_FREEZE => conv_to_str(parse_hours($cnts[5]))
    );
    if ($cnts[10]) {
      $OutTpl->parse(CONT_VIRT => 'virt1');
      $OutTpl->assign(STAND_LINK => '')
    } else {
      $OutTpl->parse(CONT_VIRT => 'virt0');
      $OutTpl->parse(STAND_LINK => 'stand_link')
    }
    if ($cnts[11]) {
      $OutTpl->parse(CONT_TEAM => 'team1');
    } else {
      $OutTpl->parse(CONT_TEAM => 'team0');
    }
    $OutTpl->parse(CONTESTS => '.contest');
  }
  $qry->finish;
}

#-------------------------------------------------------------------------------

sub change_lang
{
  to_log("Changing language.");
  $CurLang=$incgi->param('lang');
  $cur_link=$last_link;
  $Redir="<meta http-equiv=\"Refresh\" content=\"0; URL=$Path{VirtCGI}/$last_link\">";
}

#-------------------------------------------------------------------------------

sub cont_arch
{
  #Read template
  $OutTpl->define(
    cont_arch => 'cont_archive\cont_archive.tpl',
    contest => 'cont_archive\contest.tpl',
    team0 => 'cont_archive\team0.tpl',
    team1 => 'cont_archive\team1.tpl',
    virt0 => 'cont_archive\virt0.tpl',
    virt1 => 'cont_archive\virt1.tpl',
    stand_link => 'cont_archive\stand_link.tpl'
  );
  if (-e 'cont_arch\css.tpl') {$OutTpl->define(css => 'cont_arch\css.tpl');}
  $OutTpl->assign(TITLE => 'Contest archive');

  tmp_arc_contests_list();
  $OutTpl->parse(MAIN => 'cont_arch');
}

#Заменяет $arc_contests_list на список турниров
sub tmp_arc_contests_list
{
  my $filter=$incgi->param('cont_flt');
  if ($filter eq '') {$filter='%';}
  
my $qry_str=<<SQL;
  select cnm.cn_name,cnt.type_id,
         cnt."START",cnt.stop,cnt.duration,
         cnt.freeze_time,cnt.cont_id,cnt.selfreg,
         (cnt."START"-current_timestamp)*24 lz,
         (cnt.Stop-current_timestamp)*24 gz,
         cnt.is_virtual, cnt.is_team, ct.tp_name
  from (Contests cnt
       left join Contnames cnm
           on (cnt.cont_id=cnm.cont_id) and (cnm.lang_id='$CurLang')
       )
       join
       Conttypes_$CurLang ct
       on cnt.type_id=ct.type_id
  where cnt.status='S' and cnm.cn_name like '$filter'
  order by cnt."START" desc
SQL

  $OutTpl->assign(
    CONTESTS => '',
    FILTER => $filter
  );
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
      CONT_FREEZE => conv_to_str(parse_hours($cnts[5]))
    );
    if ($cnts[10]) {
      $OutTpl->parse(CONT_VIRT => 'virt1');
    } else {
      $OutTpl->parse(CONT_VIRT => 'virt0');
    }
    if ($cnts[11]) {
      $OutTpl->parse(CONT_TEAM => 'team1');
    } else {
      $OutTpl->parse(CONT_TEAM => 'team0');
    }
    $OutTpl->parse(STAND_LINK => 'stand_link');
    $OutTpl->parse(CONTESTS => '.contest');
  }
  $qry->finish;
}



