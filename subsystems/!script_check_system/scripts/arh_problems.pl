#!c:\perl\bin\perl.exe

use DBI;
use FCGI;
use IO;
use CGI qw(:standard);
use CGI::Cookie;
use CGI::Carp  qw(fatalsToBrowser);
use POSIX;

require 'common_func.pl';
use vars qw($request $db $DirTemplates $incgi %cookies %ENV);


read_config();
connect_db();

#язык по умолчанию
$sth = $db->prepare("select def_lng from const");
$sth->execute;
@row = $sth->fetchrow_array;
$lng_def=$row[0];
$sth->finish;

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

   $prb = $incgi->param("id_prb")+0;

   if ($prb) {
      $fname = "cond_problem_$id_lng.html";
   } else {
      $cookie2 = undef;

      $cur_tm = $incgi->param("id_tm")+0;
      if (!$cur_tm) {
         $cur_tm = $cookies{"id_tm"};
         $find_substr = $cur_tm =~ m/\s*id_tm\s*=\s*(\w*)/;
         if ($find_substr) {$cur_tm = "$1"+0;}
         else {$cur_tm=0;}
      } else {
         $scr_nm = $ENV{"SCRIPT_NAME"};
         $cookie2 = new CGI::Cookie(-name=>"id_tm",-value=>"$cur_tm",-path=>"$scr_nm");
      }

      $fname = "tm_problems_$id_lng.html";
   }

   #откроем шаблон и считаем все строки
   $string_template='';
   read_file("$DirTemplates\\$fname",\$string_template);

   #обработаем $include_files(x)
   include_files(\$string_template);

   if ($prb) {
      insert_problem_atr(\$string_template,$prb,$lng_def,$id_lng,$id_user);
   } else {
      

      #обработаем $insert_tema
      $cur_tm=insert_tema(\$string_template,$cur_tm,$lng_def,$id_lng,$id_user);

      #обработаем $insert_problems
      insert_problems(\$string_template,$cur_tm,$lng_def,$id_lng,$id_user);
   }

   login_info(\$string_template,$id_user);

   #обработаем $current_page
   current_page(\$string_template);

   #$string_template =~ s/<!--.*?-->//sg;
  
   print header(-charset=>"Windows-1251",
               -cookie=>[$cookie1,$cookie2],
               -cache_control=>"no-cached",
               -pragma=>"no-cache"
               );
   print "$string_template";

}

print "\n";
$db->disconnect;
#POSIX:_exit(0);

#------------------------
#      Functions
#------------------------

