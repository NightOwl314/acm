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
    
   $p_id_stat=$incgi->param("id_stat")+0;
   if ($p_id_stat==0) {
      $p_id_stat=2_000_000_000;
   }
   $p_mode=$incgi->param("mode");
   $p_id_view=$incgi->param("id_view")+0;
   $p_id_rsl=$incgi->param("id_rsl")+0;
   $p_filter_rsl=$incgi->param("filter_rsl")+0;
   $p_id_prb=$incgi->param("id_prb")+0;
   $p_id_publ=$incgi->param("id_publ")+0;

   if ($p_mode eq 'report') {
      $fname="report_status_$id_lng.html";
   } else {
      $fname="status_$id_lng.html";
   }

   #откроем шаблон и считаем все строки
   read_file("$DirTemplates\\$fname",\$string_template); 

   if ($p_mode eq 'set_view') {
      set_view($id_user,$p_id_view);
   }

   if ($p_mode eq 'set_rsl') {
      set_result($id_user,$p_id_stat,$p_id_rsl);
      $p_id_stat++;

      $new_url=$ENV{"SCRIPT_URI"}."?id_stat=$p_id_stat";
      print header(-status=>"301 Moved Permanently",
                   -Location=>$new_url);
      next main_cik;
   }

   if ($p_mode ne 'report') {
      if ($p_id_prb>0 && $p_id_publ>0) {
         $string_template =~ s/<!--start_filter-->(.*?)<!--finish_filter-->//si;
         $add_prb_publ="&id_prb=$p_id_prb&id_publ=$p_id_publ";
      } elsif ($p_filter_rsl>0 && $p_id_publ>0) {
         $string_template =~ s/<!--start_filter-->(.*?)<!--finish_filter-->//si;
         $add_prb_publ="&filter_rsl=$p_filter_rsl&id_publ=$p_id_publ";
      } elsif ($p_filter_rsl>0 && $p_id_prb>0) {
         $string_template =~ s/<!--start_filter-->(.*?)<!--finish_filter-->//si;
         $add_prb_publ="&filter_rsl=$p_filter_rsl&id_prb=$p_id_prb";
      } else {
         insert_filter(\$string_template,$id_lng,$id_user);
         $add_prb_publ='';
      }
      $string_template =~ s/\$add_prb_publ/$add_prb_publ/ig;
   }

   #обработаем $insert_rows(d+)
   insert_status_rows(\$string_template,$id_lng,$p_id_stat,$p_id_prb,$id_user,$p_id_publ,$p_filter_rsl);

   if ($p_mode eq 'report') {
      if (insert_report(\$string_template,$id_lng,$p_id_stat,$id_user)==0) {
         $new_url=$ENV{"SCRIPT_URI"};
         print header(-status=>"301 Moved Permanently",
                      -Location=>$new_url);
         next main_cik;
      }
   } else {


   #вставим врем€ обновлени€
   $string_template =~ /\$refresh_basic\s*=\s*\{(.*?)\}/s; 
   $str_basic_refresh = "$1";
   $string_template =~ /\$refresh_active\s*=\s*\{(.*?)\}/s; 
   $str_active_refresh = "$1";

   $param_rf = 0;
   $str_refresh_value = $incgi->param("refresh");
   if ($str_refresh_value eq "") {
      $str_refresh_value = $cookies{"refresh"};
      $find_substr = $str_refresh_value =~ m/\s*refresh\s*=\s*(\w*)/;
      if ($find_substr) {$str_refresh_value = "$1";}
   }
    
   if ($str_refresh_value eq "") {
      $string_template =~ /\$refresh_default\s*=\s*(.*)/; 
      $str_refresh_value = "$1";
   } else {
      $param_rf = 1;
   }  

  #@aaa = ($string_template =~ /(\$refresh_template\(\s*(\w+)\s*\))/g);
  
   while ($string_template =~ /\$refresh_template\(\s*(\S+)\s*\)/) {
      $arg = $1;
      if (($arg eq $str_refresh_value) || ($arg == $str_refresh_value)) {
         $repl = $str_active_refresh;
      } else {
         $repl = $str_basic_refresh;
      } 
      $repl =~ s/\$refresh_arg/$arg/sg;
      $string_template =~ s/\$refresh_template\(\s*\S+\s*\)/$repl/;
   }
  
   if ($str_refresh_value == 0) {$str_refresh_value="x";}
   if ($param_rf == 1) {
      $cookie2 = new CGI::Cookie(-name=>"refresh",-value=>"$str_refresh_value",-path=>"/");
   }  

   $string_template =~ s/\$refresh_time/$str_refresh_value/g;
   
   }

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

