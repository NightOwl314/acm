#!c:\perl\bin\perl.exe

use DBI;
use FCGI;
use IO;
use CGI qw(:standard);
use CGI::Cookie;
use File::Path;
use File::Copy;
use CGI::Carp  qw(fatalsToBrowser);

require 'common_func.pl';

use vars qw($request $db $DirTemplates $DirTemp $DirStdCheckers $DirPrbCond $DirProblems
            %ProblemPaths $incgi %cookies %ENV);


read_config();
connect_db();

fcgi_init();

main_cik:
while(next_request()) {

   to_log("request from user");

   $db->commit();


   CGI::_reset_globals;
   $incgi = new CGI;
   
   #а может прислали cookies
   %cookies = parse CGI::Cookie($ENV{'HTTP_COOKIE'});

   $p_mode=$incgi->param("mode");
   $p_id_chk=$incgi->param("id_chk")+0;
   $p_id_prb=$incgi->param("id_prb")+0;

   $id_user=authenticate_process("","access_user_prb(\$id_publ,$p_id_prb)")+0;
   if (!$id_user) { next main_cik; }
   
   
   $id_lng='';
   GetLanguage(\$id_lng,\$cookie1); 

   $p_test_name=$incgi->param("test_name");
   $p_test_name='' if !($p_test_name =~ m/[0-9a-zA-Z_]+/) || $& ne $p_test_name;
   
   $p_test_old_name=$incgi->param("test_old_name");
   $p_test_old_name='' if !($p_test_old_name =~ m/[0-9a-zA-Z_]+/)  || $& ne $p_test_old_name;
   
   %templ_hash = (new         => "add_problem_$id_lng.html",
                  new_post    => "add_problem_$id_lng.html",
                  get_src_chk => "chk_view_$id_lng.html",
                  edit        => "edit_problem_$id_lng.html",
                  edit_post   => "edit_problem_$id_lng.html",
                  edit_test   => "edit_test_$id_lng.html",
                  new_test    => "edit_test_$id_lng.html",
                  edit_test_post=> "edit_test_$id_lng.html");
   
   if (!exists $templ_hash{$p_mode}) {
      #по умолчанию добавляем новую задачу
      $p_mode = exists_rec($p_id_prb,'problems')?"edit":"new";
   }
   if ($p_mode eq "edit_test" && !$p_test_name) {
      $p_mode="new_test";
   }
   
   if (exists_rec($p_id_prb,'problems')) {
      if (!($p_mode eq "edit" || $p_mode eq "edit_post" || $p_mode eq "edit_test" || 
          $p_mode eq "new_test" || $p_mode eq "edit_test_post") ) {
         $p_mode="edit";
      }
   } else {
      if (($p_mode eq "edit" || $p_mode eq "edit_post" || $p_mode eq "edit_test" || 
          $p_mode eq "new_test" || $p_mode eq "edit_test_post") ) {
         $p_mode="new";
      }
   }

   
   $templ_nm = $templ_hash{$p_mode};

   #откроем шаблон и считаем все строки
   $string_template='';
   read_file("$DirTemplates\\$templ_nm",\$string_template);

   if ($p_mode eq "new" || $p_mode eq "new_post") {
      $err_sect="";
      if ($p_mode eq "new_post") {
         $string_template =~ m/<!--start_err-->(.*?)<!--errors(.*?)-->(.*?)<!--finish_err-->/si;
         $err_sect=$1.$3;
         $err_def=$2;
         $num_prb=0;
         $err_text=save_problem($err_def,$id_user,\$num_prb);
         if ($err_text) {
            $err_sect =~ s/\$err_text/$err_text/ig;
         } else {
            $err_sect="";
            
            $new_problem_url=$ENV{"SCRIPT_URI"};
            $new_problem_url =~ s/\?.*$//;
            $new_problem_url =~ s/\/[^\/]*$/\/arh_problems.pl?id_prb=$num_prb/;
            to_log($new_problem_url);
            #добавилось без ошибок переходим на страницу с новой задачей
            print header(-status=>"301 Moved Permanently",
                         -Location=>$new_problem_url);
            next main_cik;
         }
      }
      $string_template =~ s/<!--start_err-->(.*?)<!--finish_err-->/$err_sect/sig;

      if ($p_mode eq "new") {
         $incgi->param(-name=>'time_limit',-value=>'1.000');
         $incgi->param(-name=>'mem_limit',-value=>'1000');
         $incgi->param(-name=>'min_uniq_proc',-value=>'30');
      }

      insert_languages_p(\$string_template,$id_lng);
      insert_subjects_p(\$string_template,$id_lng,0,$id_user);
      insert_checkers_p(\$string_template,$id_lng);
      insert_compilers(\$string_template);
      insert_params(\$string_template);

   } elsif ($p_mode eq "get_src_chk") {
      insert_src_chk_p(\$string_template,$id_lng,$p_id_chk);

   } elsif ($p_mode eq "edit_test" || $p_mode eq "new_test" || $p_mode eq "edit_test_post") {

      if ($p_mode eq "edit_test_post") {
         if (!save_test($p_id_prb,$p_test_old_name,$p_test_name)) {
            print_err("invalid test name");
         } else {
            $new_url=$ENV{"SCRIPT_URI"};
            $new_url =~ s/\?.*$//;
            $new_url.="?mode=edit_test&id_prb=$p_id_prb&test_name=$p_test_name";
            print header(-status=>"301 Moved Permanently",
                         -Location=>$new_url);
         }
         next main_cik;
      }
      insert_single_test_p(\$string_template,$p_id_prb,$p_test_name,$p_mode eq "new_test",$id_lng);

   } elsif ($p_mode eq "edit" || $p_mode eq "edit_post") {
      
      $err_sect="";
      if ($p_mode eq "edit_post") {
         $string_template =~ m/<!--start_err-->(.*?)<!--errors(.*?)-->(.*?)<!--finish_err-->/si;
         $err_sect=$1.$3;
         $err_def=$2;
         
         $num_prb=$p_id_prb;
         $err_text=save_problem($err_def,$id_user,\$num_prb);
         
         if ($err_text) {
            $err_sect =~ s/\$err_text/$err_text/ig;
         } else {
            $string_template =~ s/<!--start_post_edit-->(.*?)<!--finish_post_edit-->/$1/sig;
            $err_sect="";
         }
      }
      $string_template =~ s/<!--start_post_edit-->(.*?)<!--finish_post_edit-->//sig;

      $string_template =~ s/<!--start_err-->(.*?)<!--finish_err-->/$err_sect/sig;

      $string_template =~ s/\$id_problem/$p_id_prb/sig;

      insert_languages_p(\$string_template,$id_lng,$p_id_prb);
      insert_subjects_p(\$string_template,$id_lng,$p_id_prb,$id_user);
      insert_tests_p(\$string_template,$p_id_prb);
      insert_limits_p(\$string_template,$p_id_prb);
      insert_size_files_p(\$string_template,$p_id_prb);

      insert_compilers(\$string_template);

   }

   #обработаем $include_files(x)
   include_files(\$string_template);

   login_info(\$string_template,$id_user);

   #обработаем $current_page
   current_page(\$string_template);


   print header(-charset=>"Windows-1251",
               -cookie=>[$cookie1],
               -cache_control=>"no-cached",
               -pragma=>"no-cache"
               );
    
    
   print "$string_template";

}

