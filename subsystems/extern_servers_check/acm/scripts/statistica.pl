#!c:\perl\bin\perl.exe

use DBI;
use FCGI;
use IO;
use CGI qw(:standard);
use CGI::Cookie;
use CGI::Carp  qw(fatalsToBrowser);
use POSIX;

require 'common_func.pl';
use vars qw($request $out_stream $db $DirTemplates $incgi %ENV %cookies);


#------------------------
#      Functions
#------------------------

sub insert_ranklist
{
  my($text,$rank,$grp,$id_lng,$id_user,$topic) = @_;
  my $query,$sth,$a_tbl,$add_grp,$grp_name;
  my @row = (),$rec_cnt,$rec_cnt1,$a_place=0,$boss,$query_mng;
  my $sect_grp,$sect_topic,$s,$before,$after,$single_offset,$offset;

  $$text =~ /\$insert_ranklist\(\s*(\d+)\s*\)/;
  $rec_cnt = $1;
  $rec_cnt1=$rec_cnt+1;

  if ($grp>0) { #ранклист для группы
      
     #if ($nstep_cnt>20) {
     #   $db->do("create table users_in_grp(id_publ integer not null primary key)");
     #   $db->do("create table problems_in_grp(id_prb integer not null primary key)");
     #   $db->do("create table author_names_stat_grp(id_publ integer not null primary key, solve_cnt integer, submit_cnt integer)");
     #   $db->commit;
     #}

     #debug
     #$db->do("execute procedure update_ranklist_grp($grp)");
     #$db->commit;

     #debug
     #$a_tbl='author_names_stat_grp';
     $a_tbl='author_names';
     $ranklist = "get_ranklist($grp,$topic)";

  } else {
     $a_tbl='author_names';
     $ranklist = "ranklist";
  }

  #определим параметры автора по которым вычисляется место
  $query = "select solve_cnt,submit_cnt from $a_tbl where id_publ=$rank";
  $sth = $db->prepare($query);
  $sth->execute;
  @aprm = $sth->fetchrow_array;
  $sth->finish;

  if ($aprm[0] eq "") {
    #если автора не существует выводим сначала
    $a_place=1;
    $query=<<SQL;
      select first $rec_cnt1 a.name, r.id_publ,
         (select name from countrs where id_cn=a.id_cn),
         r.prb_cnt, a.submit_cnt, r.rank
      from $a_tbl a inner join $ranklist r on a.id_publ=r.id_publ
      order by r.rank desc
SQL
  } else {
    #если автор существует определим его ранг
    $query= "select rank from $ranklist where id_publ=$rank";

#    open GF, ">c:\temp\x.txt";
#    printf GF $query;
#    close GF;

    $sth = $db->prepare($query);
    $sth->execute;
    @row = $sth->fetchrow_array;
    $sth->finish;
    $a_rank=$row[0];
    #теперь определим место по-порядку
    $query="select count(*)+1 from $ranklist where rank > $a_rank";
    $sth = $db->prepare($query);
    $sth->execute;
    @row = $sth->fetchrow_array;
    $sth->finish;
    $a_place=$row[0];

#Здесь, похоже, выбираются все, у кого рейтинг такой же или ниже
    $query=<<SQL;
      select first $rec_cnt1 a.name, r.id_publ,
         (select name from countrs where id_cn=a.id_cn),
         r.prb_cnt, a.submit_cnt, r.rank
      from $a_tbl a inner join $ranklist r on a.id_publ=r.id_publ
      where r.rank<=$a_rank
      order by r.rank desc
SQL
  }

  $sth = $db->prepare($query);
  $sth->execute;

  my $new_text="";
  my $cnt=0;
  while (($cnt<$rec_cnt) && (@row = $sth->fetchrow_array)) {
     #заменим <, >, &, " в имени автора
     html_text(\$row[0]);
     foreach (@row) {
        #удалим пробелы в конце поля
        $_ =~ / *\Z/;
        $_ = "$`";
        #если поле пусто, то заменим его на длинный пробел
        if ($_ eq "") {$_ =  "&nbsp;";}
     }
     $new_text .= "<tr>"
     ."<td align=center>$a_place</td>"
     ."<td>$row[2]</td>"
     ."<td><a href=/cgi-bin/statistica.pl?id_publ=$row[1]>$row[0]</a></td>"
     ."<td align=center>$row[3]</td>"
     ."<td align=center>$row[4]</td>"
     ."<td align=center>$row[5]</td>"
      ."</tr>\n";
     $cnt++;
     $a_place++;
  }

  my $next_author=-1;

  if (($cnt==$rec_cnt) && (@row = $sth->fetchrow_array)) {
     $next_author=$row[1];
  }

  $sth->finish;

  if ($grp>0) {
#     $db->do("drop table users_in_grp0");
#     $db->do("drop table problems_in_grp0");
#     $db->do("drop table author_names0");
#     $db->commit;
     
     $add_grp="&id_grp=$grp";
     $add_topic="&id_topic=$topic";
     $$text =~ s/<!--start_single_grp-->(.*?)<!--finish_single_grp-->/$1/sig;

     $query = "select name from groups_lng where id_grp=$grp and id_lng='$id_lng'";
     $sth = $db->prepare($query);
     $sth->execute;
     ($grp_name) = $sth->fetchrow_array;
     $sth->finish;
     $grp_name =~ s/ *$//m;
     $$text =~ s/\$group_name/$grp_name/sig;

     if($topic>0) {
       $query = "select name from tema_lng where id_tm=$topic and id_lng='$id_lng'";
       $sth = $db->prepare($query);
       $sth->execute;
       ($topic_name) = $sth->fetchrow_array;
       $sth->finish;
       $topic_name =~ s/ *$//m;
       $$text =~ s/\$topic_name/$topic_name/sig;
     }
     else{
       $$text =~ s/<!--start_single_topic-->(.*?)<!--finish_single_topic-->//sig; 
     }


  } else {
     $add_grp="";
     $$text =~ s/<!--start_single_grp-->(.*?)<!--finish_single_grp-->//sig;

     $$text =~ s/<!--start_single_topic-->(.*?)<!--finish_single_topic-->//sig; 

     if ($id_user>0) {

     $$text =~ s/<!--start_offset_group-->(.*?)<!--finish_offset_group-->//mi;
     $single_offset=$1;

     $$text =~ m/<!--start_group-->(.*?)<!--finish_group-->/si;
     $before=$`;
     $sect_grp=$1;
     $after=$';                  

     $query="select count(*) from groups_boss where id_publ=$id_user";
     $sth=$db->prepare($query);
     $sth->execute();
     ($boss) = $sth->fetchrow_array;
     $sth->finish();

     if ($boss>0 || is_manage_system($id_user)>0) {
        $query_mng=<<SQL;
select ggb.n_ord, ggb.id_grp, ggb.id_level,gl.name
   from get_groups_boss($id_user) ggb inner join groups_lng gl
      on ggb.id_grp=gl.id_grp and gl.id_lng='$id_lng'
   where ggb.is_boss>0
union
SQL
     } else {
        $query_mng='';
     }
     $query=<<SQL;
  $query_mng
  select distinct gtg.n_ord,ggu.id_grp, gtg.id_level, gl.name
   from get_groups_user($id_user) ggu inner join get_tree_groups(null,0) gtg on ggu.id_grp=gtg.id_grp
        inner join groups_lng gl on ggu.id_grp=gl.id_grp and gl.id_lng='$id_lng'
   order by 1
SQL
     $sth = $db->prepare($query);
     $sth->execute;

     while (@row=$sth->fetchrow_array) {
        $offset=$single_offset x ($row[2]-1);
        $row[3] =~ s/ *$//;

        $s=$sect_grp;
        $s =~ s/\$group_id/$row[1]/ig;
        $s =~ s/\$group_name/$row[3]/ig;
        $s =~ s/\$offset_group/$offset/ig;

        $before.=$s;
     }
     $sth->finish();

     $$text=$before.$after;

     #теперь выбор темы
     $$text =~ m/<!--start_topic-->(.*?)<!--finish_topic-->/si;
     $before=$`;
     $sect_topic=$1;
     $after=$';                  

     $query=<<SQL;
  select distinct gts.n_ord,gsu.id_tm, gts.id_level, tl.name
   from get_subjs_user($id_user) gsu inner join get_tree_subj(null,0) gts on gsu.id_tm=gts.id_tm
        inner join tema_lng tl on gsu.id_tm=tl.id_tm and tl.id_lng='$id_lng' where gts.id_level<3
   order by 1
SQL
     $sth = $db->prepare($query);
     $sth->execute;

     while (@row=$sth->fetchrow_array) {
        $offset=$single_offset x ($row[2]-1);
        $row[3] =~ s/ *$//;

        $s=$sect_topic;
        $s =~ s/\$topic_id/$row[1]/ig;
        $s =~ s/\$topic_name/$row[3]/ig;
        $s =~ s/\$offset_topic/$offset/ig;
        if ($row[1]==0) {$def="selected";} else {$def="";}
        $s =~ s/\$def/$def/ig;

        $before.=$s;
     }
     $sth->finish();

     $$text=$before.$after;


     }
  }
  
  $$text =~ s/<!--start_sel_grp-->(.*?)<!--finish_sel_grp-->/($id_user>0 && $grp==0)?$1:''/esig;
  $$text =~ s/\$next_author/$next_author/ig;
  $$text =~ s/\$add_grp/$add_grp/ig;
  $$text =~ s/\$add_topic/$add_topic/ig;
  $$text =~ s/\$add_param/&rank=$rank$add_grp/ig;
  $$text =~ s/\$insert_ranklist\(\s*(\d+)\s*\)/$new_text/ig;
}