sub insert_tema
{
  my($text,$cur_tm,$id_lngd,$id_lngc,$user) = @_;

  my $query="";
  my $sth=0;
  my @row=(),@row1=(),$is_new_prb;
  my $add_info='$nnlist';
  my $cur_pg=$ENV{"SCRIPT_NAME"};
  my $end_ierarh=$cur_tm;
  my $tmp1=0;
  my $tmp2=0;
  my $tmp3=0;
  my ($img_plus) = $$text =~ /\$node_plus\s*=\s*\{(.*?)\}/s;
  my ($img_minus) = $$text =~ /\$node_minus\s*=\s*\{(.*?)\}/s;
  my ($img_open) = $$text =~ /\$node_open\s*=\s*\{(.*?)\}/s;
  my ($img_close) = $$text =~ /\$node_close\s*=\s*\{(.*?)\}/s;

  my $smroot="is null";
  my $rez_tm=$cur_tm;

  if ($cur_tm > 0) {
     $query=<<SQL;
       select distinct CASE
              WHEN (t.small_root IS NULL) THEN t.id_tm
              ELSE t.small_root END, t.id_tm
       from tema t inner join get_subjs_user($user) gsu on t.id_tm=gsu.id_tm
       where t.small_root = $cur_tm or t.id_tm = $cur_tm
SQL
              
     $sth = $db->prepare($query);
     $sth->execute;
     @row=$sth->fetchrow_array;
     if ($row[0]>0) {
        @row1=$sth->fetchrow_array;
     } else {
        $rez_tm=-1; 
     }
     $sth->finish;
     
     if ($row1[0]>0) { $smroot=" =$cur_tm "; }
     else {
        if ($row[0]>0 && $row[0]!=$cur_tm) { 
           $smroot=" =$row[0] ";
           $end_ierarh = $row[0];
        } else {
           $smroot="is null";
        }
     }
  }

  if ($smroot ne "is null") {
    my $cur_node=$end_ierarh;
    my @levels=();
    my $lev_cnt=0;

    do {
  #запрос для получения родителя(и самой темы)
  $query="select name, small_root from tema,tema_lng "
  ."where id_lng='$id_lngc' and tema.id_tm=tema_lng.id_tm and tema.id_tm = $cur_node "
  ."union select name, small_root from tema, tema_lng "
  ."where id_lng='$id_lngd' and tema.id_tm=tema_lng.id_tm and tema.id_tm = $cur_node "
  ."and tema.id_tm not in (select id_tm from tema_lng where id_lng='$id_lngc' and tema.id_tm = $cur_node)";
       $sth = $db->prepare($query);
       $sth->execute;
       @row=$sth->fetchrow_array;
       $sth->finish;
       $levels[2*$lev_cnt]=$cur_node;
       $row[0] =~ s/ *\Z//;
       $levels[2*$lev_cnt+1]=$row[0];
       $lev_cnt++;
       $cur_node=$row[1];
    } while ($cur_node ne "");
    
    $levels[2*$lev_cnt]=-1;
    ($levels[2*$lev_cnt+1]) = $$text =~ /\$main_root\s*=\s*\{(.*?)\}/s;
    $lev_cnt++;

    for (my $i=$lev_cnt-2;$i>=0;$i--) {
       $tmp1=$levels[2*($i+1)];
       $tmp2=$img_minus.$levels[2*$i+1];

     if ($cur_tm == $levels[2*$i]) {
        $tmp3 = "<li><a class=\"tm_cur\" href=$cur_pg?id_tm=$tmp1>$tmp2</a>";
     } else {
        $tmp3 = "<li><a href=$cur_pg?id_tm=$tmp1>$tmp2</a>";
     }
       $add_info =~s/\$nnlist/$tmp3<ul class="Subj">\$nnlist<\/ul>/;
    }

#    $add_info =~s/\$nnlist/<ul class="Subj">\$nnlist<\/ul>/;
  }

  #получаем подтемы в данной теме
  $query=<<SQL;
  select distinct t.id_tm, tl.name, t.prb_cnt 
     from get_subjs_user($user) gsu inner join tema t on gsu.id_tm=t.id_tm
         inner join tema_lng tl on t.id_tm=tl.id_tm and id_lng='$id_lngc'
     where t.small_root $smroot 
     order by tl.name
SQL
  
  $sth = $db->prepare($query);
  $sth->execute;
  $tmp3="";
  while (@row = $sth->fetchrow_array) {

     foreach (@row) {
          #удалим пробелы в конце поля
        $_ =~ / *\Z/;
        $_ = "$`";
        #если поле пусто, то заменим его на длинный пробел
        if ($_ eq "") {$_ =  "&nbsp;";}
     }


     if ($cur_tm == $row[0]) {
        $tmp3 .= "<li><a class=\"tm_cur\" href=$cur_pg?id_tm=$row[0]>$img_open$row[1] ($row[2])</a>\n";
     } else {
     if ($row[2]==-1) {
        $tmp3 = "<li><a href=$cur_pg?id_tm=$row[0]>$img_plus$row[1]</a>\n".$tmp3;
     } else {
        $tmp3 .= "<li><a href=$cur_pg?id_tm=$row[0]>$img_close$row[1] ($row[2])</a>\n";
     }}
  }

  $sth->finish;

  $query="select max(g.f_create_prb) from get_groups_user($user) ggu inner join groups g on ggu.id_grp=g.id_grp";
  $sth = $db->prepare($query);
  $sth->execute;
  ($is_new_prb) = $sth->fetchrow_array;
  $sth->finish;
  if (!$is_new_prb) {
     $query="select max(f_create_prb) from all_subjs_user($user,0,0)";
     $sth = $db->prepare($query);
     $sth->execute;
     ($is_new_prb) = $sth->fetchrow_array;
     $sth->finish;
  }

  $$text =~ s/<!--start_new_problem-->(.*?)<!--finish_new_problem-->/$is_new_prb?$1:''/esig;

  $add_info =~s/\$nnlist/$tmp3/;
  $$text =~ s/\$insert_tema/$add_info/ig;

  return $rez_tm;
}

