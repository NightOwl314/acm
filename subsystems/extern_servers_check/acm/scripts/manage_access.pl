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

#   to_log("request from user");

   $db->commit();


   CGI::_reset_globals;
   $incgi = new CGI;
   
   #а может прислали cookies
   %cookies = parse CGI::Cookie($ENV{'HTTP_COOKIE'});

   $p_mode=$incgi->param("mode");
   $p_id_publ=$incgi->param("id_publ")+0;

   $id_user=authenticate_process("",'access_change_grp_user($id_publ)')+0;
   if (!$id_user) { next main_cik; }
   
   
   $id_lng='';
   GetLanguage(\$id_lng,\$cookie1); 

   %templ_hash = (change_grp      => "change_groups_user_$id_lng.html",
                  change_grp_post => "change_groups_user_$id_lng.html");
   
   if (!exists $templ_hash{$p_mode}) {
      #по умолчанию надо ЧЕГО-ТО делать
      #$p_mode = "XXX";
      print_err('parameters is invalid!!!');
      next main_cik;
   }
 
   if ($p_mode eq 'change_grp_post') {
      save_user_groups($p_id_publ,$id_user);
      
      $new_url=$ENV{"SCRIPT_URI"};
      $new_url =~ s/\?.*$//;
      $new_url =~ s/\/[^\/]*$/\/statistica.pl?id_publ=$p_id_publ/;
      print header(-status=>"301 Moved Permanently",
                   -Location=>$new_url);
      next main_cik;
   }
   
   $templ_nm = $templ_hash{$p_mode};

   #откроем шаблон и считаем все строки
   $string_template='';
   read_file("$DirTemplates\\$templ_nm",\$string_template);

   if ($p_mode eq "change_grp" || $p_mode eq "change_grp_post") {
      insert_groups(\$string_template,$id_lng,$p_id_publ,$id_user);
      insert_author_atr(\$string_template,$p_id_publ);
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
$db->disconnect;


#------------------------
#      Functions
#------------------------

sub insert_groups
{
   my ($text,$id_lng,$id_publ,$id_user) = @_;
   
   my $sect_grp,$s,$before,$after,$query,$mngr_sys=0,$single_offset,$offset;

   $$text =~ s/<!--start_offset_group-->(.*?)<!--finish_offset_group-->//mi;
   $single_offset=$1;

   $$text =~ m/<!--start_group-->(.*?)<!--finish_group-->/si;
   $before=$`;
   $sect_grp=$1;
   $after=$';

   $query=<<SQL;
 select ggb.id_grp,ggb.id_level, gl.name,
        case when ggb.default_grp>0 or ggb.is_boss>0 then 1 else 0 end,
    (select id_publ from groups_authors where id_publ=$id_publ and id_grp=ggb.id_grp)
   from get_groups_boss($id_user) ggb inner join groups_lng gl
      on ggb.id_grp=gl.id_grp and gl.id_lng='$id_lng'
   order by ggb.n_ord
SQL

   my $sth=$db->prepare($query);
   $sth->execute();
   
   while (my @row=$sth->fetchrow_array) {
      $offset=$single_offset x ($row[1]-1);
      $row[2] =~ s/ *$//;

      $s=$sect_grp;
      $s =~ s/\$id_grp/$row[0]/ig;
      $s =~ s/\$is_enbl\$\{(.*?)\|(.*?)\}/$row[3]>0?$1:$2/eig;
      $s =~ s/\$is_selected\$\{(.*?)\|(.*?)\}/$row[4]>0?$1:$2/eig;
      $s =~ s/\$group_name/$row[2]/ig;
      $s =~ s/\$offset_group/$offset/ig;
      

      $before.=$s;
   }
   $sth->finish();

   $$text=$before.$after;
}

#-------------------------------------------------
sub insert_author_atr
{
   my ($text,$id_publ) = @_;
   my $query,$sth,@row;
   $query="select id_publ, name from authors where id_publ=$id_publ";
   $sth=$db->prepare($query);
   $sth->execute();
   
   @row=$sth->fetchrow_array;
   $sth->finish();
   $row[1]=~s/ *\Z//;
   html_text(\$row[1]);
   $$text =~ s/\$author_id/$row[0]/ig;
   $$text =~ s/\$author_name/$row[1]/ig;

}


#-------------------------------------------------
sub save_user_groups
{
   my ($id_publ,$id_user) = @_;
   my $query,$sth,@row;
   my @groups=(),$s,$i,$k;

   @groups=$incgi->param("groups_list");
   @groups = grep ($_+=0,@groups);

   $s=join(',',0,@groups);

   $query=<<SQL;
select ggb.id_grp
  from get_groups_boss($id_user) ggb left outer join groups_authors ga
     on ggb.id_grp=ga.id_grp and ga.id_publ=$id_publ
   group by ggb.id_grp,ga.id_grp
   having (ggb.id_grp in ($s) and max(ggb.is_boss+ggb.default_grp)>0) or
          (ga.id_grp is not null and max(ggb.is_boss+ggb.default_grp)=0)
SQL
   $sth=$db->prepare($query);
   $sth->execute();
      
   @groups=();
   while(($i)=$sth->fetchrow_array) {
      push(@groups,($i));
   }
   $sth->finish();
   $s=join(',',0,@groups);
      
   $query="select count(*) from groups where id_grp in ($s)";
   $sth=$db->prepare($query);
   $sth->execute();
   ($i)=$sth->fetchrow_array;
   $sth->finish();
      
   if ($i>0 && $i == $#groups+1) {
   
      $query="delete from groups_authors where id_publ = $id_publ";
      $sth=$db->prepare($query);
      $sth->execute();

      $query="insert into groups_authors(id_grp,id_publ) values(?,$id_publ)";
      $sth=$db->prepare($query);
      foreach $k (@groups) {
         $sth->execute($k);
      }
      
      $db->commit();
   }

}