#-----------------------------------------------------------------
sub insert_author_stat
{
  my($text,$id_publ,$id_lng,$id_user) = @_;
  my $sect_grp,$s,$before,$after,$single_offset,$offset;
  my $first_sd,$last_sd,$days_sc;

  #определим параметры автора
  my $query = "select a.name,c.name,a.other_info,a.solve_cnt,a.submit_cnt from author_names a, "
             ."countrs c where a.id_cn=c.id_cn and a.id_publ=$id_publ";
  my $sth = $db->prepare($query);
  $sth->execute;
  my @aprm = $sth->fetchrow_array;
  $sth->finish;

  my @row=();
  my $author_groups="",$ch_g=0;
  my $solve_prb="";
  my $notsolve_prb="";
  my $a_place=-1;
  my $table_stat="";
  my $best_prb="";
  my $table_ranksmall="";
  my $aprm3 = 0;

  #автора несуществует
  if ($aprm[3] ne "") {

  foreach (@aprm) {
     $_ =~ / *\Z/;
     $_ = "$`";
     if ($_ eq "") {$_ =  "  ";}
  }
  html_text(\$aprm[0]);
  html_text(\$aprm[2],1);


  $$text =~ s/<!--start_offset_group-->(.*?)<!--finish_offset_group-->//mi;
  $single_offset=$1;

  $$text =~ m/<!--start_group-->(.*?)<!--finish_group-->/si;
  $before=$`;
  $sect_grp=$1;
  $after=$';

  $query=<<SQL;
  select distinct ggu.id_grp, gtg.id_level, gl.name
   from get_groups_user($id_publ) ggu inner join get_tree_groups(null,0) gtg on ggu.id_grp=gtg.id_grp
        inner join groups_lng gl on ggu.id_grp=gl.id_grp and gl.id_lng='$id_lng'
   order by gtg.n_ord
SQL
  $sth = $db->prepare($query);
  $sth->execute;

   while (my @row=$sth->fetchrow_array) {
      $offset=$single_offset x ($row[1]-1);
      $row[2] =~ s/ *$//;

      $s=$sect_grp;
      $s =~ s/\$id_grp/$row[0]/ig;
      $s =~ s/\$group_name/$row[2]/ig;
      $s =~ s/\$offset_group/$offset/ig;

      $before.=$s;
   }
   $sth->finish();

   $$text=$before.$after;
  
  $ch_g=access_change_grp_user($id_user);

  #определяем место участника

    $query= "select rank from ranklist where id_publ=$id_publ";
    $sth = $db->prepare($query);
    $sth->execute;
    @row = $sth->fetchrow_array;
    $sth->finish;
    $a_rank=$row[0]+0;
    #теперь определим место по-порядку
    $query="select count(*)+1 from ranklist where rank > $a_rank";
    $sth = $db->prepare($query);
    $sth->execute;
    @row = $sth->fetchrow_array;
    $sth->finish;
    $a_place=$row[0];

  #извлекаем статистику результатов
  $query = "select r.id_rsl+1,r.name,s.cnt from stat_authors s, results_lng r "
          ."where id_publ=$id_publ and s.id_rsl=r.id_rsl and r.id_lng='$id_lng'";

  $sth = $db->prepare($query);
  $sth->execute;

  while (@row = $sth->fetchrow_array) {

     foreach (@row) {
        #удалим пробелы в конце поля
        $_ =~ / *\Z/;
        $_ = "$`";
        #если поле пусто, то заменим его на длинный пробел
        if ($_ eq "") {$_ =  "&nbsp;";}
     }

     $table_stat .= "<tr>"
     ."<th align=\"left\">$row[1]</th>"
     ."<td align=\"right\"><a href=\"/cgi-bin/status.pl?id_publ=$id_publ&filter_rsl=$row[0]\">$row[2]</a></td>"
     ."</tr>\n";
  }

  $sth->finish;

  #даты
  $query = <<SQL;
  select min(dt_tm),max(dt_tm),
     (select count(*) from status where id_publ=$id_publ and current_timestamp-dt_tm<=30) 
     from status where id_publ=$id_publ