sub insert_problems
{
  my($text,$cur_tm,$id_lngd,$id_lngc,$user) = @_;

  my @status_prb,$hidden_prb='';
  
  ($status_prb[0]) = $$text =~ /\$notsubmit\s*=\s*\{(.*?)\}/s;
  ($status_prb[1]) = $$text =~ /\$solve\s*=\s*\{(.*?)\}/s;
  ($status_prb[2]) = $$text =~ /\$notsolve\s*=\s*\{(.*?)\}/s;

  my $query=<<SQL;
  select pr.id_prb,pl.name,st.cnt,pr.subms_cnt,pr.asolv_cnt,pr.id_creator, 
     (select case when min(id_rsl)=0 and count(id_rsl)>0 then 1 
                  when count(id_rsl)=0 then 0 
                  else 2 end
       from status where id_publ=$user and id_prb=pr.id_prb ), pr.hardlevel 
     from tm_prb tp inner join problems pr on tp.id_prb=pr.id_prb 
          inner join statistica st on st.id_prb=pr.id_prb
          inner join problems_lng pl on pl.id_prb=pr.id_prb and pl.id_lng='$id_lngc'
     where st.id_rsl=0 and tp.id_tm=$cur_tm 
     order by pl.name
SQL

  my $sth = $db->prepare($query);
  $sth->execute;

  my $cur_pg=$ENV{"SCRIPT_NAME"};

  my $add_info="";
  while ( my @row = $sth->fetchrow_array) {

     foreach (@row) {
          #удалим пробелы в конце поля
        $_ =~ / *\Z/;
        $_ = "$`";
        #если поле пусто, то заменим его на длинный пробел
        if ($_ eq "") {$_ =  "&nbsp;";}
     }
        if ($row[3]!=0) {
           $accept= int(100*$row[2]/$row[3]);
           $accept = "$accept%";
        } else { $accept="0%"; }

    if ($row[5]==$user || $row[4]>0) {    
        $add_info .= "<tr>"
        ."<td align=center>$row[0]</td>"
        ."<td><a href=$cur_pg?id_prb=$row[0]>$row[1]</a>$status_prb[$row[6]]</td>"
        ."<td align=center><a href=/cgi-bin/statistica.pl?id_prb=$row[0]>$accept</a></td>"
        ."<td align=center>$row[4]</td>"
        ."<td align=center>$row[7]</td>"
        ."</tr>\n";
    } else {
       $hidden_prb.="<a href=$cur_pg?id_prb=$row[0] title=\"$row[1]\">$row[0]</a>&nbsp;&nbsp;";
    }
  }

  $sth->finish;

  $$text =~ s/<!--start_hidden_problem-->(.*?)<!--finish_hidden_problem-->/($hidden_prb)?$1:''/esig;
  $$text =~ s/\$insert_problems/$add_info/ig;
  $$text =~ s/\$hidden_prb/$hidden_prb/ig;
}

