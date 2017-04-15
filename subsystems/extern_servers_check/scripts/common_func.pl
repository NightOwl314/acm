use FCGI;
use IO;
use DBI;
use CGI  qw(:standard);
use CGI::Cookie;
use MIME::Base64; 
use Digest::MD5 qw(md5 md5_hex md5_base64);
use Win32;
use Win32::Process;

use Win32::NetAdmin;
use Win32::OLE;
use Win32::OLE::Variant;

$fl_cfg = 'c:/acm/config/master.cfg';

use vars qw(%ENV $request $db $DirTempSrc %Compilers
            $DirTemplates $master_config $DirSrcArh $incgi $DirProblems
            $DirPrbCond $DirVirtualPrb $DirTemp $DirStdCheckers $ArchivatorExe %ProblemPaths %cookies
            $start_request_time $exit_main_cik );

#для отладки и тестирования
sub to_log
{
  my $msg=@_[0];
  
  my $fl = new IO::File;
  $fl->open(">> log.txt");
  my $dt=localtime();
  #$this_script=~m/^.*(\/|\\)(.*?)$/;
  #$scr=$2;
  my $msg="$dt: $msg\n";
  print $fl $msg;
  $fl->close;
  return 1;
}


#читает файл конфигурации и определяет каталог с шаблонами
sub read_config
{
#  to_log ("read_config started");


  #начальная инициализация
  $start_request_time=Win32::GetTickCount();
  $exit_main_cik=0;

  
  #определим путь к файлу конфигурации
#  to_log("config file name: $fl_cfg");

  #читаем весь файл конфигурации
  read_file("$fl_cfg",\$master_config);
  $master_config.='[';

  #определим каталог с шаблонами
  $master_config =~ m/\n\s*\[global paths\](.*?)\[/si;
  my $section = "$1";
  $section =~ m/^\s*DirTemplates\s*=\s*([^\n#]*)/mi;
  $DirTemplates = "$1";
  $DirTemplates =~ s/\\$//m;

  #определим каталог с условиями задач
  $section =~ m/^\s*DirPrbConditions\s*=\s*([^\n#]*)/mi;
  $DirPrbCond = "$1";
  $DirPrbCond =~ s/\\$//m;

  #определим каталог с тестами и проверяющими программами
  $section =~ m/^\s*DirProblems\s*=\s*([^\n#]*)/mi;
  $DirProblems = "$1";
  $DirProblems =~ s/\\$//m;

  #определим виртуальный каталог с условиями задач
  $section =~ m/^\s*DirVirtualPrb\s*=\s*([^\n#]*)/mi;
  $DirVirtualPrb = "$1";
  $DirVirtualPrb =~ s/\/$//m;

  #определим каталог с архивом отчетов и исходников
  $section =~ m/^\s*DirSrcArhive\s*=\s*([^\n]*)/mi;
  $DirSrcArh = "$1";
  $DirSrcArh =~ s/\\$//m;

  #определим каталог с временными файлами
  $section =~ m/^\s*DirTemp\s*=\s*([^\n]*)/mi;
  $DirTemp = "$1";
  $DirTemp =~ s/\\$//m;

  #определим каталог с присланными решениями
  $section =~ m/^\s*DirTempSrc\s*=\s*([^\n]*)/mi;
  $DirTempSrc = "$1";
  $DirTempSrc =~ s/\\$//m;

  #определим каталог со стандартными чекерами
  $section =~ m/^\s*DirStdCheckers\s*=\s*([^\n]*)/mi;
  $DirStdCheckers = "$1";
  $DirStdCheckers =~ s/\\$//m;

  #определим имя файла архиватора
  $section =~ m/^\s*ArchivatorExe\s*=\s*([^\n]*)/mi;
  $ArchivatorExe = "$1";

  #определим имя файла программы удаленного запуска процессов
  $section =~ m/^\s*RemoteRunExe\s*=\s*([^\n]*)/mi;
  $RemoteRunExe = "$1";

  #определим имя файла со списком запускаемых серверов
  $section =~ m/^\s*ServersCfg\s*=\s*([^\n]*)/mi;
  $ServersCfg = "$1";

  #поместим в хеш все параметры из секции [problem paths]
  my $k,$v;
  ($section) = $master_config =~ m/\n\s*\[problem paths\]([^\[]*)/si;
  while (($k,$v) = $section =~ m/^\s*([\w\d_]+)\s*=\s*([^\n#]*)/mi) {
     $section=$';
     $v =~ s/ *\Z//;
     $ProblemPaths{$k} = $v;
  }

  #поместим в хеш все параметры из секции [Options]
  ($section) = $master_config =~ m/\n\s*\[options\]([^\[]*)/si;
  while (($k,$v) = $section =~ m/^\s*([\w\d_]+)\s*=\s*([^\n#]*)/mi) {
     $section=$';
     $v =~ s/ *\Z//;
     $Options{$k} = $v;
  }

  my $LDAPServer = $Options{'LDAPServer'};
#  to_log ("ldap = $LDAPServer");

  #определим файл с параметрами компиляторов
  $master_config =~ m/\n\s*\[global paths\](.*?)\[/si;
  $section = "$1";
  $section =~ m/^\s*CompilCfg\s*=\s*([^\n#]*)/mi;
  my $CompilCfg = "$1";
  my $config='',$id_compil;

  #читаем весь файл с параметрами компиляторов
  read_file($CompilCfg,\$config);

  $config.='[';
  while ( ($section) = $config =~ m/^\s*\[[^\]]+\]([^\[]+)/mi) {
     $config=$';

     ($id_compil) = $section =~ m/^\s*id\s*=\s*(\d+)/mi;

     next if (!$id_compil);

     while (($k,$v) = $section =~ m/^\s*([\w\d_]+)\s*=\s*([^\n#]*)/mi) {
        $section=$';
        $v =~ s/ *$//m;
        $Compilers{$id_compil}->{$k}=$v;
     }

  }

  $TMPDIRECTORY=$DirTemp; 

}

#соединяется с БД
sub connect_db
{
  #определим параметры БД
  $master_config =~ m/\n\s*\[database\]([^\[]*)/si;
  $section = "$1";
  $section =~ m/^\s*dbname\s*=\s*([^\n#]*)/mi;
  my $dbname = "$1";
  $section =~ m/^\s*user\s*=\s*([^\n#]*)/mi;
  my $user_db = "$1";
  $section =~ m/^\s*password\s*=\s*([^\n#]*)/mi;
  my $password_db = "$1";

  my $dsn = "dbi:InterBase:dbname=$dbname;ib_dialect=3";
 $db = DBI->connect("$dsn", "$user_db", "$password_db",
    {LongReadLen=>1048576, AutoCommit => 0} );

  #to_log("xxx dbname=|$dbname|, dsn=$dsn, user_db=$user_db, password_db=$password_db, db=$db");

  $db->func(-access_mode=>'read_write',
            -isolation_level => ['read_committed', 'record_version'], 
            -lock_resolution => 'no_wait','ib_set_tx_param');
  $db->commit;
}

sub fcgi_init
{
  $request = FCGI::Request(\*STDIN, \*STDOUT, \*STDERR, \%ENV);
}

#примимает указатель на строку и заменяет в ней все директивы
#  $include_file("fn") на содержимое файла fn
sub include_files
{
  my($text) = @_;
  my $new_text,$fname;
  
  while (($fname) = $$text =~ m/\$include_file\s*\(\s*\"([^\"]*)\"\s*\)/si) {
     read_file("$DirTemplates\\$fname",\$new_text);
     $$text =~ s/\$include_file\s*\(\s*\"([^\"]*)\"\s*\)/$new_text/si;
  }
}

#заменяет $current_page на виртуальный адрес текущего скрипта
sub current_page
{
  my($text) = @_;
  my $new_text=$ENV{"SCRIPT_NAME"};
  my $rrl;
  $$text =~ s/\$current_page/$new_text/ig;

  #$$text =~ s/\$add_param//ig;
  my $add_param;
  if ($ENV{"REQUEST_URI"} =~ m/\?/) {
     $add_param=$';
  }else{
     $add_param="";
  }
  $add_param =~ s/id_lng=[^&]*&?//ig;
  $add_param =~ s/re_login=[^&]*&?//ig;
  if ($add_param) {
     $add_param='&'.$add_param;
  }
  $$text =~ s/\$add_param/$add_param/ig;

  
  $$text =~ s/\$find_value//ig;

  $$text =~ s/<!--start_login-->(.*?)<!--finish_login-->//sig;
  $$text =~ s/<!--start_not_login-->(.*?)<!--finish_not_login-->//sig;
  $$text =~ s/<!--start_manage_system-->(.*?)<!--finish_manage_system-->//sig;
  
  $rrl=int(rand(10000))+1;
  $$text =~ s/\$random_re_login/$rrl/ig;

  my $time_gen=0;
  $time_gen=(Win32::GetTickCount()-$start_request_time)/1000 if $start_request_time;
  $$text =~ s/\$time_gen/$time_gen/ig;

}

#вставляем информацию о пользователе который вошёл в систему
sub login_info
{
   my ($text,$user) = @_;
   my $query,$sth,@row,$s;
   
   $query="select id_publ, name from authors where id_publ=$user";
   $sth=$db->prepare($query);
   $sth->execute();
   @row=$sth->fetchrow_array();
   $sth->finish;
   if ($row[0]) {
      $row[1] =~ s/ *\Z//;
      html_text(\$row[1]);
      $$text =~ s/<!--start_not_login-->(.*?)<!--finish_not_login-->//sig;

      while ($$text =~ m/<!--start_login-->(.*?)<!--finish_login-->/si) {
         $s=$1;
         $s =~ s/\$l_id_author/$row[0]/ig;
         $s =~ s/\$l_author_name/$row[1]/ig;
         $$text =~ s/<!--start_login-->(.*?)<!--finish_login-->/$s/si;
      }

   } else {
      $$text =~ s/<!--start_not_login-->(.*?)<!--finish_not_login-->/$1/sig;
      $$text =~ s/<!--start_login-->(.*?)<!--finish_login-->//sig;
   }
  $$text =~ s/<!--start_manage_system-->(.*?)<!--finish_manage_system-->/is_manage_system($user)>0?$1:''/esig;
}

#проверяет язык в БД и cookies
sub GetLanguage
{
  my($id_lng_ptr,$cookie1_ptr) = @_;
  
  $$cookie1_ptr=undef;
  $$id_lng_ptr = $incgi->param("id_lng") if $incgi;
  if ($$id_lng_ptr eq "") {
     $$id_lng_ptr = $cookies{"id_lng"};
     my $find_substr = $$id_lng_ptr =~ m/\s*id_lng\s*=\s*(\w*)/;
     if ($find_substr) {$$id_lng_ptr = "$1";}
  } 

  #если язык левый то используем язык по умолчанию
  my $sth = $db->prepare("select count(*) from langs where id_lng='$$id_lng_ptr'");
  $sth->execute;
  my @row = $sth->fetchrow_array;  
  if ($row[0]==0)
  {  
     $sth->finish;
     $sth = $db->prepare("select def_lng from const");
     $sth->execute;
     @row = $sth->fetchrow_array;
     $$id_lng_ptr=$row[0];  
  } else {
    $$cookie1_ptr = new CGI::Cookie(-name=>"id_lng",-value=>"$id_lng",-path=>"/");
  }
  $sth->finish;
} 

#добавляет информацию о всех поддерживаемых компиляторах
sub insert_all_compilers
{
   my($text,$id_cmp) = @_;
   my $sect_compil,$s,$before,$after,$query,$sth;

   while ($$text =~ m/<!--start_all_compiler-->(.*?)<!--finish_all_compiler-->/si) {;
   $before=$`;
   $sect_compil=$1;
   $after=$';

   $query=" select compil.id_cmp, compil.name, compil.id_serv, servers.name "
         ." from compil "
         ." left join servers "
         ."   on compil.id_serv=servers.id_srv "
         ." order by compil.id_serv, compil.id_cmp ";
   $sth=$db->prepare($query);
   $sth->execute();
   
   while (my @row=$sth->fetchrow_array) {
      $row[1] =~ s/ *$//m;
#      $row[3] =~ s/ *$//m;

      $s=$sect_compil;
      $s =~ s/\$compiler_id/$row[0]/ig;
      $s =~ s/\$compiler_name/$row[3]$row[1]/ig;
      
      $s =~ s/\$compiler_selected\{([^\}]*)\}/$row[0]==$id_cmp?$1:''/eig;
      $before.=$s;
   }
   $sth->finish();

   $$text=$before.$after;
   }
}

#добавляет информацию о поддерживаемых компиляторах определённого сервера
sub insert_compilers
{
   my($text,$id_cmp,$id_prb) = @_;
   my $sect_compil,$s,$before,$after,$query,$sth;

   while ($$text =~ m/<!--start_compiler-->(.*?)<!--finish_compiler-->/si) {;
   $before=$`;
   $sect_compil=$1;
   $after=$';

   if ($id_prb)
   {
      $query=" select compil.id_cmp, compil.name "
            ." from compil "
            ." inner join problems "
            ."   on problems.id_serv=compil.id_serv "
            ." where problems.id_prb=$id_prb "
            ." order by compil.id_cmp ";
   } else {
      $query=" select id_cmp, name "
            ." from compil "
            ." where id_serv=0 "
            ." order by id_cmp ";
   }
   $sth=$db->prepare($query);
   $sth->execute();
   
   while (my @row=$sth->fetchrow_array) {
      $row[1] =~ s/ *$//m;

      $s=$sect_compil;
      $s =~ s/\$compiler_id/$row[0]/ig;
      $s =~ s/\$compiler_name/$row[1]/ig;
      
      $s =~ s/\$compiler_selected\{([^\}]*)\}/$row[0]==$id_cmp?$1:''/eig;
      $before.=$s;
   }
   $sth->finish();

   $$text=$before.$after;
   }
}

#добавляет информацию о странах
sub insert_countries
{
   my($text,$id_cn) = @_;
   my $sect_country,$s,$before,$after,$query,$sth;

   while ($$text =~ m/<!--start_country-->(.*?)<!--finish_country-->/si) {;
   $before=$`;
   $sect_country=$1;
   $after=$';

   $query="select id_cn, name from countrs order by id_cn";
   $sth=$db->prepare($query);
   $sth->execute();
   
   while (my @row=$sth->fetchrow_array) {
      $row[1] =~ s/ *$//m;

      $s=$sect_country;
      $s =~ s/\$country_id/$row[0]/ig;
      $s =~ s/\$country_name/$row[1]/ig;
      
      $s =~ s/\$country_selected\{([^\}]*)\}/$row[0]==$id_cn?$1:''/eig;
      $before.=$s;
   }
   $sth->finish();

   $$text=$before.$after;
   }

}

#вывод сообщения об ошибке
sub print_err
{
  my($err_text,$hide_header) = @_;

  my $id_lng,$cookie_temp;
  GetLanguage(\$id_lng,\$cookie_temp);
  
  my $fh = new IO::File;
  $fh->open("< $DirTemplates\\error_$id_lng.html");
  my $string_template=""; 
  while (<$fh>) {
      $string_template .= $_;
  }
  $fh->close;

  include_files(\$string_template);

  current_page(\$string_template);

  $string_template =~ s/\$err_text/$err_text/g;

  $string_template =~ s/<!--.*?-->//sg;

  if (!$hide_header) {
  print header(-charset=>"Windows-1251",
               -cache_control=>"no-cached",
               -pragma=>"no-cache"
               );
  }
  
  print "$string_template";
}


#заменим <, >, &, "
sub html_text
{
  my($str,$pre)=@_;
  $$str =~ s/&/&amp;/g;
  $$str =~ s/&amp;#(\d+)/&#$1/g;
  $$str =~ s/</&lt;/g;
  $$str =~ s/>/&gt;/g;
  $$str =~ s/"/&quot;/g;
  $$str =~ s/\t/  /g;
  if ($pre) {
     $$str =~ s/([^\n\r ]{80})([^\n\r ])/$1\n$2/g;
     
     $$str =~ s/(\n\r?)|(\r\n?)/<br\/>/g;
     $$str =~ s/  / &nbsp;/g;
  }
#  $$str = "<pre>".$$str."</pre>";
}

#получить переданное браузером имя пользователя
sub get_user_name
{  
  my ($msg,$re_login,$no_header)=@_;

  my $user_name="";

  $ENV{"HTTP_CGI_AUTHORIZATION"} =~ s/basic\s+//i;
  ($user_name,$user_pass) = split(/:/,decode_base64($ENV{"HTTP_CGI_AUTHORIZATION"}));

  #если имя пользователя неопределено или пользователь хочет "перезайти"
  if (($user_name eq "" && !$no_header) || $re_login ) {
    $user_name="";
    my $cookie_login = new CGI::Cookie(-name=>"re_login_c",-value=>"$re_login",-path=>"/");
    #выдать запрос на аутентификацию
    print header(-status=>"401 Unauthorized",
                 -cookie=>[$cookie_login],
                 -charset=>"Windows-1251",
                 -WWW_Authenticate=>get_authenticate_header($msg)
               );
    print_err("user not defined!!!","true");
  }

  return $user_name; #вернуть имя пользователя
}

#сформировать запрос для аутентификации
sub get_authenticate_header
{
  my($msg,$st)=@_;

  if ($msg eq "") {
     $msg="author_area";
  }
  my $msg_auth=$msg."@".$ENV{'SERVER_NAME'};

  if ($st eq "") {
     $st="false";
  }



  my $ret_str = "Basic realm=\"$msg\"";
  
  return $ret_str;
}


#аутентификация через LDAP. Если аутентификация успешна, то:
#а). Пользователь помещается в группу "студенты" (если ещё не в ней)
#б). Для него заполняется отображаемое имя, фамилия, имя и отчество значениями из LDAP

sub LDAP_authenticate
{
  my($user,$password) = @_;
  $user = lc($user);
  $user =~ s/'/''/g;

  #частный случай
  if ($user =~ /^student|school|emm$/i) {return "false";}

  my $LDAPServer = $Options{'LDAPServer'};
  my $UserDomain = $Options{'UserDomain'};
  my $AccessGroup = $Options{'AccessGroup'};

#  to_log("LDAPServer=$LDAPServer, UserDomain=$UserDomain, AccessGroup=$AccessGroup, user=$user, password=$password");

  # Если пользователь член группы AccessGroup
  if (! Win32::NetAdmin::GroupIsMember($LDAPServer, $AccessGroup, $user)) {return "false";}
  
  # И если удаётся привязаться от его имени к корню AD
  my $oRoot = Win32::OLE->GetObject("LDAP:");
  my $Status = $oRoot->OpenDSObject("LDAP://$UserDomain", $user, $password, 0x1);
#  to_log("Status: $Status");
  if (!defined $Status) {return "false";}

  #получим идентификатор пользователя. Если пользователя ещё нет в базе 
  #проверяющей системы, создадим его
  my $query = "select id_publ from authors where login='$user'";
  my $sth = $db->prepare($query);
  $sth->execute;
  my ($id_publ)=$sth->fetchrow_array;
  $sth->finish;
  if ($id_publ eq "") { #пользователь не найден - создаём
    $query = "insert into authors (name, id_cn, pwd, login) values ('$user', 1, '$password','$user')";
#    to_log($query);
    $sth = $db->prepare($query);
    $sth->execute;
    #и снова запрашиваем его идентификатор - теперь он быть должен
    $query = "select id_publ from authors where login='$user'";
    $sth = $db->prepare($query);
    $sth->execute;
    ($id_publ)=$sth->fetchrow_array;
    #поместим пользователя в группы по умолчанию
    $query="insert into groups_authors(id_grp,id_publ) select id_grp, "
                 ."$id_publ from groups where default_grp>0";
    $sth=$db->prepare($query);
    $sth->execute();
  }

  #поместим пользователя в группу студентов
  my $LDAPDefaultGroup = $Options{'LDAPDefaultGroup'};
  $query = "select count(*) from groups_authors where id_publ=$id_publ and id_grp=$LDAPDefaultGroup";
#  to_log($query);
  $sth = $db->prepare($query);
  $sth->execute;
  my ($res)=$sth->fetchrow_array;
  $sth->finish;
  if ($res == 0) {
    #добавляем группу для пользователя
    $query = "insert into groups_authors (id_publ, id_grp) values ($id_publ,$LDAPDefaultGroup)";
#    to_log($query);
    $sth = $db->prepare($query);
    $sth->execute;
  }


  #поместим пользователя в его учебную группу
  if ($user =~ /(^\w+\d\d\d\d)/) {
    $query = "insert into groups_authors(id_grp,id_publ) select id_grp, $id_publ from groups where dn='$1'";
    $sth = $db->prepare($query);
    $sth->execute;
  }

  #заполним для пользователя значения имени, фамилии и отчества из LDAP
  $query="dsquery * -filter (samAccountName=$user) -attr *";
  my @user_props = `$query`;
  my $sn, $givenName, $initials, $p, $displayName, $patname;
  foreach $p (@user_props) {
    $p =~ tr/‰–“Љ…Ќѓ™‡•љ”›‚ЂЏђЋ‹„†ќџ—‘Њ€’њЃћр©жгЄҐ­Јий§екдлў Їа®«¤¦нпзб¬ЁвмЎос/ЙЦУКЕНГШЩЗХЪФЫВАПРОЛДЖЭЯЧСМИТЬБЮЁйцукенгшщзхъфывапролджэячсмитьбюё/;
    if($p =~ /(\w*)?:\s*(.*)/) {
      if ($1 eq "sn") {$sn=$2;}
      elsif ($1 eq "givenName") {$givenName=$2;}
      elsif ($1 eq "initials") {$initials=$2;}
      elsif ($1 eq "displayName") {$displayName=$2;}
    }
  }
  $patname = $initials;
  if ($displayName =~ /([^\s]+)\s([^\s]+)\s([^\s]+)/) {
    if (($1 eq $sn) && ($2 eq $givenName)) {$patname=$3;}
  }
  $query = "update authors set name='$displayName', surname='$sn', uname='$givenName', patname='$patname' where id_publ=$id_publ";
#  to_log($query);
  $sth = $db->prepare($query);
  $sth->execute;

  return "true";
}

#определение правильности пароля пользователя по хеш значениям
sub authenticate
{
  my($user_name,$pwd,$msg)=@_;

  if ($msg eq "") {
     $msg="author_area";
  }

  my $msg_auth=$msg."@".$ENV{'SERVER_NAME'};

  #получить значения полей переданных браузером
  my ($auth_str) = $ENV{'HTTP_CGI_AUTHORIZATION'} =~ /basic\s(.+)/i;
  ($REMOTE_USER,$REMOTE_PASSWD) = split(/:/,decode_base64($ENV{"HTTP_CGI_AUTHORIZATION"}));

#  to_log("$REMOTE_USER,$user_name,$REMOTE_PASSWORD,$pwd");

  #to_log("LDAP auth failed: user=$REMOTE_USER, pass=<hidden>");


  if (($REMOTE_USER eq $user_name) && ($REMOTE_PASSWD eq $pwd)) { #все верно
    $ret_stat="true";
  } else { #пароль неправильный или некоррекный запрос
    $ret_stat="false";
  }

  return $ret_stat;

}


#возвращаем идентфикатор пользователя
#параметры - необязятельная аутентификация, дополнительная функция определения права доступа
sub authenticate_process
{
   my ($no_header,$add_func) = @_;

   my $id_user=0,$login,$l_login;
   my $query,$sth,$auth_st;
   my $re_login,$re_login_c,$new_url;
   
   $re_login = $incgi->param("re_login")+0;
   $re_login_c = (exists $cookies{"re_login_c"}) ? $cookies{"re_login_c"}->value+0 : 0;
   $re_login_c=0 if ($re_login!=$re_login_c);

   #получить имя пользователя
   $login = get_user_name(undef,$re_login-$re_login_c,$no_header);

   if ($re_login-$re_login_c) {
      $id_user='end';
   }

   #пользователь определен
   if ($login ne "") {
      $l_login=lc($login);
      $l_login =~ s/'/''/g;

      #попробуем выполнить аутентификацию через LDAP. Если она успешна и пользователя нет у нас,
      #он будет создан автоматически
      my ($auth_str) = $ENV{'HTTP_CGI_AUTHORIZATION'} =~ /basic\s(.+)/i;
      ($REMOTE_USER,$REMOTE_PASSWD) = split(/:/,decode_base64($ENV{"HTTP_CGI_AUTHORIZATION"}));
#      to_log("ldap auth: $login $REMOTE_PASSWD");
      $auth_st = LDAP_authenticate($login,$REMOTE_PASSWD);

      #получить из БД идентификатор и пароль пользователя
      $query = "select id_publ,pwd from authors where login='$l_login'";
      $sth = $db->prepare($query);
      $sth->execute;
      my ($id_publ,$pwd)=$sth->fetchrow_array;
      $sth->finish;

      $pwd =~ s/ *\Z//; #удалим пробелы в конце пароля

      if ($id_publ ne "") { #пользователь найден

         if ($auth_st ne "true") {$auth_st=authenticate($login,$pwd);}

         if ($auth_st eq "change") { #имя и пароль верные, но время жизни nonce истекло
            $id_user='end';
            print header(-status=>"401 Unauthorized",
                    -WWW_Authenticate=>get_authenticate_header(undef,"true"));
            print "change nonce!\n";
         }
         
         if ($auth_st eq "true" && $add_func) { #аутентификация успешна
            $auth_st="false" if (!eval($add_func)); #вызов функции авторизации
         }

         if ($auth_st eq "true") {
            $id_user=$id_publ;
         }
      }

      #пользователь неопределен или пароль неправилиный
      if (($id_publ eq "" || $auth_st eq "false") && !$no_header) {
#          to_log("Access Denied");
          $id_user='end';
          #выдать запрос на аутентификацию
          print header(-status=>"401 Access Denied",
                       -charset=>"Windows-1251",
                       -WWW_Authenticate=>get_authenticate_header());
          print_err("Access Denied","true");
      }
   }

    #вход пользователя под другим именем
    if ($re_login && $re_login-$re_login_c==0 && $id_user ne 'end') {
        if ($id_user) {
           $new_url = $ENV{"REQUEST_URI"};
           $new_url =~ s/re_login=\d+&?//ig;
           my $cookie_login = new CGI::Cookie(-name=>"re_login_c",-value=>"0",-path=>"/");

           print header(-status=>"301 Moved Permanently",
                        -cookie=>[$cookie_login],
                        -Location=>$new_url);
        
        } else {
           print header(-status=>"200 OK",
                        -charset=>"Windows-1251",
                        -cache_control=>"no-cached",
                        -pragma=>"no-cache"
                        );
           print_err("Invalid username or password","true");
        }

        $id_user='end';
    }

   return $id_user; #вернуть идентификатор пользователя
}


sub insert_status_rows
{

  my ($text,$id_lng,$id_stat,$id_prb,$id_user,$id_publ,$id_rsl) = @_;
  my $before,$after,$sect_srow,$row_count,$s,$s_src,$s_report;
  my $add_index="",$add_prm_q="",$op='<';
  my $query,$sth,%prb_hash=(),%slv_prb_hash=(),%publ_hash=(),$iview=-2,$single_author=0;

  $id_user=$id_user+0;

  #для страницы со статистикой задачи
  if ($id_prb>0 && $id_publ==0 && $id_rsl==0) {
     $add_prm_q="and s.id_prb=$id_prb and s.id_rsl=0 ";
  }

  #обычный статус
  if ($id_prb==0 && $id_publ==0 && $id_rsl==0 && $id_user>0) {
     $query="select case when view_status is null then -1 else view_status end from authors where id_publ=$id_user";
     $sth=$db->prepare($query);
     $sth->execute();
     ($iview)=$sth->fetchrow_array();
     $sth->finish();
     
     if ($iview==-1) {
        $add_prm_q="and s.id_publ=$id_user ";
        $single_author=1;
     } elsif ($iview==-2) {
        $add_prm_q=" ";
     } else {
        $add_prm_q="and exists (select id_grp from get_groups_user(s.id_publ) where id_grp=$iview) ";
     }
  }

  #фильтр по пользователю и задаче
  if ($id_prb>0 && $id_publ>0 && $id_rsl==0) {
     $add_prm_q="and s.id_prb=$id_prb and s.id_publ=$id_publ ";
  }

  #фильтр по пользователю и результату
  if ($id_prb==0 && $id_publ>0 && $id_rsl>0) {
     $add_prm_q="and s.id_rsl=$id_rsl-1 and s.id_publ=$id_publ ";
  }

  #фильтр по задаче и результату
  if ($id_prb>0 && $id_publ==0 && $id_rsl>0) {
     $add_prm_q="and s.id_rsl=$id_rsl-1 and s.id_prb=$id_prb ";
  }


  $$text =~ m/<!--start_status_row\((\d+)\)-->(.*?)<!--finish_status_row-->/si;
  $before=$`;
  $row_count=$1+0;
  $sect_srow=$2;
  $after=$';

  if ($row_count==1) {
     $op='=';
     $add_prm_q=" ";
  }

  if ($sect_srow=~m/\$show_report\$\{(.*?)\|(.*?)\}/i) {
     $query= <<SQL;
select first $row_count s.id_prb
   from status s
   where s.id_stat $op $id_stat $add_prm_q
   order by s.id_stat desc
SQL

     #print header();
     #print $query;
     $sth = $db->prepare($query);
     $sth->execute;
     while (@row = $sth->fetchrow_array) {
        $prb_hash{$row[0]}=$row[0];
        $slv_prb_hash{$row[0]}=0;
     }
     $sth->finish;

     $query="select id_prb, f_help_prb from access_user_prb($id_user,'.0.".join('.',keys %prb_hash).".')";
     #print header();
     #print $query;
     $sth = $db->prepare($query);
     $sth->execute;
     while (@row = $sth->fetchrow_array) {
        $prb_hash{$row[0]}=$row[1];
     }
     $sth->finish;
     #$rul=access_source($id_stat,$id_user,\$who_view,\$id_problem);

     $slv_prb_hash{0}=0;
     $query="select distinct id_prb from status where id_publ=$id_user and id_rsl=0 and id_prb in (".join(',',keys %slv_prb_hash).")";
     $sth = $db->prepare($query);
     $sth->execute;
     while (@row = $sth->fetchrow_array) {
        $slv_prb_hash{$row[0]}=1;
     }
     $sth->finish;

  }

  if ($id_user>0 && ($iview!=-1 || $row_count==1)) {
     $query= <<SQL;
select first $row_count s.id_publ
   from status s
   where s.id_stat $op $id_stat $add_prm_q
   order by s.id_stat desc
SQL

     $sth = $db->prepare($query);
     $sth->execute;
     while (@row = $sth->fetchrow_array) {
        $publ_hash{$row[0]}=$row[0] if ($row[0]!=$id_user);
     }
     $sth->finish;

     $s=join(',',keys %publ_hash);
     #to_log("s=$s");
     
     if (length($s)>0) {
        $query= <<SQL;
select distinct a.id_publ
   from get_groups_boss($id_user) ggb, authors a
   where ggb.is_boss>0 and a.id_publ in ($s) and
     exists (select id_grp from get_groups_user(a.id_publ) where id_grp=ggb.id_grp)
SQL

        $sth = $db->prepare($query);
        $sth->execute;
        %publ_hash=();
        while (@row = $sth->fetchrow_array) {
           $publ_hash{$row[0]}=$row[0];
        }
        $sth->finish;
     } else {
        $single_author=1 if ($row_count==1);
     }

  }
  $publ_hash{$id_user}=$id_user;

  $sect_srow=~s/\$single_author\$\{(.*?)\|(.*?)\}/$single_author>0?$1:$2/eig;

  $query= <<SQL;
select first $row_count s.id_stat, cast(s.dt_tm as date),cast(s.dt_tm as time),
   s.id_publ, (select a.name from author_names a where a.id_publ=s.id_publ),
   s.id_prb, (select c.name from compil c where c.id_cmp=s.id_cmp),
   (select r.name from results_lng r where r.id_rsl=s.id_rsl and r.id_lng='$id_lng'),
   s.test_no,cast(s.time_work as numeric(10,4)),s.mem_use,
   (select b.id_slv from best_solve b where b.id_slv=s.id_stat),
   (select first 1 sr.id_stat from status_reports sr where sr.id_stat=s.id_stat),
   s.id_rsl,s.warn_rsl,
   (select p.name from problems_lng p where p.id_prb=s.id_prb and p.id_lng='$id_lng'),
   s.who_view,cast(100-s.uniq_proc as integer),s.cmp_id_stat
   from status s
   where s.id_stat $op $id_stat $add_prm_q
   order by s.id_stat desc
SQL

  $sth = $db->prepare($query);
  $sth->execute;

  my $cnt=0;
  my $prev_rec=0;
  my $next_rec=0;
  my $test_n="";
  my @row = ();
  while ((@row = $sth->fetchrow_array) && $cnt<$row_count) {
     if ($cnt==0) { $prev_rec= $row[0]+$row_count+1; } 
     if ($cnt==$row_count-1) { $next_rec= $row[0]; } 
     #заменим <, >, &, " в имени автора
     html_text(\$row[4]);
     foreach (@row) {
        #удалим пробелы в конце поля
        $_ =~ s/ *\Z//;
        #если поле пусто, то заменим его на длинный пробел
        if ($_ eq "") {$_ = "&nbsp;";}
     }

     $s=$sect_srow;
     
     $s=~s/\$my_submit\$\{(.*?)\|(.*?)\}/$publ_hash{$row[3]}>0?$1:$2/eig;

     $s=~s/\$warn_plagiat\$\{(.*?)\|(.*?)\}/($row[13]==0 && $row[14]==9 )?$1:$2/eig;

     $s=~s/\$hint_plagiat\$\{(.*?)\|(.*?)\}/((($row[13]==0 && $row[14]!=9) || $row[13]==9) && $row[18]>0 )?$1:$2/eig;
     
     $s_report=$publ_hash{$row[3]}>0 
         && ($row[12]>0 || ($row[18]>0 && ($row[13]==0 || $row[13]==9))) 
         && ($prb_hash{$row[5]}>0 || $row[13]==7 || $row[13]==0 || $row[13]==9);
     $s=~s/\$show_report\$\{(.*?)\|(.*?)\}/$s_report ?$1:$2/eig;

     $s=~s/\$best_solve\$\{(.*?)\|(.*?)\}/$row[11]>0?$1:$2/eig;
     
     $s_src=$row[13]==0 && ($row[3]==$id_user || $row[16] eq 'a' || ($row[16] eq 's' && $slv_prb_hash{$row[5]}==1) || $publ_hash{$row[3]}>0);
     $s=~s/\$show_src\$\{(.*?)\|(.*?)\}/$s_src ?$1:$2/eig;

     $s=~s/\$not_uniq_proc_int/$row[17]/ig;
     $s=~s/\$stat_date/$row[1]/ig;
     $s=~s/\$stat_time/$row[2]/ig;
     $s=~s/\$author_id/$row[3]/ig;
     $s=~s/\$problem_id/$row[5]/ig;
     $s=~s/\$problem_name/$row[15]/ig;
     $s=~s/\$compiler_name/$row[6]/ig;

     $s=~s/\$result_name/$row[7]/ig;

     $s=~s/\$test_n/$row[8]/ig;
     $s=~s/\$time_work/$row[9]/ig;
     $s=~s/\$mem_use/$row[10]/ig;
     $s=~s/\$author_name/$row[4]/ig;

     $s=~s/\$stat_id/$row[0]/ig;

     $before.=$s;

     $cnt++;
  }
  $sth->finish;

  $$text=$before.$after;

  $$text =~ s/<!--start_author-->(.*?)<!--finish_author-->/$single_author>0?'':$1/esig;

  $$text =~ s/\$prev_rec/$prev_rec/g;                                
  $$text =~ s/\$next_rec/$next_rec/g;
  
}


#полностью считывает файл (имя файла, указатель на строку получатель)
sub read_file
{
   my ($f_name,$ptr_text)=@_;
   my $fh;
   
   $fh=new IO::File;

   $fh->open("< $f_name");
   $$ptr_text=""; 
   while (<$fh>) {
      $$ptr_text .= $_;
   }
   $fh->close;
}

# замена на передаваемые параметры $$ 
sub insert_params
{
   my ($ptr_text) = @_;
   my $k,$v,$ctext,$rez_text;

   $ctext=$$ptr_text;
   $rez_text='';
   while ($ctext =~ m/\$\$([\d\w_]+)/mi) {
      $k="$1";
      $v=$incgi->param($k);
      #to_log("k=$k,v=$v");
      $rez_text.=$`.$v;
      $ctext=$';
   }
   $rez_text.=$ctext;

   #to_log($rez_text);
   while ($rez_text =~ m/<!--\?([\d\w\!\=\-]+?),(.*?)-->/mi) {
      $k=$1;
      #to_log("k=$k");
      $v=eval($k);
      $rez_text =~ s/<!--\?$k,(.*?)-->/$v?$1:''/emig;
   }
   $rez_text =~ s/<!--\?(.*?)-->//mg;

   $$ptr_text=$rez_text;
}

#загружает файл посланный клиентом в указанный файл на сервере
sub upload_file
{
   my ($f_name_in,$dest_file)=@_;
   my $fin,$fout,$rez=1,$buffer,$byteread;
   
   $fin=$incgi->upload($f_name_in);
   #to_log("f_name_in = $f_name_in; fin = $fin; dest_file = $dest_file");

   $rez=0 if (!$fin || $incgi->cgi_error);

   if ($rez) {
      $fout=new IO::File;
      $fout->open("> $dest_file");
      binmode($fin);
      binmode($fout);
      seek($fin,0,0);
      while ($byteread=read($fin,$buffer,4096)) {
         #to_log("byteread = $byteread");
         print $fout $buffer;
      }
      $fout->close;
   }

   return $rez;
}

#разархивирует указанный файл в указанный каталог с опциональным режимом "без подкаталогов"
sub un_pack
{
   my($file,$dir,$not_sub_folders) = @_;
   my $mode,$rez=0,$cmd;
   if ($not_sub_folders) {
      $mode='e';
   } else {
      $mode='x';
   }

   #$rez = system ($ArchivatorExe,"$mode -y -o\"$dir\" \"$file\" 1>null.txt") ;
   my $fl=new IO::File;
   open($fl,"$ArchivatorExe $mode -y -o\"$dir\" \"$file\" |");
   while (<$fl>) { }
   close($fl);

   return !$rez;
}

#заархивирует в указанный файл указанные каталоги 
sub re_pack
{
   my($file,@dirs) = @_;
   my $dirs_str='"'.join('" "',@dirs).'"';

   if (!-e($file) || unlink($file)) {
      my $fl=new IO::File;
      open($fl,"$ArchivatorExe a -tzip -mx9 -y \"$file\" $dirs_str |");
      while (<$fl>) { }
      close($fl);
   } else {
      return 0;
   }

   return 1;
}

#компилирует указанный файл, указанным компилятором, выход компилятора, возвращает имя полученного файла
sub compiling_file
{
   my ($src_file,$id_compil,$ptr_out) = @_;
   my $CompilScript,$CompilParam,$FileIn,$FileOut;
   my $in_file,$out_file,$uniq_x;

   $uniq_x='q'.(int( rand(899_999))+100_000).'q';
   
   $CompilScript = $Compilers{$id_compil}->{'CompilScript'};
   $CompilParam = $Compilers{$id_compil}->{'CompilParam'};
   $FileIn = $Compilers{$id_compil}->{'FileIn'};
   $FileOut = $Compilers{$id_compil}->{'FileOut'};
   
   $FileIn =~ s/\$\(id\)/$uniq_x/ig;
   $FileOut =~ s/\$\(id\)/$uniq_x/ig;
   $CompilParam =~ s/\$\(id\)/$uniq_x/ig;

   ($in_file) = $src_file =~ m/(.*)\\/s;
   $in_file.="\\$FileIn";
   ($out_file) = $src_file =~ m/(.*)\\/s;
   $out_file.="\\$FileOut";

   if ($CompilScript) {
   
      #переименуем компилируемый файл
      rename $src_file,$in_file;

      my $ProcessObj;
      Win32::Process::Create($ProcessObj,$ENV{'ComSpec'},
                          "cmd /c \"$CompilScript\" $CompilParam >$uniq_x.stdout",
                          0,NORMAL_PRIORITY_CLASS,$DirTemp);
      $ProcessObj->Wait(INFINITE);

      read_file("$DirTemp\\$uniq_x.stdout",$ptr_out);
      unlink("$DirTemp\\$uniq_x.stdout");  #удаляет временный файл (никогда бы не подумал ;) )

      html_text($ptr_out);
      rename $in_file,$src_file;
   
   } else {
      $out_file="";
   }

   return (-e $out_file)?$out_file:"";

}

sub next_request
{
   my $rez;
   
  $db->func(-access_mode=>'read_only',
            -isolation_level => ['read_committed', 'record_version'], 
            'ib_set_tx_param');
  $db->commit;

   if ($request) {
      $rez = $request->Accept() >= 0;
      $start_request_time=Win32::GetTickCount();
   } else {
      $exit_main_cik = !$exit_main_cik;
      $rez=$exit_main_cik;
   }

  $db->func(-access_mode=>'read_write',
            -isolation_level => ['read_committed', 'record_version'], 
            -lock_resolution => 'no_wait','ib_set_tx_param');
  $db->commit;

   return $rez;
}

sub format_size
{
  my ($size) = @_;
  my $rez='';

  if ($size<1024) {
     $rez=($size+0).' b';
  } else {
     $rez=int(($size/1024)*10)/10 . ' Kb';
  }
  return $rez;
}


#------------------------------------------------------------------------
sub exists_rec
{
   my ($id,$table) = @_;
   my $query,$sth,$rez=0;
 
   if ($table eq 'problems') {
      $query="select id_prb from problems where id_prb=$id";
   } elsif ($table eq 'authors') {
      $query="select id_publ from authors where id_publ=$id";
   } else { #langs
      $id =~ s/\'/\'\'/g;
      $query="select id_lng from langs where id_lng='$id'";
   }
   
   $sth=$db->prepare($query);
   $sth->execute();
   $rez=1 if $sth->fetchrow_array;
   $sth->finish();

   return $rez;
}


#------------------------------------------------------------------------
#параметр - указатель на массив (заполняется процедурой) идентификаторов запущенных серверов
sub get_runing_servers
{
   my ($ptr_arr_srv)=@_;
   @$ptr_arr_srv=();

   my $query,$sth,$sth_edt,$id_srv,$err;

   $db->func(-isolation_level => ['read_committed', 'record_version'], -lock_resolution => 'no_wait','ib_set_tx_param');
   $db->commit;
   $db->{PrintError}=0;

   $query="select id_srv from test_servers";
   $sth=$db->prepare($query);
   $sth->execute();
   while (($id_srv)=$sth->fetchrow_array) {
      $sth_edt=$db->prepare("update lock_servers set test=1 where id_srv=$id_srv");
      $sth_edt->execute();
      $err = $sth_edt->err;
      #to_log("err=$err");
      if (!$err) {
         $sth_edt=$db->prepare("delete from test_servers where id_srv=$id_srv");
         $sth_edt->execute();
         next;
      }
      push(@$ptr_arr_srv,$id_srv);
   }

   $sth->finish();
   $query='delete from lock_servers where id_srv not in ('.join(',',0,@$ptr_arr_srv).')';
   #to_log("qq=$query");

   $sth=$db->prepare($query);
   $sth->execute();
   $db->commit;
   $db->func(-isolation_level => 'snapshot', -lock_resolution => 'wait','ib_set_tx_param');
   $db->{PrintError}=1;

}

#------------------------------------------------------------------------
sub parse_servers_cfg
{
   my ($srv,$srv_cpu)=@_;

   my $text="",$k="",$after="",@arr=(),;
   
   read_file($ServersCfg,\$text);

   $after=$text;
   while (@arr = ($after =~ m/^\s*([\w\d\.-]+)\s*(\d+)\s*((?:\"[^\"]+\")|(?:[^\s]+))[ \t]*([^\n]*)$/mi)) {
      $k=uc($1);
      if (exists $$srv{$k}) {
         $$srv{$k}++;
      } else {
         $$srv{$k}=1;
      }

      $k=uc($1).'$'.$2;
      if (exists $$srv_cpu{$k}) {
         $$srv_cpu{$k}++;
      } else {
         $$srv_cpu{$k}=1;
      }

      $after=$';
   }
   return $text;
}

#------------------------------------------------------------------------
sub start_servers
{
   my ($p_host,$p_cpu) = @_;

   my $text="",$k="",$after="",@arr=(),%srv=(),%srv_cpu=(),@t_serv=();
   my $query,$sth,$host="",$cpu="",$cnt=0,$file="",$add_param="",$lh="";
   

   $text=parse_servers_cfg(\%srv,\%srv_cpu);

   ($lh)=($text=~m/^\s*localhost\s*=\s*([\w\d\.-]+)/mi);
   #to_log("lh=$lh");

   if ($p_host) {
      #to_log("host=$p_host, cpu=$p_cpu");
      %srv = ($p_host=>1);
      %srv_cpu = ($p_host.'$'.$p_cpu=>1);
   } else {
   get_runing_servers(\@t_serv);

   $query='select upper(host_name),processor_num,count(*) from test_servers where id_srv in ('.join(',',0,@t_serv).
          ') group by upper(host_name),processor_num';

   $sth=$db->prepare($query);
   $sth->execute();
   while (($host,$cpu,$cnt)=$sth->fetchrow_array) {
      $host =~ s/ *$//m;
      #to_log("host=$host,cpu=$cpu,cnt=$cnt;      srv{host}=".$srv{$host});

      if (exists $srv{$host}) {
         $srv{$host}-=$cnt;
#         to_log("host=$host,cnt=$cnt,srv=".$srv{$host});
      } else {
         $srv{$host}=-$cnt;
      }
      
      $k=$host.'$'.$cpu;
      if (exists $srv_cpu{$k}) {
         $srv_cpu{$k}-=$cnt;
         #to_log("k=$k,cnt=$cnt,srv_cpu=".$srv_cpu{$k});
      } else {
         $srv_cpu{$k}=-$cnt;
      }
   }
   $sth->finish();
   }

   foreach $k (keys %srv_cpu) {
      ($host,$cpu) = ($k=~m/(.+)\$(.+)/);
      ($file,$add_param) = ($text =~ m/^\s*$host\s*$cpu\s*((?:\"[^\"]+\")|(?:[^\s]+))[ \t]*([^\n]*)$/mi);
      while ($srv{$host}>0 && $srv_cpu{$k}>0 && $file) {
         remote_run(($host eq uc($lh))?'LOCALHOST':$host,$cpu,$file,$add_param);
         #to_log('run...');
         $srv_cpu{$k}--;
         $srv{$host}--;
      }
   }


}


#------------------------------------------------------------------------
sub remote_run
{
   my ($host,$cpu,$file,$add_param)=@_;
   my $ProcessObj,$dir,$exe,$cmd,$dir_exe;

   ($dir) = $file =~ m/\"?(.*)\\/m;
   if (uc($host) eq 'LOCALHOST') {
      $file =~ s/\"?([^\"]*)\"?/$1/;

      ($exe) = $file =~ m/.*\\([^\\\/]+)$/m;
      $cmd="$exe -cpu$cpu";

      Win32::Process::Create($ProcessObj,$file,
                             $cmd,0,NORMAL_PRIORITY_CLASS,$dir);
   } else {
      ($dir_exe,$exe) = $RemoteRunExe =~ m/(.*)\\([^\\\/]+)$/m;
      $cmd="$exe \\\\$host -d $add_param -a $cpu -w \"$dir\" $file";
      #to_log("cmd=$cmd");

      Win32::Process::Create($ProcessObj,$RemoteRunExe,
                             $cmd,0,NORMAL_PRIORITY_CLASS,$dir_exe);
      $ProcessObj->Wait(INFINITE);
   }
}

#------------------------------------------------------------------------
sub save_submit
{
   my ($err_list,$id_user,$id_prb,$id_cmp,$source_text,$source_file_nm)=@_;
   my %err_hash=(),$rez,$stat_err=0,$i,$fh,@servers;
   my $query,$sth,@arr_q,$id,$id1,$id_stat,$in_file;

   if ($err_list) {
      $err_list =~ s/\s*[\n\r]+\s*//gm;
      %err_hash = split(/\s*:\s*\{(.*?)\}\s*/,$err_list);
      $err_hash{0}="";
   }

   @arr_q=("select id_publ,1 from authors where id_publ=$id_user",
           "select f_submit_prb, (select id_prb from problems where id_prb=$id_prb ) from access_user_prb( $id_user, '.$id_prb.' )",
           "select id_cmp,1 from compil where id_cmp=$id_cmp"
          );

   #проверим юзера,задачу и компилер
   for ($i=0;$i<=$#arr_q && !$stat_err;$i++) {
      $sth=$db->prepare($arr_q[$i]);
      $sth->execute();
      ($id,$id1)=$sth->fetchrow_array;
      $sth->finish();
      $stat_err=$i+1 if (!$id || !$id1);
   }

   if (!$stat_err) {
      $stat_err=4 if (!$source_text && !$incgi->param($source_file_nm));
   }

   if (!$stat_err) {
      $stat_err=5 if ($source_text && $incgi->param($source_file_nm));
   }

   #сохраним посылку
   if (!$stat_err) {
      if ($Options{'AutoStartServer'}) {
         #to_log('start_chk_servers');
         get_runing_servers(\@servers);
         #to_log('servers='.$#servers);
         if ($#servers+1==0) {
            start_servers();
         }
      }
      
      $query="insert into status(id_publ,id_prb,id_cmp,id_rsl) values($id_user,$id_prb,$id_cmp,100)";
      $sth=$db->prepare($query);
      $sth->execute();
      
      $query="select gen_id(status_gen,0) from rdb\$database";
      $sth=$db->prepare($query);
      $sth->execute();
      ($id_stat)=$sth->fetchrow_array;
      $sth->finish;

      $id=sprintf('%x',$id_stat);
      $in_file=$Compilers{$id_cmp}->{'FileIn'};
      $in_file=~s/\$\(id\)/$id/ig;
      $in_file="$DirTempSrc\\".$in_file;
      if ($source_text) {
         $fh=new IO::File;
         $fh->open("> $in_file");
         binmode($fh);
         print $fh $source_text;
         $fh->close();
      } else {
         $i=upload_file($source_file_nm,$in_file);
         if (!$i) {
            $db->rollback;
            $stat_err=4;
         } 
      }

   }

   if (!$stat_err) {
      $db->commit;
   }

   if ($err_list) {
      $rez=$err_hash{$stat_err};
   } else {
      $rez=($stat_err?$stat_err:'').'';
   }

   return $rez;
}

#------------------------------------------------------------------------
sub access_user_prb
{
  my ($user,$prb,$is_get_help) = @_;
  my $query,$sth,$rez;

  if (exists_rec($prb,'problems')) {
     $query="select ".($is_get_help>0?'f_help_prb':'f_edit_prb')." from access_user_prb($user,'.$prb.')";
     $sth = $db->prepare($query);
     $sth->execute;
     ($rez) = $sth->fetchrow_array;
     $sth->finish;
  } else {
     $query="select max(g.f_create_prb) from get_groups_user($user) ggu inner join groups g on ggu.id_grp=g.id_grp";
     $sth = $db->prepare($query);
     $sth->execute;
     ($rez) = $sth->fetchrow_array;
     $sth->finish;
     if (!$rez) {
        $query="select max(f_create_prb) from all_subjs_user($user,0,0)";
        $sth = $db->prepare($query);
        $sth->execute;
        ($rez) = $sth->fetchrow_array;
        $sth->finish;
     }
  }

  return $rez;
}

#------------------------------------------------------------------------
sub access_change_grp_user
{
  my ($user,$mode) = @_;
  my $query,$sth,$rez;

  $rez=2 if (is_manage_system($user));

  if (!$rez) {
     $query="select first 1 id_publ from groups_boss where id_publ=$user";
     $sth = $db->prepare($query);
     $sth->execute;
     ($rez) = $sth->fetchrow_array;
     $sth->finish;
     $rez=1 if ($rez);
  }
  
  return $rez;
}

#------------------------------------------------------------------------
sub is_manage_system
{
  my ($iuser) = @_;
  my $query,$sth,$rez=0;

  $query=<<SQL;
      select max(g.f_mngr_sys)
         from get_groups_user($iuser) ggu inner join groups g
            on ggu.id_grp=g.id_grp
SQL
  $sth = $db->prepare($query);
  $sth->execute;
  ($rez) = $sth->fetchrow_array;
  $sth->finish;

  return $rez;
}

#------------------------------------------------------------------------
sub access_edit_profile
{
  my ($iuser,$ipubl) = @_;
  my $rez=0;

  if ($iuser==$ipubl) {
     $rez=1;
  } elsif (exists_rec($ipubl,'authors')) {
     $rez = is_manage_system($iuser)>0;
  }

  return $rez;
}



return 1;