SQL

  $sth = $db->prepare($query);
  $sth->execute;
  ($first_sd,$last_sd,$days_sc)=$sth->fetchrow_array;
  $sth->finish;

  #решенные и не решенные задачи
  $query = "select s.id_prb, count(s.id_prb), min(s.id_rsl), ".
   "(select p.name from problems_lng p where s.id_prb=p.id_prb and p.id_lng='$id_lng') ".
   "from status s where s.id_publ=$id_publ group by s.id_prb order by s.id_prb";

  $sth = $db->prepare($query);
  $sth->execute;

  $notsolve_prb = "<tr>";
  $solve_prb = "<tr>";
  my $val_in_line=5;
  my $cnt=1;
  my $cnt1=1;

  my $one_line = "";
  while (@row = $sth->fetchrow_array) {
     $row[3] =~ s/ *$//;
     
     $one_line = "<td><a href=\"/cgi-bin/status.pl?id_prb=$row[0]&id_publ=$id_publ\" title=\"$row[3]\">$row[0]"
       ."<sup>$row[1]</sup></a></td>";

     if ($row[2] == 0) {
       $solve_prb .= $one_line;

       if ($cnt1%$val_in_line==0) {
         $solve_prb .= "</tr>\n<tr>";
       }
       $cnt1++;
     } else {
       $notsolve_prb .= $one_line;

       if ($cnt%$val_in_line==0) {
         $notsolve_prb .= "</tr>\n<tr>";
       }
       $cnt++;
     }

  }

  $sth->finish;
  $notsolve_prb .= "</tr>";
  $solve_prb .= "</tr>";

  #лучшие решения
  $query = <<SQL;
  select b.id_slv, s.id_prb, b.add_admin,
   (select p.name from problems_lng p where p.id_prb=s.id_prb and p.id_lng='$id_lng')
   from best_solve b inner join status s on b.id_slv=s.id_stat
   where s.id_publ=$id_publ
   order by s.id_prb
SQL

  $sth = $db->prepare($query);
  $sth->execute;

  $best_prb = "<tr valign=\"bottom\">";
  $cnt=1;
  while (@row = $sth->fetchrow_array) {
     $row[3] =~ s/ *$//;

     if ($row[2] eq "y" ) {
        $one_line = "<a class=\"bl_lnk\" href=\"/cgi-bin/statistica.pl?"
                   ."id_slv=$row[0]\" title=\"$row[3]\">$row[1]<sup>admin</sup></a>";
     } else {
        $one_line = "<a href=\"/cgi-bin/statistica.pl?id_slv=$row[0]\" title=\"$row[3]\">$row[1]</a>";
     }

     $best_prb .= "<td>$one_line</td>";

     if ($cnt%$val_in_line==0) {
       $best_prb .= "</tr>\n<tr valign=\"bottom\">";
     }
     $cnt++;
  }

  $sth->finish;