#------------------------
#      Functions
#------------------------
sub insert_report
{
   my ($text,$id_lng,$id_stat,$id_user)=@_;
   my $query,$sth,$id_rpt,$id_text,$title,$msg,$msg1,$i,$prb,$rsl,$dsc_err='',$dsc_test='';
   my %pl_hash=(),$s,$sth1,$uname,$cname,$id_publ,$cur_src,$other_src,$test_nm,$color_lang="";
  

   $$text=~s/\$stat_id/$id_stat/ig;
   $$text=~s/\$p1_stat_id/$id_stat+1/eig;
   
   $query="select s.id_stat,s.id_prb,s.id_rsl,s.id_publ,s.test_no,c.color_lang from status s inner join compil c on s.id_cmp=c.id_cmp where s.id_stat=$id_stat";
   $sth = $db->prepare($query);
   $sth->execute;
   ($i,$prb,$rsl,$id_publ,$test_nm,$color_lang)=$sth->fetchrow_array;
   $sth->finish;

   $$text=~s/\$color_lang/$color_lang/ig;

   #проверим есть ли право на просмотр отчета, если решение посылал кто-то другой
   if ($i>0 && $id_user!=$id_publ) {
      $query=<<SQL;
select count(*)
   from get_groups_boss($id_user) ggb
   where ggb.is_boss>0 and exists (select id_grp from get_groups_user($id_publ) where id_grp=ggb.id_grp)
SQL

      $sth=$db->prepare($query);
      $sth->execute();
      ($i) = $sth->fetchrow_array;
      $sth->finish;
   }
 
   #проверим право на просмотр отчета дл€ конкретной задачи, ошибку компил€ции (7) всегда можно посмотреть
   if ($i>0 && $rsl!=7 && $rsl!=0 && $rsl!=9) {
      $query="select f_help_prb from access_user_prb($id_user,'.$prb.')";
      $sth = $db->prepare($query);
      $sth->execute;
      ($i)=$sth->fetchrow_array;
      $sth->finish;
   }


   if ($i>0) {

      $query = <<SQL;
          select r.id_rpt,r.comment, rl.name, sr.text, cast(null as varchar(50)) as text1
             from status_reports sr inner join reports_lng rl on sr.id_rpt=rl.id_rpt and rl.id_lng='$id_lng'
                  inner join reports r on r.id_rpt=sr.id_rpt
          where sr.id_stat=$id_stat and r.id_rpt<>7
          union
          select r.id_rpt,r.comment, rl.name, null as text,
          cast(('id_stat='||s.cmp_id_stat||';id_publ='||s1.id_publ||';proc_not_uniq='||
          cast((100.0-s.uniq_proc) as numeric(10,3))) as varchar(50)) as text1
             from status s, status s1, reports_lng rl, reports r
          where s.id_stat=$id_stat and s.cmp_id_stat is not null and (s.id_rsl=0 or s.id_rsl=9)
            and s1.id_stat=s.cmp_id_stat and r.id_rpt=7 and rl.id_rpt=7 and rl.id_lng='$id_lng'
SQL

      $sth = $db->prepare($query);
      $sth->execute;
      while (($id_rpt,$id_text,$title,$msg,$msg1)=$sth->fetchrow_array) {
         if ($msg=~m/\@sql/s) {$msg="Input...";}
         $id_text=~s/ *$//m;
         $title=~s/ *$//m;
         $$text=~s/\$name_$id_text/$title/sig;
         if ($id_rpt==7) {
            %pl_hash = split(/[; =]+/,$msg1);
            ($s) = $$text=~m/<!--begin_$id_text-->(.*?)<!--end_$id_text-->/si;
            $sth1=$db->prepare("select name from author_names where id_publ=$pl_hash{id_publ}");
            $sth1->execute;
            ($uname)=$sth1->fetchrow_array;
            $sth1->finish;
            $uname=~s/ *$//m;
            html_text(\$uname);
            
            $s=~s/\$p_author_id/$pl_hash{id_publ}/ig;
            $s=~s/\$not_uniq_proc/$pl_hash{proc_not_uniq}/ig;
            $s=~s/\$p_author_name/$uname/ig;
            $$text=~s/<!--begin_$id_text-->(.*?)<!--end_$id_text-->/$s/sig;

            #чужие исходники не показываем юзеру, а показываем только руководителю группы или админу
            if ($id_publ!=$id_user || is_manage_system($id_user)>0) {
            ($s) = $$text=~m/<!--begin_cmp_sources-->(.*?)<!--end_cmp_sources-->/si;

            $sth1=$db->prepare("select name from author_names where id_publ=$id_publ");
            $sth1->execute;
            ($cname)=$sth1->fetchrow_array;
            $sth1->finish;
            $cname=~s/ *$//m;
            html_text(\$cname);
            
            read_file("$DirSrcArh\\".sprintf('%x',$id_stat).".src",\$cur_src);
            html_text(\$cur_src,1);

            read_file("$DirSrcArh\\".sprintf('%x',$pl_hash{id_stat}).".src",\$other_src);
            html_text(\$other_src,1);
            
            $s=~s/\$cur_author_name/$cname/ig;
            $s=~s/\$other_author_name/$uname/ig;

              $s=~s/\$cur_source/$cur_src/ig;
              $s=~s/\$other_source/$other_src/ig;

            $$text=~s/<!--begin_cmp_sources-->(.*?)<!--end_cmp_sources-->/$s/sig;
            }

         } else {           
            #if ($i>0 || ($id_rpt==1 || $id_rpt==8) )
            #{
           if ($id_rpt != 9) {
              html_text(\$msg,1); 
           }

            #  if ($id_rpt==8)
            #  {
            #    read_file("$DirSrcArh\\".sprintf('%x',$id_stat).".otch",\$content);
            #    if ($content eq "") {$content = "Report not found!!!"; }
                #вырезаем из отчета информацию о security violation
            #    $content=~/(SECURITY.*?\<\/table\>)/i;
            #    $msg=$1;
            #  }

              $$text=~s/<!--begin_$id_text-->(.*?)\$text_$id_text(.*?)<!--end_$id_text-->/$1$msg$2/sig;


            #}
            
         }
      }
      $sth->finish;

      $query=<<SQL;
         select description from results_lng where id_rsl=$rsl and id_lng='$id_lng'
SQL
      $sth = $db->prepare($query);
      $sth->execute();
      ($dsc_err)=$sth->fetchrow_array();
      $sth->finish;

      read_file("$DirProblems\\$prb\\".$ProblemPaths{'Tests'}."\\$test_nm.$id_lng",\$dsc_test);
      $dsc_test =~ s/\$img\$/\/cgi-bin\/download.a?mode=get_img_test&id_prb=$prb&test=$test_nm/ig;
   }

   if ($dsc_err) {
      $$text=~s/<!--begin_description-->(.*?)\$description_error(.*?)<!--end_description-->/$1$dsc_err$2/sig;
   }
   if ($dsc_test) {
      $$text=~s/<!--begin_desc_test-->(.*?)\$desc_test(.*?)<!--end_desc_test-->/$1$dsc_test$2/sig;
   }

   $$text=~s/<!--begin_([\w_]*)-->.*?<!--end_\1-->//sig;

   return $i;

}

