#Файл с общими функциями

use IO;
use FCGI;
use DBI;
use CGI qw(:standard);
use MIME::Base64;
use Digest::MD5 qw(md5 md5_hex md5_base64);
use Win32::Mutex;
use Win32::Process;
use CGI::FastTemplate;
use CGI::Cookie;

$fl_cfg_name = 'c:/acm/cnt_sys/config/master.cfg';

#В лог!
sub to_log
{
  my $msg=@_[0];
  my $fl = new IO::File;
  $fl->open(">> $LogFile");
  $msg.="\n";
  my $dt=localtime();
  $msg="$dt [$ThisScript]: ".$msg;
  print $fl $msg;
  $fl->close;
  return 1;
}

#Вытаскивает значение параметра из секции в конфиге
sub get_cfg_param
{
  my ($cfg_file,$sec_name,$par_name)=@_;
  my ($section,$result);

  $$cfg_file =~ m/\n\s*\[$sec_name\](.*?)\[/si;
  $section = "$1";
  $section =~ m/^\s*$par_name\s*=\s*([^\n#]*)/m;
  $result = "$1";
  $result =~ s/\\$//m;
  return $result;
}

#Чтение параметров из конфигов
sub configurate {
  #Debug
  $LastLink='cnt_common.pl';
  $CurLang='en';
  $DefLang='en';
  $LogFile='log_cnt_cgi.txt';
  #/Debug

  to_log($fl_cfg_name);

  #читаем основную конфигурацию системы
  read_config();

  #Читаем весь главный файл конфигурации
  my $master_cfg='';
  read_file($fl_cfg_name, \$master_cfg);
  $master_cfg.='[';

  #Пути
  $Path{Templates} = get_cfg_param(\$master_cfg,'global paths','DirTemplates');
  $Path{CompCfg} = get_cfg_param(\$master_cfg,'global paths','CompilCfg');
  $Path{VirtCGI} = get_cfg_param(\$master_cfg,'global paths','DirVirtCGI');
  $LogFile = get_cfg_param(\$master_cfg,'global paths','LogFile');

  #Параметры БД
  $DBprm{ContTmID} = get_cfg_param(\$master_cfg,'database','ContestsTemaID');

  $fl_cfg_name = get_cfg_param(\$master_cfg,'global paths','ArchprbCfg');
  $master_cfg='';
 

  read_file($fl_cfg_name,\$master_cfg);
  $master_cfg.='[';

  $Path{Source} = get_cfg_param(\$master_cfg,'global paths','DirSrcArhive');
  $Path{ProbTxt} = get_cfg_param(\$master_cfg,'global paths','DirPrbConditions');
  $Path{ProbTxtVirt} = get_cfg_param(\$master_cfg,'global paths','DirVirtualPrb');
  $Path{Temp} = get_cfg_param(\$master_cfg,'global paths','DirTemp');
  $Path{TestServer} = get_cfg_param(\$master_cfg,'global paths','TestServerFile');

  #Параметры БД
  $DBprm{Name} = get_cfg_param(\$master_cfg,'database','dbname');
  $DBprm{User} = get_cfg_param(\$master_cfg,'database','user');
  $DBprm{Password} = get_cfg_param(\$master_cfg,'database','password');

  to_log("dbname=$DBprm{Name}");

  to_log("Master conf file parsed.");

  #Читаем весь файл конфигурации компиляторов
  #to_log("Parsing compilers conf file...");
  my $compile_cfg='';
  read_file($Path{CompCfg},\$compile_cfg);
  #to_log("compile_cfg=\n$compile_cfg\n");
  #s/\[(.+)\].*$(.*$)*(?=\[.+\].*$)//mi
  my $sec;
  my $name;
  my $id=0;
  while ($compile_cfg =~ s/\[(.+?)\].*? \n ((.*?\n)*?) (?=(\[.+\].*\n)|\Z)//mix) {
    #to_log("1=$1\n2=$2\n3=$3\n");
    $name=$1;
    $sec=$2;
    if ($sec =~ s/\s* id \s* = \s* (\d+) \s*$//mix) {
      $id=$1;
    } else {
      to_log("Error parsing compilers conf file: compiler $name has no id");
    }
    
    $CompPrm{$id}{Name}=$name;
    #to_log("CompPrm{$id}{Name}=$name");
    $sec =~ s/\s* FileIn \s* = \s* (.+?) \s*$//mix;
    $CompPrm{$id}{FileIn}=$1;
    #to_log("CompPrm{$id}{FileIn}=$1");
  }
  to_log("Compilers conf file parsed.");
}

sub fcgi_init
{
  $Request = FCGI::Request(\*STDIN, \*STDOUT, \*STDERR, \%ENV);
  to_log "fcgi_init"
}


#Инициализация FastCGI (from Dens)
#sub fcgi_init
#{
#  $in_stream = new IO::Handle;
#  #$out_stream = new IO::Handle;

#  $Request = FCGI::Request($in_stream, \*STDOUT, \*STDERR, \%ENV);
#  #$Request = FCGI::Request(\*STDIN, \*STDOUT, \*STDERR, \%ENV);
#}

#Заменяет в тексте одно выражение на другое
sub tmp_replace
{
  my ($text,$in,$out)=@_;
  $in =~ s/\$/\\\$/gi;
  $in =~ s/\@/\\\@/gi;
  $in =~ s/\%/\\\%/gi;
  $out =~ s/\$/\\\$/gi;
  $out =~ s/\@/\\\@/gi;
  $out =~ s/\%/\\\%/gi;
  $$text =~ s/$in/$out/gi;
}

#Cоединение c БД
sub db_connect
{
  my $dsn;
  $dsn = "dbi:InterBase:dbname=$DBprm{Name};ib_dialect=3";
  to_log("Connecting to DB: $dsn");
  $db = DBI->connect("$dsn", "$DBprm{User}", "$DBprm{Password}",{LongReadLen=>1048576});
  to_log("Connected to DB, $db");
}

#Завершение работы c БД
sub db_disconnect
{
  $db->disconnect();
}

#Выход с выводом сообщения
sub exit_err
{
  my ($msg,$no_header)=@_;
  to_log($msg);

  if (!$no_header) {print header(-charset=>"Windows-1251");}

  my $ErrTpl = new CGI::FastTemplate("$Path{Templates}\\$CurLang");
  $ErrTpl->define(
    main => 'main_admin.tpl',
    error => 'error\error.tpl'
  );
  $ErrTpl->assign(
    MSG => $msg,
    TITLE => 'Error',
    REDIR => ''
  );
  $ErrTpl->parse(MAIN => 'error');
  $ErrTpl->parse(MAIN => 'main');
  $ErrTpl->print();

  $db->rollback();
  next work_cycle;
  #db_disconnect();
  #exit;
}

#-------------------------------------------------------------------------------

sub is_master
{
  my ($user_id)=@_;
  my $qry_str="select sec from author_sec where id_publ=$user_id";
  my $sec=$db->selectrow_array($qry_str)+0;
  to_log("Security level got: UserID=$user_id; Sec=$sec");
  return $sec>=1;
}

sub is_admin
{
  my ($user_id)=@_;
  my $qry_str="select sec from author_sec where id_publ=$user_id";
  my $sec=$db->selectrow_array($qry_str)+0;
  to_log("Security level got: UserID=$user_id; Sec=$sec");
  return $sec==2;
}

#-------------------------------------------------------------------------------

#Конвертрует количество дней (double) в массив [дни,часы,минуты,секунды]
sub parse_hours
{
  my ($hour)=@_;
  my @res=();
  #my ($hour,$minsec)=(int($hour),$hour-int($hour));

#  $res[0]=$date;

#  $res[1]=int($time*24);
#  $time=$time-$res[1]/24;

#  $res[2]=int($time*1440);
#  $time=$time-$res[2]/1440;

#  $res[3]=int($time*86400);

  $res[0]=int($hour/24);
  $hour=$hour-$res[0]*24;
  
  $res[1]=int($hour);
  $hour=$hour-$res[1];

  $res[2]=int($hour*60);
  $hour=$hour-$res[2]/60;

  $res[3]=int($hour*3600);
  return [@res];
}

#Конвертрует строку вида "D.HH:MM:SS" в массив [дни,часы,минуты,секнды]
sub parse_str
{
  my ($str)=@_;
  my @res=();
  if ($str =~ m/((\d+).)?(\d+):(\d+):(\d+)/s) {
    $res[0]=($2!='')?$2:0;
    $res[1]=$3;
    $res[2]=$4;
    $res[3]=$5;
    return [@res];
  } else {
    return 0;
  }
}

#Преобразует массив [D,H,M,S] в double
sub conv_to_hours
{
  my ($arr)=@_;
  my $res=0;

#  $res+=$$arr[0];
#  $res+=$$arr[1]/24;
#  $res+=$$arr[2]/1440;
#  $res+=$$arr[3]/86400;
  $res+=$$arr[0]*24;
  $res+=$$arr[1];
  $res+=$$arr[2]/60;
  $res+=$$arr[3]/3600;

  return $res;
}

#Преобразует массив [D,H,M,S] в строку вида "D.HH:MM:SS"
sub conv_to_str
{
  my ($arr)=@_;
  my ($st,$h,$m,$s)=('','','','');
  if ($$arr[0]!=0) {$st.=$$arr[0].'.';}
  if ($$arr[1]<10) {$h='0'.$$arr[1];} else {$h=$$arr[1];}
  if ($$arr[2]<10) {$m='0'.$$arr[2];} else {$m=$$arr[2];}
  if ($$arr[3]<10) {$s='0'.$$arr[3];} else {$s=$$arr[3];}
  $st.=$h.':'.$m.':'.$s;
  return $st;
}

#-------------------------------------------------------------------------------

#Читает и парсит параметры (посланные методом) POST из потока $in_stream
sub parse_post
{
  to_log("Parsing input stream...");
  my %res;
  my $instr='';
  my $dlm='';
  if ($dlm=<STDIN>) {
    $dlm =~ s/(-+?[a-z0-9]+).*/$1/six;
  } else {
    exit_err('Input stream empty!');
  }
  while (<STDIN>) {$instr.=$_;}

  to_log ("Stream content:\n$instr\nEndstream content.");
  while ($instr =~ s/Content-Disposition:\s+form-data;\s+name="([^"]+?)"(;\s+filename="([^"]*?)"|)\s*?\n(.+?)$dlm//six) {
    my $name=$1;
    my $val=$4;
    my $flname=$3;
    $val =~ s/^(\s*\n)*//six;
    $val =~ s/(\s*\n)*$//six;
    to_log("name=$name\nval=$val\nflname=$flname");
    if ($flname eq '') {
      if ($val =~ m/^\s* ( ([+-]|) \d+ ) \s*$/six) {
        $res{$name}=$1+0;
        to_log("$name=$1 (num)");
      } else {
        $res{$name}=$val;
        to_log("$name=$val (not num)");
      }
    } else {
      $val =~ s/^Content-Type:\s+([^\n\s]*?)\s*\n//six;
      #if ($1 eq 'text/plain') {
        $val =~ s/^(\s*\n)*//six;
        $res{$name}=$val;
        to_log("$name=$val");
      #} else {
        #exit_err("Only text/plain file allowed!");
      #}
    }
  }
  to_log("Input stream parsed.");
  return %res;
}

#-------------------------------------------------------------------------------

sub template_main_public
{

  my ($user)=@_;
  my $qry_str;
  $OutTpl->define(
    link_admin => 'mp_link_admin.tpl',
    link_master => 'mp_link_master.tpl',
    logged => 'mp_logged.tpl',
    not_logged => 'mp_not_logged.tpl'
  );
  
  my $dlm='';
  my $rrl=int(rand(10000))+1;
  $dlm=$inpar?'&':'?';
  $OutTpl->assign(LINK_LOGIN => "$cur_link$dlm"."re_login=$rrl");
  if ($user) {
    my $user_name='';
    $qry_str="select name from authors where id_publ=$user";
    $user_name=$db->selectrow_array($qry_str);
    $OutTpl->assign(
      AUTHOR_ID => $user,
      AUTHOR_NAME => $user_name
    );
    $OutTpl->parse(LOGIN_MSG => 'logged');
  } else {
    $OutTpl->parse(LOGIN_MSG => 'not_logged');
  }
  
  $OutTpl->assign(
    LINK_ADMIN => '',
    LINK_MASTER => ''
  );

  if (is_master($user)) {
    $OutTpl->parse(LINK_MASTER => 'link_master');
  }

  if (is_admin($user)) {
    $OutTpl->parse(LINK_ADMIN => 'link_admin');
  }
}

sub template_main_team
{
  my ($user)=@_;
  my $qry_str;
  $OutTpl->define(
    link_admin => 'mt_link_admin.tpl',
    link_master => 'mt_link_master.tpl',
    logged => 'mt_logged.tpl',
    not_logged => 'mt_not_logged.tpl'
  );

  my $dlm='';
  my $rrl=int(rand(10000))+1;
  $dlm=$inpar?'&':'?';
  $OutTpl->assign(LINK_LOGIN => "$cur_link$dlm"."re_login=$rrl");
  if ($user) {
    my $user_name='';
    $qry_str="select name from authors where id_publ=$user";
    $user_name=$db->selectrow_array($qry_str);
    $OutTpl->assign(
      AUTHOR_ID => $user,
      AUTHOR_NAME => $user_name
    );
    $OutTpl->parse(LOGIN_MSG => 'logged');
  } else {
    $OutTpl->parse(LOGIN_MSG => 'not_logged');
  }

  $OutTpl->assign(
    LINK_ADMIN => '',
    LINK_MASTER => ''
  );

  if (is_master($user)) {
    $OutTpl->parse(LINK_MASTER => 'link_master');
  }
  if (is_admin($user)) {
    $OutTpl->parse(LINK_ADMIN => 'link_admin');
  }
}

#-------------------------------------------------------------------------------

sub is_reg
{
  my ($cont_id,$user_id)=@_;
  my @res;
  my $qry_str="select reg_time from regauth where user_id=$user_id and cont_id=$cont_id";
  my $qry=$db->prepare($qry_str);
  $qry->execute();
  @res=$qry->fetchrow_array();
  $qry->finish();
  return $res[0];
}

#-------------------------------------------------------------------------------

sub is_team
{
  my ($user_id)=@_;
  #my $res;
  #my $qry_str="select reg_time from regauth where user_id=$user_id and cont_id=$cont_id";
  #$res=$db->selectrow_array($qry_str);
  #return $res;
  return 0;
}

#-------------------------------------------------------------------------------

return 1;