#  $cnt--;
#  while ($cnt%$val_in_line!=0) {
#     $best_prb .= "<td>&nbsp;</td>";
#     $cnt++;
#  }
  $best_prb .= "</tr>";

  #выводим соседей

  $aprm3 = 0-$aprm[3];
  $table_ranksmall= "<tr class=\"mark_author\">"
     ."<td align=\"center\">$a_place</td>"
     ."<td><a href=\"/cgi-bin/statistica.pl?id_publ=$id_publ\">$aprm[0]</a></td>"
     ."<td align=\"center\">$aprm3</td>"
     ."<td align=\"center\">$aprm[4]</td>"
     ."</tr>\n";

  #нижние соседи
    $query=<<SQL;
      select first 10 a.name, r.id_publ,
         0-a.solve_cnt, a.submit_cnt
      from author_names a inner join ranklist r on a.id_publ=r.id_publ
      where (r.rank<=$a_rank) and (r.id_publ<>$id_publ)
      order by r.rank desc
SQL
  
  $sth = $db->prepare($query);
  $sth->execute;

  $$text =~ /\$insert_ranksmall\(\s*(\d+)\s*\)/;
  my $rec_cnt = $1;

  $cnt=$a_place+1;
  my $rec_num = $a_place+$rec_cnt;
  while (($cnt<=$rec_num) && (@row = $sth->fetchrow_array)) {
     #заменим <, >, &, " в имени автора
     html_text(\$row[0]);
     foreach (@row) {
        #удалим пробелы в конце поля
        $_ =~ / *\Z/;
        $_ = "$`";
        #если поле пусто, то заменим его на длинный пробел
        if ($_ eq "") {$_ =  "&nbsp;";}
     }
     $table_ranksmall .= "<tr>"
     ."<td align=\"center\">$cnt</td>"
     ."<td><a href=\"/cgi-bin/statistica.pl?id_publ=$row[1]\">$row[0]</a></td>"
     ."<td align=\"center\">$row[2]</td>"
     ."<td align=\"center\">$row[3]</td>"
     ."</tr>\n";
     $cnt++;
  }

  #верхние соседи
    $query=<<SQL;
      select first 10 a.name, r.id_publ,
         0-a.solve_cnt, a.submit_cnt
      from author_names a inner join ranklist r on a.id_publ=r.id_publ
      where (r.rank>$a_rank) and (r.id_publ<>$id_publ)
      order by r.rank
SQL
  $sth = $db->prepare($query);
  $sth->execute;

  $cnt=$a_place-1;
  $rec_num = $a_place-$rec_cnt;
  while (($cnt>=$rec_num) && (@row = $sth->fetchrow_array)) {
     #заменим <, >, &, " в имени автора
     html_text(\$row[0]);
     foreach (@row) {
        #удалим пробелы в конце поля
        $_ =~ / *\Z/;
        $_ = "$`";
        #если поле пусто, то заменим его на длинный пробел
        if ($_ eq "") {$_ =  "&nbsp;";}
     }
     $table_ranksmall = "<tr>"
     ."<td align=\"center\">$cnt</td>"
     ."<td><a href=\"/cgi-bin/statistica.pl?id_publ=$row[1]\">$row[0]</a></td>"
     ."<td align=\"center\">$row[2]</td>"
     ."<td align=\"center\">$row[3]</td>"
     ."</tr>\n".$table_ranksmall;
     $cnt--;
  }

  }

  $$text =~ s/<!--start_change_groups-->(.*?)<!--finish_change_groups-->/($ch_g>0)?$1:''/esig;
  $$text =~ s/<!--start_edit_profile-->(.*?)<!--finish_edit_profile-->/access_edit_profile($id_user,$id_publ)?$1:''/esig;
  $$text =~ s/\$id_author/$id_publ/ig;

  $$text =~ s/\$author_name/$aprm[0]/ig;
  $$text =~ s/\$author_country/$aprm[1]/ig;
  $$text =~ s/\$author_info/$aprm[2]/ig;
  $$text =~ s/\$author_solve/$aprm3/ig;
  $$text =~ s/\$author_submit/$aprm[4]/ig;
  $$text =~ s/\$author_groups/$author_groups/ig;
  $$text =~ s/\$author_place/$a_place/ig;
  $$text =~ s/\$author_stat/$table_stat/ig;
  
  $$text =~ s/\$first_sbm_date/$first_sd/ig;
  $$text =~ s/\$last_sbm_date/$last_sd/ig;
  $$text =~ s/\$30days_sbm_cnt/$days_sc/ig;
  
  $$text =~ s/\$problems_solve/$solve_prb/ig;
  $$text =~ s/\$problems_notsolve/$notsolve_prb/ig;
  $$text =~ s/\$problems_best/$best_prb/ig;
  $$text =~ s/\$insert_ranksmall\(\s*(\d+)\s*\)/$table_ranksmall/ig;
  $$text =~ s/\$add_param/&id_publ=$id_publ/ig;
}