#------------------------------------------------------------------
sub insert_filter
{
   my ($text,$id_lng,$user) = @_;

   my $text0,$sect_view,$s,$before,$after,$query,$sth,$single_offset,$offset;
   my $pref_grp,$private_name,$all_name,$boss,$sel_view;


   $$text =~ m/<!--start_filter-->(.*?)<!--finish_filter-->/si;
   $text0=$1;

   if ($user>0) {
      $text0 =~ s/<!--start_param_view-->([^\|]*?)\|([^\|]*?)\|([^\|]*?)<!--finish_param_view-->//si;
      $single_offset=$1;
      $private_name=$2;
      $all_name=$3;

      $text0 =~ m/<!--start_view-->(.*?)<!--finish_view-->/si;
      $before=$`;
      $sect_view=$1;
      $after=$';

      $query="select case when view_status is null then -1 else view_status end  from author_names where id_publ=$user";
      $sth=$db->prepare($query);
      $sth->execute();
      ($sel_view) = $sth->fetchrow_array;
      $sth->finish();
   
      $query="select count(*) from groups_boss where id_publ=$user";
      $sth=$db->prepare($query);
      $sth->execute();
      ($boss) = $sth->fetchrow_array;
      $sth->finish();
   
      if ($boss>0 || is_manage_system($user)>0) {
         $query=<<SQL;
select -1 as n_ord, -1 as id, 1 as id_level, cast('$private_name' as char(80)) as name,1 as enbl from rdb\$database
union
select ggb.n_ord, ggb.id_grp as id, ggb.id_level, cast(gl.name as char(80)) as name,ggb.is_boss as enbl
   from get_groups_boss($user) ggb inner join groups_lng gl
      on ggb.id_grp=gl.id_grp and gl.id_lng='$id_lng'
union
select 1000000 as n_ord, -2 as id, 1 as id_level, cast('$all_name' as char(80)) as name,1 as enbl from rdb\$database
SQL
      } else {
          $query=<<SQL;
select -1 as n_ord, -1 as id, 1 as id_level, cast('$private_name' as char(80)) as name,1 as enbl from rdb\$database
union
select 1000000 as n_ord, -2 as id, 1 as id_level, cast('$all_name' as char(80)) as name,1 as enbl from rdb\$database
SQL
      }

      $sth=$db->prepare($query);
      $sth->execute();
   
      while (my @row=$sth->fetchrow_array) {
         $offset=$single_offset x ($row[2]-1);
         $row[3] =~ s/ *$//;

         $s=$sect_view;
         $s =~ s/\$is_selected\$\{(.*?)\|(.*?)\}/$row[1]==$sel_view?$1:$2/eig;
         $s =~ s/\$is_enbl\$\{(.*?)\|(.*?)\}/$row[4]>0?$1:$2/eig;
         $s =~ s/\$view_name/$row[3]/ig;
         $s =~ s/\$offset_view/$offset/ig;

         $row[1]=-1 if ($row[4]==0);
         $s =~ s/\$view_id/$row[1]/ig;

         $before.=$s;
      }
      $sth->finish();

      $text0=$before.$after;
   } else {
      $text0='';
   }

   $$text =~ s/<!--start_filter-->(.*?)<!--finish_filter-->/$text0/si;

}

#--------------------------------------------------------------------
sub set_view
{
   my ($user,$iview) = @_;
   my $query,$sth;
   
   $sth=$db->prepare("update authors set view_status=$iview where id_publ=$user");
   $sth->execute();
   $db->commit;

}

#--------------------------------------------------------------------
sub set_result
{
   my ($id_user,$id_stat,$id_rsl) = @_;
   my $query,$sth,$i,$rsl,$id_publ,$s='';
   
   $query="select s.id_stat,s.id_rsl,s.id_publ from status s where s.id_stat=$id_stat";
   $sth = $db->prepare($query);
   $sth->execute;
   ($i,$rsl,$id_publ)=$sth->fetchrow_array;
   $sth->finish;

   if ($i>0) {
      $query=<<SQL;
select count(*)
   from get_groups_boss($id_user) ggb
   where ggb.is_boss>0 and exists (select id_grp from get_groups_user($id_publ) where id_grp=ggb.id_grp)
SQL
      $sth = $db->prepare($query);
      $sth->execute;
      ($i)=$sth->fetchrow_array;
      $sth->finish;
   }

   if ($i>0 && (($id_publ==$id_user && is_manage_system($id_user)==0) || ($id_rsl!=0 && $id_rsl!=9))) {
      $i=0;
   }

   if ($i>0) {
      #$s=',obj_data=null' if ($id_rsl==9);
      $sth=$db->prepare("update status set id_rsl=$id_rsl,warn_rsl=$id_rsl $s where id_stat=$id_stat");
      $sth->execute();
      #if ($id_rsl==0)  {
      #   $sth=$db->prepare("delete from status_reports where id_stat=$id_stat");
      #   $sth->execute();
      #}

      $db->commit;
   }

}

 


