#!c:\perl\bin\perl.exe

use DBI;
use FCGI;
use IO;
use CGI qw(:standard);
use CGI::Cookie;
use CGI::Carp  qw(fatalsToBrowser);

require 'common_func.pl';
use vars qw($request $db $DirTemp $DirTemplates $incgi %cookies %ENV);


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

   $p_mode=$incgi->param("mode");
   $p_id_prb=$incgi->param("id_prb")+0;
   $p_id_compiler=$incgi->param("id_compiler")+0;
   $p_id_stat=$incgi->param("id_stat")+0;
   $p_source=$incgi->param("source");

   #откроем шаблон и считаем все строки
   read_file("$DirTemplates\\submit_$id_lng.html",\$string_template);

   $err_sect='';

   if ($p_mode eq 'send') {
      $string_template =~ m/<!--start_err-->(.*?)<!--errors(.*?)-->(.*?)<!--finish_err-->/si;
      $err_sect=$1.$3;
      $err_def=$2;
      $err_text=save_submit($err_def,$id_user,$p_id_prb,$p_id_compiler,$p_source,"sourcefile");
      if ($err_text) {
         $err_sect =~ s/\$err_text/$err_text/ig;
      } else {
         sleep(2); #больше половины решений за это время уже проверятся и пользователю не придется обновлять страницу
         $err_sect="";
            
         $new_url=$ENV{"SCRIPT_URI"};
         $new_url =~ s/\?.*$//;
         $new_url =~ s/\/[^\/]*$/\/status.pl/;
         print header(-status=>"301 Moved Permanently",
                      -Location=>$new_url);
         next main_cik;
      }
   } elsif ($p_mode eq 'load_src') {
      load_source($id_user,$p_id_stat,\$p_source,\$p_id_compiler,\$p_id_prb);
   } else {
      last_compil_problem($id_user,\$p_id_compiler,\$p_id_prb);
   }

 
   $string_template =~ s/<!--start_err-->(.*?)<!--finish_err-->/$err_sect/sig;
   if ($p_id_prb) {
      $string_template =~ s/\$problem_id/$p_id_prb/ig;
   } else {
      $string_template =~ s/\$problem_id//ig;
   }
   $string_template =~ s/\$source_text/$p_source/ig;


   #обработаем $include_files(x)
   include_files(\$string_template);

   login_info(\$string_template,$id_user);

   #обработаем $current_page
   current_page(\$string_template);

   #обработаем $insert_compilers
   insert_compilers(\$string_template,$p_id_compiler,$p_id_prb);

   $string_template =~ s/<!--.*?-->//sg;
  
   print header(-charset=>"Windows-1251",
               -cookie=>[$cookie1],
               -cache_control=>"no-cached",
            -pragma=>"no-cache"
               );
   print "$string_template";
}

print "\n";
$db->disconnect;


#------------------------
#      Functions
#------------------------
sub load_source
{
   my ($id_user,$id_stat,$text,$id_cmp,$id_prb) = @_;
   my $query,$sth,$id_publ,$rez;

   if ($id_stat) {
      $query="select id_stat,id_cmp,id_prb,id_publ from status where id_stat=$id_stat";
   } else {
      $query="select first 1 id_stat,id_cmp,id_prb,id_publ from status where id_publ=$id_user and id_rsl<100 order by id_stat desc";
   }
   $sth=$db->prepare($query);
   $sth->execute();
   ($id_stat,$$id_cmp,$$id_prb,$id_publ) = $sth->fetchrow_array;
   $sth->finish;

   if ($id_stat && $id_user!=$id_publ) {
      $query=<<SQL;
select count(*)
   from get_groups_boss($id_user) ggb
   where ggb.is_boss>0 and exists (select id_grp from get_groups_user($id_publ) where id_grp=ggb.id_grp)
SQL

      $sth=$db->prepare($query);
      $sth->execute();
      ($rez) = $sth->fetchrow_array;
      $sth->finish;
      if ($rez==0) {
         $id_stat=0;
         $$id_cmp=0;
         $$id_prb=0;
      }
   }

   if ($id_stat) {
      read_file("$DirSrcArh\\".sprintf('%x',$id_stat).".src",$text);
   }

}

#------------------------------------------------------------------------
sub last_compil_problem
{
   my ($id_user,$id_cmp,$id_prb) = @_;
   my $query,$sth,$rsl,$compil,$prb;

   $query="select first 1 id_cmp,id_prb,id_rsl from status where id_publ=$id_user and id_rsl<100 order by id_stat desc";
   $sth=$db->prepare($query);
   $sth->execute();
   ($compil,$prb,$rsl) = $sth->fetchrow_array;
   $sth->finish;
   $$id_cmp=$compil;
   
   if (!$$id_prb && $rsl!=0) {
      $$id_prb=$prb;
   }

}

 