sub access_solve
{
   my($id_slv,$id_publ,$who_v_ptr,$id_prb_ptr)=@_;

   #дополнительные данные о лучшем решении
   my $query = "select s.id_prb,s.id_publ,b.who_view from best_solve b inner join status s on b.id_slv=s.id_stat "
                         ."where b.id_slv=$id_slv";
   my $sth = $db->prepare($query);
   $sth->execute;
   my @row = $sth->fetchrow_array;
   $sth->finish;
   if ($row[0] eq "") {
      return "not found";
   }

   my($id_prb,$id_author,$who_view)=@row;
   $$who_v_ptr = $who_view;
   $$id_prb_ptr = $id_prb;

   if ($id_publ==$id_author) {
      return "full";
   }
   if ($who_view eq "n") {
      return "denied";
   }
   if ($who_view eq "a") {
      return "view";
   }

   $query = "select count(id_prb) from status where id_publ=$id_publ and "
             ."id_prb=$id_prb and id_rsl=0 group by id_prb";

   $sth = $db->prepare($query);
   $sth->execute;
   @row = $sth->fetchrow_array;
   $sth->finish;
   if ($row[0] > 0) {
      return "view";
   }

   return "denied";
}

#проверка доступа на просмотр исходника
sub access_source
{
   my($id_stat,$id_user,$who_v_ptr,$id_prb_ptr)=@_;
   my $rez=0;

   #дополнительные данные о решении
   my $query = "select s.id_prb,s.id_publ,s.who_view from status s where s.id_stat=$id_stat";
   my $sth = $db->prepare($query);
   $sth->execute;
   my @row = $sth->fetchrow_array;
   $sth->finish;
   if ($row[0] eq "") {
      return "not found";
   }

   my($id_prb,$id_publ,$who_view)=@row;
   $$who_v_ptr = $who_view;
   $$id_prb_ptr = $id_prb;

   if ($id_user==$id_publ) {
      return "full";
   } else {
      $query=<<SQL;
select count(*)
   from get_groups_boss($id_user) ggb
   where ggb.is_boss>0 and exists (select id_grp from get_groups_user($id_publ) where id_grp=ggb.id_grp)
SQL

      $sth=$db->prepare($query);
      $sth->execute();
      ($rez) = $sth->fetchrow_array;
      $sth->finish;
      if ($rez>0) {
         return "view";
      } else {
        if ($who_view eq "n") {
           return "denied";
        } elsif ($who_view eq "a") {
           return "view";
        } else {

           $query = "select count(id_prb) from status where id_publ=$id_user and "
                   ."id_prb=$id_prb and id_rsl=0 group by id_prb";

           $sth = $db->prepare($query);
           $sth->execute;
           @row = $sth->fetchrow_array;
           $sth->finish;
           if ($row[0] > 0) {
              return "view";
           }
        }
      }
   }

   return "denied";
}

sub insert_src_rules
{
  my($text,$who_view,$id_prb) = @_;
  my $view_str="";

  if ($who_view eq "a") {
     ($view_str) = $$text =~ /\$view_all\s*=\s*\{(.*?)\}/si;
  } elsif ($who_view eq "n") {
     ($view_str) = $$text =~ /\$view_author\s*=\s*\{(.*?)\}/si;
  } elsif ($who_view eq "s") {
     ($view_str) = $$text =~ /\$view_solved\s*=\s*\{(.*?)\}/si;
  }
  $view_str =~ s/\$id_problem/$id_prb/sig;
  $$text =~ s/\$who_view/$view_str/ig;

}


sub insert_src_atr
{
  my($text,$id_slv,$lng_c,$lng_d) = @_;
  my $source_str="";

  my $query = "select best_code,add_admin from best_solve where id_slv=$id_slv";
  my $sth = $db->prepare($query);
  $sth->execute;
  my @row = $sth->fetchrow_array;
  $sth->finish;
  my $source_str=$row[0];
  my $add_admin=$row[1];
  html_text(\$source_str);

  $query = "select s.id_publ, a.name, s.id_prb, p.name, c.name, c.color_lang "
          ."from status s JOIN author_names a ON a.id_publ = s.id_publ "
          ."JOIN compil c ON c.id_cmp = s.id_cmp "
          ."JOIN problems_lng p ON (p.id_prb = s.id_prb) and (p.id_lng='$lng_c') "
          ."JOIN results_lng r ON (r.id_rsl = s.id_rsl) and (r.id_lng='$lng_c') "
          ."where s.id_stat=$id_slv";
  $sth = $db->prepare($query);
  $sth->execute;
  @row = $sth->fetchrow_array;
  $sth->finish;

  if ($row[3] eq "") {
  $query = "select s.id_publ, a.name, s.id_prb, p.name, c.name, c.color_lang "
          ."from status s JOIN author_names a ON a.id_publ = s.id_publ "
          ."JOIN compil c ON c.id_cmp = s.id_cmp "
          ."JOIN problems_lng p ON (p.id_prb = s.id_prb) and (p.id_lng='$lng_d') "
          ."JOIN results_lng r ON (r.id_rsl = s.id_rsl) and (r.id_lng='$lng_c') "
          ."where status.id_stat=$id_slv";
  $sth = $db->prepare($query);
  $sth->execute;
  @row = $sth->fetchrow_array;
  $sth->finish;
  }

  html_text(\$row[1]);
  foreach (@row) {
     #удалим пробелы в конце поля
     $_ =~ / *\Z/;
     $_ = "$`";
     #если поле пусто, то заменим его на длинный пробел
     if ($_ eq "") {$_ =  "&nbsp;";}
  }

  my $who_append_str="";
  if($add_admin eq "n") {
     ($who_append_str) = $$text =~ /\$append_sys\s*=\s*\{(.*?)\}/i;
  } else {
     ($who_append_str) = $$text =~ /\$append_admin\s*=\s*\{(.*?)\}/i;
  }

  $$text =~ s/\$id_author/$row[0]/ig;
  $$text =~ s/\$author_name/$row[1]/ig;
  $$text =~ s/\$id_problem/$row[2]/ig;
  $$text =~ s/\$problem_name/$row[3]/ig;
  $$text =~ s/\$compiler_name/$row[4]/ig;
  $$text =~ s/\$color_lang/$row[5]/ig;
  $$text =~ s/\$id_solve/$id_slv/ig;
  $$text =~ s/\$id_stat/$id_stat/ig;
  $$text =~ s/\$who_append/$who_append_str/ig;
  $$text =~ s/\$source_text/$source_str/ig;
}

