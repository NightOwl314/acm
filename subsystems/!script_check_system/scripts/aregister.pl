#!c:\perl\bin\perl.exe

use DBI;
use FCGI;
use IO;
use CGI qw(:standard);
use CGI::Cookie;
use CGI::Carp  qw(fatalsToBrowser);

require 'common_func.pl';
use vars qw($request $in_stream $db $DirTemplates $incgi %cookies %ENV);

  read_config();
  connect_db();
  fcgi_init();

main_cik:
  while(next_request()) {

  $db->commit;
  
  CGI::_reset_globals;
  $incgi = new CGI;
    
  #а может прислали cookies
  %cookies = parse CGI::Cookie($ENV{'HTTP_COOKIE'});

  GetLanguage(\$id_lng,\$cookie1); 

  $p_mode=$incgi->param("mode");
  $p_id_publ=$incgi->param("id_publ")+0;

  if ($p_mode eq 'edit' || $p_mode eq 'edit_post') {
     $id_user=authenticate_process('',"access_edit_profile(\$id_publ,$p_id_publ)")+0;
     next main_cik if (!$id_user);
  } else {
     $id_user=authenticate_process("true");
     next main_cik if ($id_user.'' eq 'end');
  }

  %templ_hash = (new       => "authreg_$id_lng.html",
                 new_post  => "authrequest_$id_lng.html",
                 edit      => "author_edit_$id_lng.html",
                 edit_post => "author_edit_$id_lng.html");
   
  if (!exists $templ_hash{$p_mode}) {
     #по умолчанию создаем нового пользователя
     $p_mode = "new";
  }
  if ($p_mode eq 'new' || $p_mode eq 'new_post') {
     $p_id_publ=0;
  }

  $err_code=0;

  if ($p_mode eq 'new_post' || $p_mode eq 'edit_post') {
     #проверка пароля
     $author_pwd = $incgi->param("author_pwd1");
     $author_pwd2 = $incgi->param("author_pwd2");
     if ($p_mode eq 'new_post' || length($author_pwd)>0 || length($author_pwd2)>0) {
        if ($author_pwd ne $author_pwd2) {
           $err_code=1;
        }

        if (!$err_code && length($author_pwd)<5) {
           $err_code=2;
        }
     }

     if (!$err_code) {
        $country_id = $incgi->param("country")+0;

        $author_name = $incgi->param("author_name");
        $author_name =~ s/ *\Z//;
        $author_name_rz=$author_name;

        $author_login = lc($incgi->param("author_login"));
        $author_login =~ s/ *\Z//;
        
        $author_email = $incgi->param("author_email");
        $add_info = $incgi->param("add_info");

        $sth = $db->prepare("select count(*) from authors where "
                           ."name = '$author_name' and id_publ<>$p_id_publ");
        $sth->execute;
        @row = $sth->fetchrow_array;
        $sth->finish;
        if ($row[0]!=0 || length($author_name)==0) {
           $err_code=3;
        }                                   
     }

     if (!$err_code) {
        $sth = $db->prepare("select count(*) from authors where "
                           ."login = '$author_login' and id_publ<>$p_id_publ");
        $sth->execute;
        @row = $sth->fetchrow_array;
        $sth->finish;
        if ($row[0]!=0 || length($author_login)==0) {
           $err_code=4;
        }                                   
     }

     if (!$err_code) {
        @mas = (\$author_name, \$author_login, \$author_email, \$author_pwd ,\$add_info);
        foreach (@mas) {
           if ($$_ eq "") {
              $$_ = "NULL";
           } else {
              $$_ =~ s/'/''/g;
              $$_ = "'$$_'";
           }
        }

        if ($p_mode eq 'new_post') {
           $query = "INSERT INTO authors(name,login,email,id_cn,pwd,other_info) "
                   ."VALUES ($author_name,$author_login,$author_email,$country_id,$author_pwd,$add_info)";

           $sth = $db->prepare($query);
           $sth->execute();

           $query="select gen_id(authors_gen,0) from rdb\$database";
           $sth=$db->prepare($query);
           $sth->execute();
           ($new_id_publ)=$sth->fetchrow_array;
           $sth->finish;

           $query="insert into groups_authors(id_grp,id_publ) select id_grp, "
                 ."$new_id_publ from groups where default_grp>0";
           $sth=$db->prepare($query);
           $sth->execute();
        }

        if ($p_mode eq 'edit_post') {
           $query = "update authors set name=$author_name,login=$author_login,email=$author_email,"
                   ."id_cn=$country_id,other_info=$add_info"
                   .($author_pwd2?",pwd=$author_pwd":"")." where id_publ=$p_id_publ";

           $sth = $db->prepare($query);
           $sth->execute();
        }

        $db->commit();
     }

     if ($err_code>0) {
        $p_mode='new' if ($p_mode eq 'new_post');
        $p_mode='edit' if ($p_mode eq 'edit_post');
     }
  }
    
  #откроем шаблон и считаем все строки
  $templ_nm = $templ_hash{$p_mode};
  $string_template='';
  read_file("$DirTemplates\\$templ_nm",\$string_template);

  #обработаем $include_files(x)
  include_files(\$string_template);

  $err_sect="";
  if ($err_code>0) {
     $string_template =~ m/<!--start_err-->(.*?)<!--errors(.*?)-->(.*?)<!--finish_err-->/si;
     $err_sect=$1.$3;
     $err_def=$2;
     if ($err_def) {
        $err_def =~ s/\s*[\n\r]+\s*//gm;
        %err_hash = split(/\s*:\s*\{(.*?)\}\s*/,$err_def);
     }
     $err_text=$err_hash{$err_code};
     $err_sect =~ s/\$err_text/$err_text/ig;
  }

  $string_template =~ s/<!--start_err-->(.*?)<!--finish_err-->/$err_sect/sig;

  if ($p_mode eq 'new') {
     insert_countries(\$string_template);
     current_page(\$string_template,$id_user);
     insert_params(\$string_template);
  }

  if ($p_mode eq 'new_post') {
     #login_info(\$string_template,$id_user);
     current_page(\$string_template);
     $string_template =~ s/\$author_name/$author_name_rz/sig;
  }

  if ($p_mode eq 'edit' || $p_mode eq 'edit_post') {
     $query=<<SQL;
     select name,login,email,id_cn,other_info from authors where id_publ=$p_id_publ
SQL
     $sth=$db->prepare($query);
     $sth->execute();
     @a_data=$sth->fetchrow_array;
     $sth->finish;
     
     @a_data = grep ($_=~s/ *\Z//,@a_data);
     
     $string_template =~ s/<!--start_post_edit-->(.*?)<!--finish_post_edit-->//sig if ($p_mode eq 'edit');

     insert_countries(\$string_template,$a_data[3]);
     login_info(\$string_template,$id_user);
     current_page(\$string_template);

     $string_template =~ s/\$author_id/$p_id_publ/sig;
     $string_template =~ s/\$author_name/$a_data[0]/sig;
     $string_template =~ s/\$author_login/$a_data[1]/sig;
     $string_template =~ s/\$author_email/$a_data[2]/sig;
     $string_template =~ s/\$add_info/$a_data[4]/sig;
  }

  #$string_template =~ s/<!--.*?-->//sg;

  print header(-charset=>"Windows-1251",
               -cookie=>[$cookie1],
               -cache_control=>"no-cached",
            -pragma=>"no-cache"
               );
  print "$string_template";

  }
  print "\n";
  #$db->disconnect;
 