sub insert_problem_atr
{
  my($text,$id_prb,$id_lngd,$id_lngc,$user) = @_;

  my $bl=0;
  my $query,$sth,@row,$f_submit_prb,$f_edit_prb,$o_id_prb;
  my $new_text="",$abs_path="",$fh;

  $o_id_prb=$id_prb;

  $query="select f_submit_prb, f_edit_prb from access_user_prb($user,'.$id_prb.')";
  $sth = $db->prepare($query);
  $sth->execute;
  ($f_submit_prb,$f_edit_prb) = $sth->fetchrow_array;
  $sth->finish;
  
  if ($f_submit_prb>0) {
  
     #вставим текст задачи
     $fh = new IO::File;
     $fh->open("< $DirPrbCond\\$id_prb\\$id_lngc\\index.html");

     if ($fh->error != 0) {
        $fh->open("< $DirPrbCond\\$id_prb\\$id_lngd\\index.html");
        $bl=1;
     }
     while (<$fh>) {
        $new_text .= $_;
     }  
     $fh->close;
  
     #вырежем body
     if ($new_text =~ m/<\s*body[^>]*?>(.*?)<\s*\/\s*body\s*>/si) {
        $new_text=$1;
     }

     #заменим относительный путь к рисукам на абсолютный      (http:\/\/|\/|)
     if ($bl == 0) {
        $abs_path = "$DirVirtualPrb\/$id_prb\/$id_lngc\/";
     } else {
        $abs_path = "$DirVirtualPrb\/$id_prb\/$id_lngd\/";
     }
     $new_text =~ s/(<\s*(?:img|image)\s+.*?src\s*=\s*"?)([^\/"][^>]*?)("?[\s\n>])/$1$abs_path$2$3/sig;
     $new_text =~ s/(<\s*(?:link)\s+.*?href\s*=\s*"?)([^\/"][^>]*?)("?[\s\n>])/$1$abs_path$2$3/sig;

  } else {
     $id_prb=0;
     if ($$text =~ /<!--.*?\$access_denied_prb\s*=\s*\{(.*?)\}.*?-->/is) {
        $new_text=$1;
     }
  }

  $$text =~ s/\$include_cond_prb/$new_text/gi;

  #вставим название, time limit & memory limit
  if ($bl == 0) {
     $query="select name from problems_lng where id_prb=$id_prb and id_lng='$id_lngc'";
  } else {
     $query="select name from problems_lng where id_prb=$id_prb and id_lng='$id_lngd'";
  }

  $sth = $db->prepare($query);
  $sth->execute;
  @row = $sth->fetchrow_array;
  $sth->finish;

  $row[0] =~ s/\s*\Z//;
  $$text =~ s/\$problem_name/$row[0]/gi;

  $query="select p.time_lim, p.mem_lim, p.id_creator, a.name, p.hardlevel ".
         " from problems p left outer join authors a on p.id_creator=a.id_publ ".
         " where id_prb=$id_prb";
  $sth = $db->prepare($query);
  $sth->execute;
  @row = $sth->fetchrow_array;
  $sth->finish;
  $row[0]=int($row[0]*1000)/1000;
  $row[1]=$row[1]*1;
  if (!$row[2]) {
    $row[2]=-1;
    ($row[3]) = $$text =~ /<!--[\s\n\r]*\$author_undef\s*=\s*\{(.*?)\}.*?-->/is;
  }
                                                                                   
  html_text(\$row[3]);
  $$text =~ s/<!--start_edit_problem-->(.*?)<!--finish_edit_problem-->/($f_edit_prb)?$1:''/esig;

  $$text =~ s/\$time_limit/$row[0]/gi;
  $$text =~ s/\$memory_limit/$row[1]/gi;
  $$text =~ s/\$id_author/$row[2]/gi;
  $$text =~ s/\$author_name/$row[3]/gi;
  $$text =~ s/\$problem_id/$id_prb/gi;
  $$text =~ s/\$add_param/&id_prb=$o_id_prb/ig;
  $$text =~ s/\$hardlevel/$row[4]/ig;

}

  