#для просмотра не лучшего :) исходника
sub insert_src_atr2
{
  my($text,$id_stat,$lng_c,$lng_d) = @_;
  my $source_str="";

#  my $query = "select ':)','n' from status where id_stat=$id_stat";
#  my $sth = $db->prepare($query);
#  $sth->execute;
#  my @row = $sth->fetchrow_array;
#  $sth->finish;

  my $source_str;
  read_file("$DirSrcArh\\".sprintf('%x',$id_stat).".src",\$source_str);
      if ($source_str eq "") {$source_str = "Source not found!!!"; }
  html_text(\$source_str);

  my $add_admin='n';

  $query = "select s.id_publ, a.name, s.id_prb, p.name, c.name, c.color_lang "
          ."from status s JOIN author_names a ON a.id_publ = s.id_publ "
          ."JOIN compil c ON c.id_cmp = s.id_cmp "
          ."JOIN problems_lng p ON (p.id_prb = s.id_prb) and (p.id_lng='$lng_c') "
          ."JOIN results_lng r ON (r.id_rsl = s.id_rsl) and (r.id_lng='$lng_c') "
          ."where s.id_stat=$id_stat";
  $sth = $db->prepare($query);
  $sth->execute;
  @row = $sth->fetchrow_array;
  $sth->finish;

  if ($row[3] eq "") {
  $query = "select s.id_publ, a.name, s.id_prb, p.name, c.name, c.color_lang "
          ."from status s JOIN author_names a ON a.id_publ = s.id_publ "
          ."JOIN compil c ON c.id_cmp = s.id_cmp "
          ."JOIN problems_lng p ON (p.id_prb = s.id_prb) and (p.id_lng='$lng_d') "
          ."JOIN results_lng r ON (r.id_rsl = s.id_rsl) and (r.id_lng='$lng_c') "
          ."where status.id_stat=$id_stat";
  $sth = $db->prepare($query);
  $sth->execute;
  @row = $sth->fetchrow_array;
  $sth->finish;
  }

  html_text(\$row[1]);
  foreach (@row) {
     #удалим пробелы в конце поля
     $_ =~ / *\Z/;
     $_ = "$`";
     #если поле пусто, то заменим его на длинный пробел
     if ($_ eq "") {$_ =  "&nbsp;";}
  }

  my $who_append_str="";
  if($add_admin eq "n") {
     ($who_append_str) = $$text =~ /\$append_sys\s*=\s*\{(.*?)\}/i;
  } else {
     ($who_append_str) = $$text =~ /\$append_admin\s*=\s*\{(.*?)\}/i;
  }

  $$text =~ s/\$id_author/$row[0]/ig;
  $$text =~ s/\$author_name/$row[1]/ig;
  $$text =~ s/\$id_problem/$row[2]/ig;
  $$text =~ s/\$problem_name/$row[3]/ig;
  $$text =~ s/\$compiler_name/$row[4]/ig;
  $$text =~ s/\$color_lang/$row[5]/ig;
  $$text =~ s/\$id_solve/$id_stat/ig;
  $$text =~ s/\$id_stat/$id_stat/ig;
  $$text =~ s/\$who_append/$who_append_str/ig;
  $$text =~ s/\$source_text/$source_str/ig;
}


sub insert_src_atr_dop
{
   my($text,$id_slv,$who_view)=@_;

   $$text =~ s/\$checked_$who_view/checked/ig;
   $$text =~ s/\$checked_.//ig;
}