print "\n";
$db->disconnect() or print $db->errstr;


#------------------------
#      Functions
#------------------------

sub insert_languages_p
{
   my ($text,$id_lng,$id_problem) = @_;
   
   my $sect_lng,$s,$before,$after,$i,$query,$fln,$cond_size;

   $$text =~ m/<!--start_lang-->(.*?)<!--finish_lang-->/si;
   $before=$`;
   $sect_lng=$1;
   $after=$';

   if ($id_problem) {
      $query="select l.id_lng, ll.name, p.name from langs l left outer join langs_lng ll ".
             "on l.id_lng=ll.id_lng2 and ll.id_lng1='$id_lng' ".
             "left outer join problems_lng p on l.id_lng=p.id_lng and p.id_prb=$id_problem";
   } else {
      $query="select l.id_lng, ll.name from langs l left outer join langs_lng ll ".
             "on l.id_lng=ll.id_lng2 and ll.id_lng1='$id_lng'";
   }

   my $sth=$db->prepare($query);
   $sth->execute();
   
   $i=0;
   while (my @row=$sth->fetchrow_array) {
      $s=$sect_lng;
      $s =~ s/\$i_id_lang/$row[0]/ig;
      $s =~ s/\$i_lang_name/$row[1]/ig;
      if ($id_problem) {
         $row[2] =~ s/ *$//;
         $s =~ s/\$title_prb_lang/$row[2]/ig;

         #размер условия
         $fln=$ProblemPaths{'ArchivCondName'};
         $fln =~ s/\$lang/$row[0]/ig;
         $fln="$DirProblems\\$id_problem\\".$fln;
         if (!-e($fln) || (stat($fln))[9]<(stat("$DirPrbCond\\$id_problem\\$row[0]\\index.html"))[9]) {
            re_pack($fln,"$DirPrbCond\\$id_problem\\$row[0]\\*");
         }
         $cond_size=format_size((stat($fln))[7]);
         $s =~ s/\$cond_size/$cond_size/ig;
      }

      if ($i>0) {
         $s =~ s/<!--start_one_help_lng-->(.*?)<!--finish_one_help_lng-->//sig;
      }
      $before.=$s;
      $i++;
   }
   $sth->finish();

   $$text=$before.$after;
}

#------------------------------------------------------------------------
sub insert_subjects_p
{
   my ($text,$id_lng,$id_problem,$user) = @_;
   
   my $sect_subj,$s,$before,$after,$offset,$query,$single_offset;

   $$text =~ s/<!--start_offset_tema-->(.*?)<!--finish_offset_tema-->//mi;
   $single_offset=$1;

   $$text =~ m/<!--start_tema-->(.*?)<!--finish_tema-->/si;
   $before=$`;
   $sect_subj=$1;
   $after=$';

   if ($id_problem) {
      $query=<<SQL;
      select tree.id_tm,tree.id_level,max(tree.is_enbl),tl.name,tp.id_prb 
         from get_change_subjs_user($user) tree 
            left outer join tema_lng tl on tree.id_tm=tl.id_tm and tl.id_lng='$id_lng' 
            left outer join tm_prb tp on tree.id_tm=tp.id_tm and tp.id_prb=$id_problem
         group by tree.n_ord,tree.id_tm,tree.id_level,tl.name,tp.id_prb
         order by tree.n_ord
SQL
   } else {
      $query=<<SQL;
      select tree.id_tm,tree.id_level,max(tree.is_enbl),tl.name 
         from get_change_subjs_user($user) tree left outer join tema_lng tl
              on tree.id_tm=tl.id_tm and tl.id_lng='$id_lng'
         group by tree.n_ord,tree.id_tm,tree.id_level,tl.name
         order by tree.n_ord
SQL
   }

   my $sth=$db->prepare($query);
   $sth->execute();
   
   while (my @row=$sth->fetchrow_array) {
      $offset=$single_offset x ($row[1]-1);
      $row[3] =~ s/ *$//;

      $s=$sect_subj;
      $s =~ s/\$id_tema/$row[0]/ig;
      $s =~s/\$is_enbl\$\{(.*?)\|(.*?)\}/$row[2]>0?$1:$2/eig;
      $s =~ s/\$title_tema/$row[3]/ig;
      $s =~ s/\$offset_tema/$offset/ig;
      
      if ($id_problem) {
         $s =~ s/\$tema_selected\{([^\}]*)\}/$row[4]?$1:''/eig;
      }

      $before.=$s;
   }
   $sth->finish();

   $$text=$before.$after;
}

