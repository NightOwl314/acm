#!c:\perl\bin\perl.exe

use DBI;
use FCGI;
use IO;
use CGI qw(:standard);
use CGI::Cookie;
use CGI::Carp  qw(fatalsToBrowser);
use POSIX;

require 'common_func.pl';
use vars qw($request $db $DirTemplates $DirProblems $incgi %cookies %ENV);

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

   $id_user=authenticate_process("true");
   next main_cik if ($id_user.'' eq 'end');
    
   $p_id_url=$incgi->param("id_url")+0;
   $p_url=$incgi->param("url");
   $p_url=~s/\'/\'\'/g;

   $fname="plain_text_$id_lng.html";

   #откроем шаблон и считаем все строки
   read_file("$DirTemplates\\$fname",\$string_template); 

   #определим имя файла который надо вставить
   if ($p_id_url>0) {
     $cond="id_url=$p_id_url";
   } elsif ($p_url) {
     $cond="url='$p_url'";
   } else {
     $cond="1=0";
   }

   $query="select html_file from valid_urls where $cond";
   $sth=$db->prepare($query);
   $sth->execute();
   ($file_ins) = $sth->fetchrow_array;
   $sth->finish;
   $file_ins=~s/ *$//m;

   if ($file_ins) {
      $file_ins=~s/\$DirTemplates/$DirTemplates/ig;
      $file_ins=~s/\$id_lng/$id_lng/ig;
      
      read_file("$file_ins",\$full_text); 
      #получим заголовок и тело
      ($u_head)=$full_text=~m/<\s*head[^>]*>(.*?)<\s*\/\s*head\s*>/si;
      ($u_title)=$u_head=~m/<\s*title[^>]*>(.*?)<\s*\/\s*title\s*>/si;
      ($u_body)=$full_text=~m/<\s*body[^>]*>(.*?)<\s*\/\s*body\s*>/si;
   } else {
      print header(-status=>'301 Moved Permanently',
                   -Location=>'/');
      next main_cik;
   }

   $string_template =~ s/\$u_title/$u_title/ig;
   $string_template =~ s/\$u_body/$u_body/ig;

   #обработаем $include_files(x)
   include_files(\$string_template);

   login_info(\$string_template,$id_user);

   #обработаем $current_page
   current_page(\$string_template);

   $string_template =~ s/<!--.*?-->//sg;
 
   print header(-charset=>"Windows-1251",
               -cookie=>[$cookie1,$cookie2],
               -cache_control=>"no-cached",
               -pragma=>"no-cache"
            );

   print "$string_template";

}

print "\n";
$db->disconnect;
POSIX:_exit(0);