sub insert_problem_stat
{
   my($text,$prb,$lng_c,$lng_d)=@_;

  #определим параметры задачи
  my $query = "select a.name,p.asolv_cnt,p.asubm_cnt,p.subms_cnt from problems p, "
         ."problems_lng a where p.id_prb=$prb and p.id_prb=a.id_prb "
         ."and a.id_lng='$lng_c' union "
         ."select a.name,p.asolv_cnt,p.asubm_cnt,p.subms_cnt from problems p, "
         ."problems_lng a where p.id_prb=$prb and p.id_prb=a.id_prb "
         ."and a.id_lng='$lng_d' and p.id_prb not in (select id_prb "
         ."from problems_lng where id_prb=$prb and id_lng='$lng_c')";
  my $sth = $db->prepare($query);
  $sth->execute;
  my @param_row = $sth->fetchrow_array;
  $sth->finish;

  my $table_stat="";
  my $table_best_slv="";

  $param_row[0] =~ s/ *\Z//;

  #извлекаем статистику результатов
  $query = "select r.id_rsl+1,r.name,s.cnt from statistica s, results_lng r "
          ."where id_prb=$prb and s.id_rsl=r.id_rsl and r.id_lng='$lng_c'";

  $sth = $db->prepare($query);
  $sth->execute;

  my @row = ();
  while (@row = $sth->fetchrow_array) {

     foreach (@row) {
        #удалим пробелы в конце поля
        $_ =~ / *\Z/;
        $_ = "$`";
        #если поле пусто, то заменим его на длинный пробел
        if ($_ eq "") {$_ =  "&nbsp;";}
     }

     $table_stat .= "<tr>"
     ."<th align=\"left\">$row[1]</th>"
     ."<td align=\"right\"><a href=\"/cgi-bin/status.pl?id_prb=$prb&filter_rsl=$row[0]\">$row[2]</a></td>"
     ."</tr>\n";
#     $table_stat .= "<tr>"
#     ."<th align=left>$row[0]</th>"
#     ."<td align=right>$row[1]</td>"
#     ."</tr>\n";
  }

  $sth->finish;

  #вставляем табличку лучших решений
  my ($best_str) = $$text =~ /\$insert_best_solve\{(.*?)\}/i;

  $query = "select s.id_stat, cast(s.dt_tm as date),cast(s.dt_tm as time), "
          ."s.id_publ, a.name, c.name, s.time_work,s.mem_use "
          ."from best_solve bs "
          ."JOIN status s ON s.id_stat = bs.id_slv "
          ."JOIN author_names a ON a.id_publ = s.id_publ "
          ."JOIN compil c ON c.id_cmp = s.id_cmp "
          ."where s.id_prb=$prb order by s.id_stat desc";

  $sth = $db->prepare($query);
  $sth->execute;

  while (@row = $sth->fetchrow_array) {

     html_text(\$row[4]);
     foreach (@row) {
        #удалим пробелы в конце поля
        $_ =~ / *\Z/;
        $_ = "$`";
        #если поле пусто, то заменим его на длинный пробел
        if ($_ eq "") {$_ =  "&nbsp;";}
     }

     $table_best_slv .= "<tr>"
     ."<td align=center>$row[0]</td>"
     ."<td align=center>$row[1]<br>$row[2]</td>"
     ."<td><a href=/cgi-bin/statistica.pl?id_publ=$row[3]>$row[4]</a></td>"
     ."<td align=center>$row[5]</td>"
     ."<td align=center>$row[6]</td>"
     ."<td align=center>$row[7]</td>"
     ."<td align=center><a class=\"src_lnk1\" href=/cgi-bin/statistica.pl?id_slv=$row[0]>$best_str</a></td>"
     ."</tr>\n";
  }

  $sth->finish;


  $$text =~ s/\$problem_name/$param_row[0]/ig;
  $$text =~ s/\$problem_solved/$param_row[1]/ig;
  $$text =~ s/\$problem_submit/$param_row[2]/ig;
  $$text =~ s/\$problem_sbm_cnt/$param_row[3]/ig;
  $$text =~ s/\$problem_stat/$table_stat/ig;
  $$text =~ s/\$problem_id/$prb/ig;
  $$text =~ s/\$insert_best_solve\{$best_str\}/$table_best_slv/ig;

  $$text =~ s/\$add_param/&id_prb=$prb/ig;

}
  

sub insert_search_list
{
  my($text,$find_author) = @_;

  my @row = ();

  my $find_az=$find_author;
  $find_az =~ s/(%|_)/\?$1/g;
  $find_az =~ s/'/''/g;

  $query ="select a.name, a.id_publ, c.name, 0-a.solve_cnt, a.submit_cnt "
         ."from author_names a, countrs c where c.id_cn=a.id_cn and "
         ."a.name like cast('%$find_az%' as varchar(100) character set win_1251) escape '?' "
         ." order by solve_cnt, submit_cnt, id_publ";

#  to_log($query);

  $sth = $db->prepare($query);
  $sth->execute;

  my $cnt=0;
  my $new_text="";
  while ((@row = $sth->fetchrow_array) && $cnt<100) {
     #заменим <, >, &, " в имени автора
     html_text(\$row[0]);
     foreach (@row) {
        #удалим пробелы в конце поля
        $_ =~ / *\Z/;
        $_ = "$`";
        #если поле пусто, то заменим его на длинный пробел
        if ($_ eq "") {$_ =  "&nbsp;";}
     }
     $new_text .= "<tr>"
     ."<td>$row[2]</td>"
     ."<td><a href=/cgi-bin/statistica.pl?id_publ=$row[1]>$row[0]</a></td>"
     ."<td align=center>$row[3]</td>"
     ."<td align=center>$row[4]</td>"
     ."</tr>\n";
     $cnt++;
  }

  $sth->finish;
  $$text =~ s/\$insert_search_list/$new_text/ig;
  $$text =~ s/\$add_param/&find_author=$find_author/ig;
  $$text =~ s/\$find_value/$find_author/ig;

}

#------------------------
#      Main program
#------------------------

  read_config();
  connect_db();

  #язык по умолчанию
  $sth = $db->prepare("select def_lng from const");
  $sth->execute;
  @row = $sth->fetchrow_array;
  $lng_def=$row[0];
  $sth->finish;

  fcgi_init();
  #$nstep_cnt=0;