#------------------------------------------------------------------------
sub insert_checkers_p
{
   my ($text,$id_lng) = @_;
   
   my $sect_chk,$s,$before,$after,$query,$sth;

   $$text =~ m/<!--start_checker-->(.*?)<!--finish_checker-->/si;
   $before=$`;
   $sect_chk=$1;
   $after=$';

   $query="select id_chk, name from standart_checkers_lng where id_lng='$id_lng'";

   $sth=$db->prepare($query);
   $sth->execute();
   
   while (my @row=$sth->fetchrow_array) {
      $s=$sect_chk;
      $s =~ s/\$chk_id/$row[0]/ig;
      $s =~ s/\$chk_name/$row[1]/ig;
      $before.=$s;
   }
   $sth->finish();

   $$text=$before.$after;
}

#------------------------------------------------------------------------
sub insert_src_chk_p
{
   my ($text,$id_lng,$id_chk) = @_;
   my $rez=1,$source_text="",$chk_name="";
   my $query="select chk.file_name_src,chkl.name ".
             " from standart_checkers chk inner join standart_checkers_lng chkl on chk.id_chk=chkl.id_chk ".
             " where chk.id_chk=$id_chk and chkl.id_lng='$id_lng'";

   my $sth=$db->prepare($query);
   $sth->execute();
   if (my @row=$sth->fetchrow_array) {
      read_file("$DirStdCheckers\\$row[0]",\$source_text);
      html_text(\$source_text);
      $chk_name=$row[1];
   } else { $rez=0; }
   
   $sth->finish();

   $$text =~ s/\$chk_name/$chk_name/ig;
   $$text =~ s/\$source_text/$source_text/ig;

   return $rez;
}

#------------------------------------------------------------------------
sub save_problem
{
   my ($err_list,$id_user,$ptr_id_prb)=@_;
   my $cond_p='cond_file_',$tests_p='tests_file';
   
   my $i_id_lng,%titles=(),%conds=(),%conds_files=(),$stat_err=0,$single_cond="";
   my $i,%err_hash=(),$ctype,$uniq_part,$fln,@subjs=(),$tests_file,$tests_dir;
   my $fl_lst,$list_tests_fn,$std_checker,$checker_file_exe,$checker_file_scr,$chk_compil,$id_compil;
   my @del_files=(),$time_limit,$mem_limit,$new_id_prb,@row,$valid_solve,$user_sbm;
   my $s,%enbl_tests=(),@set=(),$min_uniq_proc,@exts=('in','out','img');

   $uniq_part=(int( rand(899_999_999))+100_000_000).'';

   $err_list =~ s/\s*[\n\r]+\s*//gm;
   %err_hash = split(/\s*:\s*\{(.*?)\}\s*/,$err_list);
   $err_hash{0}="";

   my $query="select id_lng from langs";

   my $sth=$db->prepare($query);
   $sth->execute();
   
   #получает названия и условия
   while (@row=$sth->fetchrow_array) {
      $i_id_lng=$row[0];
      push(@exts,$i_id_lng);
      $titles{$i_id_lng} = $incgi->param("title_prb_$i_id_lng");

      $v=$incgi->param("$cond_p$i_id_lng");

      if ($$ptr_id_prb) {
         $conds{$i_id_lng} = $v if $v;
      } else {
         $conds{$i_id_lng} = $v;
      
         if ($conds{$i_id_lng} && $incgi->param("single_cond_$i_id_lng") ) {
            $single_cond=$i_id_lng;
         }
      }
   }
   $sth->finish();
   
   if ($single_cond) {
      for (values %conds) {
         $_= $conds{$single_cond} ;
      }
   }
   
   #проверка наличия всех названий
   for (values %titles) {
      $stat_err=1 if (!$_);
   }

   #проверка уникальности названий
   if (!$stat_err) {
      while (my ($k,$v) = each %titles) {
         $v=uc($v);
         $v =~ s/\'/\'\'/g;
         
         if ($$ptr_id_prb) {
            $query="select count(*) from problems_lng where id_lng='$k' and upper(name)='$v' and id_prb<>$$ptr_id_prb";
         } else {
            $query="select count(*) from problems_lng where id_lng='$k' and upper(name)='$v'";
         }

         $sth=$db->prepare($query);
         $sth->execute();
         ($i)=$sth->fetchrow_array;
         $sth->finish();
         if ($i>0) {
            $stat_err=2;
            $err_hash{2} =~ s/\$not_unique_title/$titles{$k}/ig;
            last;
         }
      }
   }

   #проверка наличия всех условий
   if (!$stat_err) {
      for (values %conds) {
         $stat_err=3 if (!$_);
      }
   }
   
   #проверка корректности всех условий
   if (!$stat_err) {
      foreach $k (keys %conds) {
         $v=$cond_p.($single_cond?$single_cond:$k);
         $fln="$cond_p$uniq_part$k";

         $i=upload_file($v,"$DirTemp\\$fln.fl");
         push(@del_files,"$DirTemp\\$fln.fl");
         
         if ($i) {
            $ctype=$incgi->uploadInfo($conds{$k})->{'Content-Type'};
            #to_log("ctype = $ctype");
            if ($ctype eq 'text/html') {
               $conds_files{$k}="$DirTemp\\$fln.fl";
            } else {
               $i=un_pack("$DirTemp\\$fln.fl","$DirTemp\\$fln.dir\\");
               push(@del_files,"$DirTemp\\$fln.dir");
               $conds_files{$k}="$DirTemp\\$fln.dir";

               $i=0 unless (-e "$DirTemp\\$fln.dir\\index.html");
            }
         }

         if (!$i) {
            $stat_err=4;
            $err_hash{4} =~ s/\$file/$conds{$k}/ig;
            last;
         }
      }
   }
   
   #проверка тем
   if (!$stat_err) {
      @subjs=$incgi->param("tema_list");
      @subjs = grep ($_+=0,@subjs);

      $s=join(',',0,@subjs);

      $i=$$ptr_id_prb+0;
      $query=<<SQL;
select tree.id_tm
   from get_change_subjs_user($id_user) tree left outer join tm_prb tp
      on tree.id_tm=tp.id_tm and tp.id_prb=$i
   group by tree.id_tm,tp.id_tm
   having (tree.id_tm in ($s) and max(tree.is_enbl)>0) or
          (tp.id_tm is not null and max(tree.is_enbl)=0)
SQL
      $sth=$db->prepare($query);
      $sth->execute();
      
      @subjs=();
      while(($i)=$sth->fetchrow_array) {
         push(@subjs,($i));
      }
      $sth->finish();
      $s=join(',',0,@subjs);
      
      
      $query="select count(*) from  tema where id_tm in ($s)";
      $sth=$db->prepare($query);
      $sth->execute();
      ($i)=$sth->fetchrow_array;
      $sth->finish();
      
      $stat_err=5 if ($i==0 || $i != $#subjs+1);

#      $i=$$ptr_id_prb+0;
#      $query=<<SQL;
#      select t.id_tm
#         from tema t left outer join tm_prb tp on t.id_tm=tp.id_tm and tp.id_prb=$i
#         where (tp.id_tm is not null or t.id_tm in ($s)) and
#           not (tp.id_tm is not null and t.id_tm in ($s))
#SQL
#      $sth=$db->prepare($query);
#      $sth->execute();
#      
#      while(($i)=$sth->fetchrow_array) {
#         push(@set,($i));
#      }
#      $sth->finish();
#      $s=join(',',0,@set);
#
#      to_log("s=$s");
#
#      $query=<<SQL;
#      select id_tm from get_change_subjs_user($id_user)
#         group by id_tm
#         having max(is_enbl)=0 and id_tm in ($s)
#SQL
#      $sth=$db->prepare($query);
#      $sth->execute();
#      ($i)=$sth->fetchrow_array;
#      $sth->finish();
#      
#      $stat_err=5 if ($i);
   }

   #проверка наличия архива тестов
   if (!$stat_err) {
      $tests_file=$incgi->param($tests_p);
      $stat_err=6 if (!$tests_file && !($$ptr_id_prb) );
   }

   #проверка тестов (только при редактировании)
   if (!$stat_err && $$ptr_id_prb && !$tests_file) {
      $i=0;
      $fln="$DirProblems\\$$ptr_id_prb\\".$ProblemPaths{'ListTests'};
      $fl_lst=new IO::File;
      $fl_lst->open("< $fln");
      while (<$fl_lst>) {
         chomp; 
         s/^\$//;
         $enbl_tests{$_} = $incgi->param("single_test_$_")+0;
         $i++ if $enbl_tests{$_};
      }
      $fl_lst->close();
      
      $stat_err=12 unless $i;
   }

   #проверка корректности архива тестов
   if (!$stat_err && $tests_file) {
      $fln=$tests_p.'_'.$uniq_part;
      $i=upload_file($tests_p,"$DirTemp\\$fln.fl");
      push(@del_files,"$DirTemp\\$fln.fl");
      
      if ($i) {
         $tests_dir="$DirTemp\\$fln.dir";

         $i=un_pack("$DirTemp\\$fln.fl","$tests_dir\\","true");
         push(@del_files,$tests_dir);

         $list_tests_fn="$tests_dir\\".$ProblemPaths{'ListTests'};
         if ($i && -e $list_tests_fn) {
            $i=0;
            $fl_lst=new IO::File;
            $fl_lst->open("< $list_tests_fn");
            while (<$fl_lst>) {
               chomp; 
               s/^\$//;
               
               #to_log("$DirTemp\\$fln.dir\\$_.in");
               if (!(m/[a-zA-Z0-9_]+/) || !(-e "$tests_dir\\$_.in") || !(-e "$tests_dir\\$_.out")) {
                  $i=0;
                  last;
               }
               $i++;
            }
            $fl_lst->close();
         } else {
           $i=0;
         }
      }

      $stat_err=7 unless $i;
   }

   #проверка ограничения по времени
   if (!$stat_err) {
      $time_limit=int(($incgi->param('time_limit')+0.000)*1000)/1000;
      $stat_err=8 unless $time_limit>=0.001;
   }

   #проверка ограничения по памяти
   if (!$stat_err) {
      $mem_limit=int($incgi->param('mem_limit')+0);
      $stat_err=9 unless $mem_limit>0;
   }

   #проверка ограничения по уникальности
   if (!$stat_err) {
      $min_uniq_proc=int($incgi->param('min_uniq_proc')+0);
      $stat_err=13 unless ($min_uniq_proc>=0 && $min_uniq_proc<=100);
   }

   #проверка выбора чекера
   if (!$stat_err) {
      if ($$ptr_id_prb) {
         $std_checker=-1;
      } else {
         $std_checker=$incgi->param("standart_checker")+0;
      }

      if ($std_checker==-1) {
         $checker_file_exe=$incgi->param("checker_file");
         if ($checker_file_exe) {
            $i=upload_file("checker_file","$DirTemp\\checker_$uniq_part.fl");
            push(@del_files,"$DirTemp\\checker_$uniq_part.fl");
            
            if ($i) {
               $checker_file_exe="$DirTemp\\checker_$uniq_part.fl";
            } else {
               $checker_file_exe="";
            }
         }
      } else {
         $query="select file_name_bin,file_name_src from standart_checkers where id_chk=$std_checker";
         $sth=$db->prepare($query);
         $sth->execute();
         @row=$sth->fetchrow_array;
         $sth->finish();
         if ($row[0]) {
            $checker_file_exe="$DirTemp\\checker_$uniq_part.exe";
            copy("$DirStdCheckers\\$row[0]",$checker_file_exe);
            push(@del_files,$checker_file_exe);
         } else {
            $checker_file_exe='';
         }
         if ($row[1]) {
            $checker_file_src="$DirTemp\\checker_$uniq_part.src";
            copy("$DirStdCheckers\\$row[1]",$checker_file_src);
            push(@del_files,$checker_file_src);
         } else {
            $checker_file_src='';
         }
      }

      $stat_err=10 if (!-e($checker_file_exe) && !($$ptr_id_prb));
   }

   #компиляция чекера (если нужно)
   if (!$stat_err && $std_checker==-1 && $checker_file_exe) {
      $chk_compil=$incgi->param('chk_compil_src')+0;
      $id_compil=$incgi->param('chk_compiler_id')+0;
      if ($chk_compil && $id_compil) {
         $checker_file_src=$checker_file_exe;
         $checker_file_exe=compiling_file($checker_file_src,$id_compil,\$i);

         if (!$checker_file_exe) {
            $stat_err=11;
            $err_hash{11} =~ s/\$compil_output/$i/ig;
         } else {
            push(@del_files,$checker_file_exe);
         }
      }
   }


   #теперь все проверили
   #сохраняем изменения при редактировании
   if (!$stat_err && $$ptr_id_prb) {
      #сохраним ограничения
      $query="update problems set time_lim=$time_limit, mem_lim=$mem_limit, "
            ."min_uniq_proc=$min_uniq_proc where id_prb = $$ptr_id_prb";
      $sth=$db->prepare($query);
      $sth->execute();

      #сохраним названия
      $query="delete from problems_lng where id_prb = $$ptr_id_prb";
      $sth=$db->prepare($query);
      $sth->execute();

      #$query="update problems_lng set name = ? where id_prb = $$ptr_id_prb and id_lng = ?";
      $query="insert into problems_lng(id_prb,id_lng,name) values($$ptr_id_prb,?,?)";
      $sth=$db->prepare($query);
      foreach $k (keys %titles) {
         #$sth->execute($titles{$k},$k);
         $sth->execute($k,$titles{$k});
      }

      #сохраним темы
      $query="delete from tm_prb where id_prb = $$ptr_id_prb";
      $sth=$db->prepare($query);
      $sth->execute();

      $query="insert into tm_prb(id_tm,id_prb) values(?,$$ptr_id_prb)";
      $sth=$db->prepare($query);
      foreach $k (@subjs) {
         $sth->execute($k);
      }
      
      $db->commit();

      #сохраним условия
      if (!-d "$DirPrbCond\\$$ptr_id_prb") {
         mkdir("$DirPrbCond\\$$ptr_id_prb");
      }

      foreach $k (keys %conds_files) {
         $v=$conds_files{$k};
         $fln="$DirPrbCond\\$$ptr_id_prb\\$k";
         rmtree([$fln],0,1);
         if (-d $v) {
            rename($v,$fln);
         } else {
            mkdir($fln);
            rename($v,"$fln\\index.html");
         }
         $s=$ProblemPaths{'ArchivCondName'};
         $s =~ s/\$lang/$k/ig;
         re_pack("$DirProblems\\$$ptr_id_prb\\$s",
                 "$fln\\*");
      }

      #сохраним тесты если указан архив тестов
      if ($tests_file) {
         unlink("$DirProblems\\$$ptr_id_prb\\".$ProblemPaths{'ListTests'});

         $fln="$DirProblems\\$$ptr_id_prb\\".$ProblemPaths{'Tests'};
         rmtree([$fln],0,1);
         mkdir($fln);

         $fl_lst=new IO::File;
         $fl_lst->open("< $list_tests_fn");
         while (<$fl_lst>) {
            chomp;
            s/^\$//; 
            $v=$_;
            foreach $k (@exts) {
               rename("$tests_dir\\$v.$k","$fln\\$v.$k");
            }
         }
         $fl_lst->close();
         rename($list_tests_fn,"$DirProblems\\$$ptr_id_prb\\".$ProblemPaths{'ListTests'});

         #запакуем все тесты в архив
         grep($_="$DirProblems\\$$ptr_id_prb\\".$ProblemPaths{'Tests'}."\\*.$_",@exts);
         re_pack("$DirProblems\\$$ptr_id_prb\\".$ProblemPaths{'ArchivTestsName'},
                 "$DirProblems\\$$ptr_id_prb\\".$ProblemPaths{'ListTests'},@exts);
      }

      #сохраняем включенные тесты, если неуказан архив тестов
      if (!$tests_file) {
         $fln="$DirProblems\\$$ptr_id_prb\\".$ProblemPaths{'ListTests'};
         $s='';
         $fl_lst=new IO::File;
         $fl_lst->open("< $fln");
         while (<$fl_lst>) {
            chomp; 
            s/^\$//;
            $s.= ($enbl_tests{$_}?'':'$').$_."\n";
         }
         $fl_lst->close();
         
         $fl_lst->open("> $fln");
         print $fl_lst $s;
         $fl_lst->close();
      }

      #сохраним проверяющую программу
      if ($checker_file_exe) {
         $fln="$DirProblems\\$$ptr_id_prb\\";
         unlink($fln.$ProblemPaths{'WrongAnswerPrg'});
         unlink($fln.$ProblemPaths{'WrongAnswerSrc'});

         rename($checker_file_exe,$fln.$ProblemPaths{'WrongAnswerPrg'});
         if ($checker_file_src) {
            rename($checker_file_src,$fln.$ProblemPaths{'WrongAnswerSrc'});
         }
      }
   }

   
   #теперь все проверили
   #вносим задачу в базу для новой задачи
   if (!$stat_err && !($$ptr_id_prb)) {
      #сохраним ограничения
      $query="insert into problems(time_lim,mem_lim,id_creator,min_uniq_proc) "
            ."values($time_limit,$mem_limit,$id_user,$min_uniq_proc)";
      $sth=$db->prepare($query);
      $sth->execute();

      #определим идентификатор новой задачи
      $query="select gen_id(problems_gen,0) from rdb\$database";
      $sth=$db->prepare($query);
      $sth->execute();
      ($new_id_prb)=$sth->fetchrow_array;
      $sth->finish;

      #сохраним названия
      $query="insert into problems_lng(id_prb,id_lng,name) values($new_id_prb,?,?)";
      $sth=$db->prepare($query);
      foreach $k (keys %titles) {
         $sth->execute($k,$titles{$k});
      }

      #сохраним темы
      $query="insert into tm_prb(id_tm,id_prb) values(?,$new_id_prb)";
      $sth=$db->prepare($query);
      foreach $k (@subjs) {
         $sth->execute($k);
      }
      $db->commit();

      #сохраним условия
      mkdir("$DirPrbCond\\$new_id_prb");
      foreach $k (keys %conds_files) {
         $v=$conds_files{$k};
         $fln="$DirPrbCond\\$new_id_prb\\$k";
         rmtree([$fln],0,1);
         if (-d $v) {
            rename($v,$fln);
         } else {
            mkdir($fln);
            rename($v,"$fln\\index.html");
         }
         $s=$ProblemPaths{'ArchivCondName'};
         $s =~ s/\$lang/$k/ig;
         re_pack("$DirProblems\\$new_id_prb\\$s",
                 "$fln\\*");
      }

      #сохраним тесты
      mkdir("$DirProblems\\$new_id_prb");

      $fln="$DirProblems\\$new_id_prb\\".$ProblemPaths{'Tests'};
      mkdir($fln);

      $fl_lst=new IO::File;
      $fl_lst->open("< $list_tests_fn");
      while (<$fl_lst>) {
         chomp;
         s/^\$//;
         $v=$_;
         foreach $k (@exts) {
            rename("$tests_dir\\$v.$k","$fln\\$v.$k");
         }
      }
      $fl_lst->close();
      rename($list_tests_fn,"$DirProblems\\$new_id_prb\\".$ProblemPaths{'ListTests'});

      #запакуем все тесты в архив
      grep($_="$DirProblems\\$new_id_prb\\".$ProblemPaths{'Tests'}."\\*.$_",@exts);
      re_pack("$DirProblems\\$new_id_prb\\".$ProblemPaths{'ArchivTestsName'},
              "$DirProblems\\$new_id_prb\\".$ProblemPaths{'ListTests'},@exts);

      #сохраним проверяющую программу
      rename($checker_file_exe,"$DirProblems\\$new_id_prb\\".$ProblemPaths{'WrongAnswerPrg'});
      if ($checker_file_src) {
         rename($checker_file_src,"$DirProblems\\$new_id_prb\\".$ProblemPaths{'WrongAnswerSrc'});
      }

      $$ptr_id_prb=$new_id_prb;

      #посылаем "верное" решение на проверку
      $valid_solve=$incgi->param("source_file");
      $id_compil=$incgi->param("slv_compiler_id");
      if ($valid_solve && $id_compil) {
         $i=save_submit('',$id_user,$new_id_prb,$id_compil,'','source_file');

      }

   }


   #удаление всех временных файлов и каталогов
   rmtree(\@del_files,0,1);

   return $err_hash{$stat_err};
}


#------------------------------------------------------------------------
sub insert_tests_p
{
   my ($text,$id_problem) = @_;
   
   my $sect_test,$s,$before,$after,$tests_dir,$fl_lst,$checked,$size;

   $$text =~ m/<!--start_single_test-->(.*?)<!--finish_single_test-->/si;
   $before=$`;
   $sect_test=$1;
   $after=$';

   $tests_dir="$DirProblems\\$id_problem\\".$ProblemPaths{'Tests'};
   $fl_lst=new IO::File;
   $fl_lst->open("< $DirProblems\\$id_problem\\".$ProblemPaths{'ListTests'});
   while (<$fl_lst>) {
      $s=$sect_test;
      chomp;
      $checked = (s/^\$//)?'':'checked';
      $s =~ s/\$test_checked/$checked/ig;
      $s =~ s/\$test_name/$_/ig;

      $size=format_size((stat("$tests_dir\\$_.in"))[7]+(stat("$tests_dir\\$_.out"))[7]);
      
      $s =~ s/\$test_size/$size/ig;

      $before.=$s;
   }
   $fl_lst->close();
   
   $$text=$before.$after;
}


#------------------------------------------------------------------------
sub insert_limits_p
{
   my ($text,$id_problem) = @_;
   my $query,$sth,$time_limit='',$mem_limit='',$min_uniq_proc='';
 
   $query="select time_lim,mem_lim,min_uniq_proc from problems where id_prb=$id_problem";
   $sth=$db->prepare($query);
   $sth->execute();
   ($time_limit,$mem_limit,$min_uniq_proc) = $sth->fetchrow_array;
   $sth->finish();
   $time_limit=sprintf("%.3f", $time_limit);
   $min_uniq_proc+=0;

   $$text =~ s/\$time_limit/$time_limit/ig;
   $$text =~ s/\$mem_limit/$mem_limit/ig;
   $$text =~ s/\$min_uniq_proc/$min_uniq_proc/ig;
}


#------------------------------------------------------------------------
sub insert_size_files_p
{
   my ($text,$id_problem) = @_;
   my $chk_src_size='',$chk_exe_size='',$fln;
   my $before,$after,$sect_chk_src,$arh_tests_size;

   #размеры проверяющей программы
   $$text =~ m/<!--start_checker_src-->(.*?)<!--finish_checker_src-->/si;
   $before=$`;
   $sect_chk_src=$1;
   $after=$';
   $fln="$DirProblems\\$id_problem\\".$ProblemPaths{'WrongAnswerSrc'};
   if (-e $fln) {
      $chk_src_size=format_size((stat($fln))[7]);
      $sect_chk_src =~ s/\$chk_src_size/$chk_src_size/ig;
   } else {
      $sect_chk_src='';
   }
   $$text=$before.$sect_chk_src.$after;

   $fln="$DirProblems\\$id_problem\\".$ProblemPaths{'WrongAnswerPrg'};
   $chk_exe_size=format_size((stat($fln))[7]);

   #размер архива тестов
   $fln="$DirProblems\\$id_problem\\".$ProblemPaths{'ArchivTestsName'};
   if (!-e($fln)) {
      re_pack($fln,
              "$DirProblems\\$id_problem\\".$ProblemPaths{'ListTests'},
              "$DirProblems\\$id_problem\\".$ProblemPaths{'Tests'}."\\*.in",
              "$DirProblems\\$id_problem\\".$ProblemPaths{'Tests'}."\\*.out");
   }
   $arh_tests_size=format_size((stat($fln))[7]);

   
   $$text =~ s/\$chk_exe_size/$chk_exe_size/ig;
   $$text =~ s/\$arh_tests_size/$arh_tests_size/ig;
}


#------------------------------------------------------------------------
sub insert_single_test_p
{
   my ($text,$id_problem,$test_name,$new,$id_lng) = @_;

   my $test_in="",$test_out="",$dir,$before,$sect_test,$after,$lst,$fl,$s;
   my $this_test='',$sect_lng='',$query,$sth,$comment_lang='';

   if ($$text =~ s/<!--this_test\{([^\{]*)\}-->//i) {
      $this_test=$1;
   }

   $$text =~ m/<!--start_other_tests-->(.*?)<!--finish_other_tests-->/si;
   $before=$`;
   $sect_test=$1;
   $after=$';

   $lst="$DirProblems\\$id_problem\\".$ProblemPaths{'ListTests'};
   $fl = new IO::File;
   $fl->open("< $lst");
   while (<$fl>) {
      chomp; 
      s/^\$//;
      
      if ($test_name eq $_) {
         $s=$this_test;
      } else {
         $s=$sect_test;
      }

      $s =~ s/\$i_test_name/$_/ig;
      $before.=$s;
   }
   $fl->close();
   $$text = $before.$after;
   
   $dir="$DirProblems\\$id_problem\\".$ProblemPaths{'Tests'};
   if (!$new) {
      $new=!read_file("$dir\\$test_name.in",\$test_in) ||
           !read_file("$dir\\$test_name.out",\$test_out);

      html_text(\$test_in);
      html_text(\$test_out);
   }

   if ($$text =~ s/<!--test_new\{([^\{]*)\}-->//i) {
      $test_name=$1 if ($new);
   }
   
   $$text =~ m/<!--start_comment-->(.*?)<!--finish_comment-->/si;
   $before=$`;
   $sect_lng=$1;
   $after=$';

   $query="select id_lng2, name from langs_lng where id_lng1='$id_lng'";
   $sth=$db->prepare($query);
   $sth->execute();
   
   while (my @row=$sth->fetchrow_array) {
      $row[1] =~ s/ *$//m;
      $s=$sect_lng;
      $s =~ s/\$i_id_lang/$row[0]/ig;
      $s =~ s/\$i_lang_name/$row[1]/ig;
      #if (!$new) {
         read_file("$dir\\$test_name.$row[0]",\$comment_lang);
         $s =~ s/\$comment_lang/$comment_lang/ig;
      #}
      $before.=$s;
   }
   $sth->finish();

   $$text=$before.$after;


   $$text =~ s/\$id_problem/$id_problem/ig;
   $$text =~ s/\$test_name/$test_name/ig;
   $$text =~ s/\$test_in/$test_in/ig;
   $$text =~ s/\$test_out/$test_out/ig;

}


#------------------------------------------------------------------------
sub save_test
{
   my ($id_problem,$old_name,$test_name) = @_;

   my $rez=1,$test_in="",$test_out="",$dir,$fl,$s,$lst,$dis;
   my @langs=(),@exts=('in','out','img'),%fl_txt=(),$query,$ptr,$k;

   $dir="$DirProblems\\$id_problem\\".$ProblemPaths{'Tests'};
   $fl=new IO::File;
   
   if (!$test_name) {
      $rez=0;
   }
   
   if ($rez) {
      $query="select id_lng from langs";
      $ptr=$db->selectcol_arrayref($query);
      @langs=@$ptr;
      push(@exts,@langs);
      #to_log(join(',',@langs));

      $lst="$DirProblems\\$id_problem\\".$ProblemPaths{'ListTests'};
      $s='';
      $fl->open("< $lst");
      while (<$fl>) {
         chomp; 
         $dis = s/^\$//;
            
         $rez=0 if ($old_name ne $_) && ($test_name eq $_);

         if ($old_name && ($old_name eq $_) && ($old_name ne $test_name)) {
            $_=$test_name; 
         }

         $s.= ($dis?'$':'').$_."\n";
      }
      $fl->close();
      if (!$old_name) {
         $s.= "$test_name\n";
      }
      
      if ($rez) {
         if ($old_name) {
            foreach $k (@exts) {
               rename("$dir\\$old_name.$k","$dir\\$test_name.$k");
            }
         }
         $fl->open("> $lst");
         print $fl $s;
         $fl->close();
      }
   }
   
   if ($rez) {
      if ($incgi->param("image_file")) {
         upload_file("image_file","$dir\\$test_name.img");
      }
      foreach $k (@exts) {
         next if $k eq 'img';
         if (grep($k eq $_,@langs)>0) {
            $s=$incgi->param("comment_$k")
         } else {
            $s=$incgi->param("test_$k")
         }
         $fl_txt{$k}=$s;
      }

      foreach $k (@exts) {
         next if $k eq 'img';
         if (grep($k eq $_,@langs)>0 && length($fl_txt{$k})==0) {
            unlink("$dir\\$test_name.$k");
            next;
         }
         $fl->open("> $dir\\$test_name.$k");
         binmode($fl);
         print $fl $fl_txt{$k};
         $fl->close();
      }

      grep($_="$DirProblems\\$id_problem\\".$ProblemPaths{'Tests'}."\\*.$_",@exts);

      re_pack("$DirProblems\\$id_problem\\".$ProblemPaths{'ArchivTestsName'},
              "$DirProblems\\$id_problem\\".$ProblemPaths{'ListTests'},@exts);
   }

   return $rez;
}