main_cik:
  while(next_request()) {
  
  #$nstep_cnt++;

  $db->commit;
  
  CGI::_reset_globals;
  $incgi = new CGI;
    
  #а может прислали cookies
  %cookies = parse CGI::Cookie($ENV{'HTTP_COOKIE'});

  GetLanguage(\$id_lng,\$cookie1); 
 
  $id_user=authenticate_process("true");
  next main_cik if ($id_user.'' eq 'end');

  $rank = $incgi->param("rank")+0;
  $p_grp = $incgi->param("id_grp")+0;
  $topic = $incgi->param("id_topic")+0;
  $id_publ = $incgi->param("id_publ")+0;
  $find_author = $incgi->param("find_author");
  $id_slv = $incgi->param("id_slv")+0;
  $id_stat = $incgi->param("id_stat")+0;
  $id_prb = $incgi->param("id_prb")+0;
  $search_list="";
  if ($id_stat and $id_slv)
  {
    $id_slv = 0; 
  }

  if ($find_author ne "") {

    $find_az="".$find_author;
    $find_az =~ s/(%|_)/\?$1/g;
    $find_az =~ s/'/''/g;
    $sth = $db->prepare("select id_publ from authors where name like cast('%$find_az%' as varchar(100) character set win_1251) escape '?'");
    $sth->execute;
    @row = $sth->fetchrow_array;
    if (@xxx=$sth->fetchrow_array) {
       $search_list="yes";
    }

    $sth->finish;

    if ($search_list eq "") {
       if ($row[0] eq "") {
          print_err("author '$find_author' not found!");
          next main_cik;
       } else {
          $id_publ=$row[0];
       }
    }

  }

  $http_st="200 OK";

  if ($id_publ) {
     $fname = "author_stat_$id_lng.html";

#debug
#  } elsif ($id_slv or $id_stat) {
   } elsif ($id_slv) {

     if (!$id_user) {
        $id_user=authenticate_process()+0;
        if (!$id_user) { next main_cik; }
     }
	

     if ($id_slv)
     {
       $rul=access_solve($id_slv,$id_user,\$who_view,\$id_problem);
#       if ($rul eq "not found"){  
#            print_err("this solve not best!!!");
#            next main_cik; 
#       }

     }

     $fname = "src_$rul"."_$id_lng.html";
  } elsif ($id_prb) {
     $fname = "problem_stat_$id_lng.html";
  } elsif($id_stat) {
     $rul=access_source($id_stat,$id_user,\$who_view,\$id_problem);
     $fname = "src_$rul"."_$id_lng.html";
  }elsif ($search_list ne "") {
     $fname = "search_list_$id_lng.html";
  } else {  #rank - по умолчанию
     $fname = "ranklist_$id_lng.html";
  }

  #откроем шаблон и считаем все строки
  $fh = new IO::File;
  $fh->open("< $DirTemplates\\$fname");
  $string_template=""; 
  while (<$fh>) {
      $string_template .= $_;
  }
  $fh->close;

  #обработаем $include_files(x)
  include_files(\$string_template);

  if ($id_publ) {
    insert_author_stat(\$string_template,$id_publ,$id_lng,$id_user);
  } elsif ($id_slv) {


    if ($rul eq "denied") {
       insert_src_rules(\$string_template,$who_view,$id_problem);
    }
    if (($rul eq "view") || ($rul eq "full")) {
       insert_src_atr(\$string_template,$id_slv,$id_lng,$lng_def);
    }
    if ($rul eq "full") {
       $acc = $incgi->param("access");
       if (($acc eq "n") || ($acc eq "s")) {
          $sth = $db->prepare("update best_solve set who_view='$acc' where id_slv=$id_slv");
          $sth->execute;
          $db->commit;
          $who_view=$acc;
        }

      insert_src_atr_dop(\$string_template,$id_slv,$who_view);
    }

    $string_template =~ s/\$add_param/&id_slv=$id_slv/ig;
  } 
  elsif ($id_prb) {
    insert_problem_stat(\$string_template,$id_prb,$id_lng,$lng_def);

    $id_stat=$incgi->param("id_stat")+0;
    if ($id_stat==0) {
       $id_stat=2_000_000_000;
    }
    insert_status_rows(\$string_template,$id_lng,$id_stat,$id_prb,$id_user,0);
  } elsif ($search_list ne "") {
    insert_search_list(\$string_template,$find_author);
  } 
  elsif ($id_stat) {
    if ($rul eq "denied") {
       insert_src_rules(\$string_template,$who_view,$id_problem);
    }
    if (($rul eq "view") || ($rul eq "full")) {
       insert_src_atr2(\$string_template,$id_stat,$id_lng,$lng_def);
    }

    if ($rul eq "full") {
       $acc = $incgi->param("access");
       if (($acc eq "n") || ($acc eq "s")) {
          $sth = $db->prepare("update status set who_view='$acc' where id_stat=$id_stat");
          $sth->execute;
          $db->commit;
          $who_view=$acc;
         }
     
     insert_src_atr_dop(\$string_template,$id_stat,$who_view);
   }

   $string_template =~ s/\$add_param/&id_stat=$id_stat/ig;
  }
  else {
    if (!$rank) { $rank=-1; }
    if ($id_user==0) { $p_grp=0; }
    insert_ranklist(\$string_template,$rank,$p_grp,$id_lng,$id_user,$topic);
  }

  login_info(\$string_template,$id_user);

  #обработаем $current_page
  current_page(\$string_template);

  $string_template =~ s/<!--.*?-->//sg;
  
  print header(-charset=>"Windows-1251",
               -cookie=>[$cookie1],
               -cache_control=>"no-cached",
               -pragma=>"no-cache",
               -status=>"$http_st"
               );
  print "$string_template";

  }  
  print "\n";
#  $db->disconnect;

POSIX:_exit(0);
