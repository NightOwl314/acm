#!c:\perl\bin\perl.exe

use DBI;
use FCGI;
use IO;
use CGI qw(:standard);
use CGI::Cookie;
use Win32::Mutex;
use Win32::Process;
use CGI::Carp  qw(fatalsToBrowser);

require 'common_func.pl';
use vars qw($request $out_stream $db $DirSrcArh $DirTemp $DirTempSrc 
            $master_config $this_script $incgi %ENV %cookies %Compilers);


  read_config();
  connect_db();

  $this_script = '/cgi-bin/admin.pl'; ;#$env{"SCRIPT_NAME"};

  fcgi_init();

main_cik:
  while(next_request()) {

    $db->commit;

    CGI::_reset_globals;
    $incgi = new CGI;
    
    # $user=authenticate_process("",'is_manage_system($id_publ)')+0;
    # if (!$user) { next main_cik; }
    $user=21916;

    #а может прислали cookies
    %cookies = parse CGI::Cookie($ENV{'HTTP_COOKIE'});
    $cookie1 = undef;

    $add_wl = $incgi->param("add_wl");
    $id_report = $incgi->param("id_report")+0;
    $id_source = $incgi->param("id_source")+0;
    $srv_manager = $incgi->param("manager")+0;
    $p_id_srv = $incgi->param("id_srv")+0;
    $p_host = $incgi->param("host");
    $p_host =~ s/([\w\d-\.]*)/$1/;
    
    $p_cpu = $incgi->param("cpu")+0;

    $id_rejudge = $incgi->param("id_rejudge")+0;
    $grp_rejudge = $incgi->param("grp_rejudge");
    $grp_rejudge1 = $incgi->param("grp_rejudge1");
    $set_filter = $incgi->param("set_filter");

    $sn=$ENV{"SERVER_NAME"};
    if ($ENV{"SERVER_PORT"} != 80) {
      $sn .= ":".$ENV{"SERVER_PORT"};
    }

    if ($add_wl ne "") {
      $id_compil = $incgi->param("compiler");
      $content = add_in_whitelist($add_wl,$id_compil);
      $content = "<html><head><title>White list for compiler_id=$id_compil</title>"
                ."</head><body><a href=\"$this_script\">go main page</a>"
                ."<h2>Total white list</h2><pre>$content</pre></body></html>";

    } elsif ($id_report) {

      read_file("$DirSrcArh\\".sprintf('%x',$id_report).".otch",\$content);
      if ($content eq "") {$content = "Report not found!!!"; }
      $content = "<html><head><title>Admin monitor</title></head>"
      ."<body><a href=\"$this_script\">go main page</a>"
      ."<h2 align=center>Run time report</h2>$content</body></html>";

    } elsif ($id_source) {

      read_file("$DirSrcArh\\".sprintf('%x',$id_source).".src",\$content);
      if ($content eq "") {$content = "Source not found!!!"; }
      html_text(\$content);

      $content = "<html><head><title>Admin monitor</title></head>"
      ."<body><a href=\"$this_script\">go main page</a>"
      ."<h2 align=center>Source</h2><pre>$content</pre></body></html>";

    } elsif ($srv_manager) {

      server_manager($srv_manager,$p_id_srv,$p_host,$p_cpu);

      print "Location: http://$sn$this_script\n\n";
      next main_cik;

    } elsif ($id_rejudge) {

      $rezult = rejudge_status($id_rejudge);

      if ($rezult==1) {
        $db->commit;
        #server_manager(4); #rescan db
        print "Location: http://$sn$this_script\n\n";
      } else {
        print_err("$rezult");
      }

      next main_cik;

    } elsif ($grp_rejudge ne "") {

      $rezult = rejudge_group($grp_rejudge,1);

      if ($rezult==1) {
        rejudge_group($grp_rejudge,0);
        $db->commit;
        #server_manager(4); #rescan db
        print "Location: http://$sn$this_script\n\n";
        next main_cik;

      } else {
      $content = "<html><head><title>Admin monitor</title></head>"
      ."<body><a href=\"$this_script\">go main page</a>"
      ."<h2 align=center>Error</h2><pre>$rezult</pre>"
    .'<form action="'.$this_script.'" method="GET">
      <input type=hidden name="grp_rejudge1" value="'.$grp_rejudge.'">
      <input type=submit value="Continue (delete records for sources not found)">
      </form></body></html>';

      }

    } elsif ($grp_rejudge1 ne "") {

      $rezult = rejudge_group($grp_rejudge1,0);
      $db->commit;
      #server_manager(4); #rescan db
      print "Location: http://$sn$this_script\n\n";
      next main_cik;

    } elsif ($set_filter ne "") {

      set_status_filter($user,$set_filter);

      #print "Location: http://$sn$this_script\n\n";
      $new_url=$ENV{"SCRIPT_URI"};
      print header(-status=>"301 Moved Permanently",
                   -Location=>$new_url);
      next main_cik;

    } else {

      $id_stat=$incgi->param("id_stat")+0;
      if ($id_stat==0) {
         $id_stat_s = $cookies{"id_stat"};
         $find_substr = $id_stat_s =~ m/\s*id_stat\s*=\s*(\w*)/;
         if ($find_substr) {$id_stat = "$1"+0;}

         if ($id_stat==0 || $id_stat==-1) {
            $id_stat=2_000_000_000;
         }
      } else {
        $cookie1 = new CGI::Cookie(-name=>"id_stat",-value=>"$id_stat",-path=>"$this_script");
        if ($id_stat==-1) { $id_stat=2_000_000_000; }
      }

      
      $content = '<html><head><title>Admin monitor</title></head><body>
       <a href="/cgi-bin/arh_problems.pl">go user interface</a>
       <h2>Servers manager</h2>
      Servers list: <br>'.get_servers_status().'
      <table cellpadding="5"><tr><td>
      <form action="'.$this_script.'" method="GET">
      <input type="hidden" name="manager" value="1">
      <input type="submit" value="Start ALL available">
      </form></td><td>
      <form action="'.$this_script.'" method="GET">
      <input type="hidden" name="manager" value="2">
      <input type="submit" value="Stop ALL">
      </form></td></tr></table>
      <p>Input WHERE section of SQL-query (for table STATUS)</p>
      <p>Defined fields: problem_id, result_id, warn_result, author_id, compiler_id, status_id, date_time, test_num.</p>
      <p>Example: <i>problem_id=5 and result_id=6</i></p>
      <table border="0" cellpadding="0"><tr><td>
      <h4>Rejudge group of submitions</h4>
      <form action="'.$this_script.'" method="GET">
      <textarea name="grp_rejudge" rows=4 and cols=50></textarea>
      <input type=submit value="Send">
      </form>
      </td><td>&nbsp;&nbsp;&nbsp;&nbsp;</td><td>
      <h4>Filter submisions</h4>
      <form action="'.$this_script.'" method="GET">
      <textarea name="set_filter" rows=4 and cols=50>'.get_status_filter($user).'</textarea>
      <input type=submit value="Send">
      </form>
      </td></tr></table>
      <h2 align=center>On-line status</h2>'.get_status_rows($id_stat,15,$user)
      .'</body></html>';
    }

    print header(-charset=>"Windows-1251",
               -cookie=>[$cookie1],
               -cache_control=>"no-cached",
               -pragma=>"no-cache",
               );

    print $content;

  }

  $db->disconnect;


#------------------------
#      Functions
#------------------------


sub add_in_whitelist
{
     my ($add_wl,$id_compil) = @_;
     my $content_wl="",$fh;
     my $path_wl = $Compilers{$id_compil}->{'WhiteListFile'};

     #читаем весь белый список
     read_file("$path_wl",\$content_wl);

     my $dll_name="";
     my $dll_find=0;
     my $func_name="";
     my $callcnt=0;
     my $func_find=0;

     while (($dll_name) = $add_wl =~ m/dll=(\S+)/s) {

        $dll_find = $content_wl =~ m/dll=$dll_name/s;
        if ($dll_find == 0) {
           $content_wl .= "\ndll=$dll_name\n";
        }
        while (($func_name,$callcnt) = $add_wl =~ m/dll=$dll_name\s+(\S+)\s+([-\d]+)/s) {
           $func_find = $content_wl =~ m/dll=$dll_name[^=]+?$func_name\s+([-\d]+)/s;
           if ($func_find == 0) {
              $content_wl =~ s/(dll=$dll_name\n)/$1   $func_name $callcnt\n/s;
           } elsif ($1!=-1 && $callcnt>$1) {
                 $content_wl =~ s/(dll=$dll_name[^=]+?$func_name\s+)([-\d]+)/$1$callcnt/s;

           }

           $add_wl =~ s/$func_name\s+$callcnt//s;
        }

        $add_wl =~ s/dll=$dll_name//s;
     }

     $fh=new IO::File;
     $fh->open("> $path_wl");
     print $fh $content_wl;
     $fh->close;

     return $content_wl;
}


#sub access_admin
#{
#   my ($login)=@_;
#
#   $master_config =~ m/\n\s*\[options\]([^\[]*)/s;
#   my $section = $1;
#   $section =~ m/^\s*AdminLogin\s*=\s*([^\n]*)/m;
#
#   if ($1 ne $login) {
#      return "denied";
#   }
#   $section =~ m/^\s*AdminPassword\s*=\s*([^\n]*)/m;
#
#   my $auth_st = authenticate($login,$1,"admin_area");
#
#   if ($auth_st eq "true") {
#      return "OK";
#   }
#
#   if ($auth_st eq "change") {
#      return "ch_nonce";
#   }
#   return "denied";
#}

sub get_status_rows
{

  my ($id_stat,$record_count,$user) = @_;
  my $filter,$query,$query0,$sth;
  
  $filter=get_status_filter($user);
  $filter =~ s/problem_id/s.id_prb/g;
  $filter =~ s/result_id/s.id_rsl/g;
  $filter =~ s/warn_result/s.warn_rsl/g;
  $filter =~ s/author_id/s.id_publ/g;
  $filter =~ s/compiler_id/s.id_cmp/g;
  $filter =~ s/status_id/s.id_stat/g;
  $filter =~ s/date_time/s.dt_tm/g;
  $filter =~ s/test_num/s.test_no/g;

  $filter =~ s/ *$//m;
  if ($filter) {
     $filter=' and '.$filter;
  }

  $query0="select s.id_stat, cast(s.dt_tm as date),cast(s.dt_tm as time), "
      ."s.id_publ, a.name, s.id_prb, "
      ."r.name,s.test_no, s.id_rsl "
      ."from status s "
      ."JOIN authors a ON a.id_publ = s.id_publ "
      ."JOIN results_lng r ON (r.id_rsl = s.id_rsl) and (r.id_lng=(select def_lng from const)) "
      ."where s.id_stat<$id_stat \$filter "
      ."PLAN JOIN (S INDEX (STATUS_IDX1), "
      ."A INDEX (RDB\$PRIMARY107), "
      ."R INDEX (RDB\$PRIMARY113)) "
      ."order by s.id_stat desc";
  
  $query=$query0;
  $query =~ s/\$filter/$filter/ig;
  $db->{PrintError}=0;
  $sth = $db->prepare($query);
  if ($sth) {
     $sth->execute;
  } else {
     set_status_filter($user,'');
     $query=$query0;
     $query =~ s/\$filter//ig;
     $sth = $db->prepare($query);
     $sth->execute;
  }
  $db->{PrintError}=1;

  my $string_table="";
  my $cnt=0;
  my $prev_rec=0;
  my $next_rec=0;
  my @row = ();
  my $test_n="";
  while ((@row = $sth->fetchrow_array) && $cnt<$record_count) {
     if ($cnt==0) { $prev_rec= $row[0]+$record_count+1; } 
     if ($cnt==$record_count-1) { $next_rec= $row[0]; } 
     #заменим <, >, &, " в имени автора
     html_text(\$row[4]);
     foreach (@row) {
        #удалим пробелы в конце поля
        $_ =~ s/ *\Z//;
        #если поле пусто, то заменим его на длинный пробел
        if ($_ eq "") {$_ = "&nbsp;";}
     }

     if ($row[7] == 0) { $test_n=""; }
     else { $test_n="($row[7])"; }

     $string_table .= "<tr>"
     .'<td align=center><a href="/cgi-bin/status.pl?mode=report&id_stat='.$row[0].'">'.$row[0].'</a></td>'
     ."<td align=center>$row[1]<br>$row[2]</td>"
     ."<td>$row[4] \[$row[3]\]</td>"
     ."<td align=center>$row[5]</td>"
     ."<td align=center>$row[6] $test_n</td>";
     if ($row[8]<100) {
        $string_table .=
        "<form action=$this_script method=GET><td align=center><input type=\"hidden\" name=\"id_rejudge\" value=\"$row[0]\"><input type=\"submit\" value=\"rejudge\"></td></form>"
       ."<form action=$this_script method=GET><td align=center><input type=\"hidden\" name=\"id_report\" value=\"$row[0]\"><input type=\"submit\" value=\"view report\"></td></form>"
       ."<form action=$this_script method=GET><td align=center><input type=\"hidden\" name=\"id_source\" value=\"$row[0]\"><input type=\"submit\" value=\"view source\"></td></form>";
     } else {
        $string_table .= "<td>&nbsp;</td><td>&nbsp;</td><td>&nbsp;</td>"
     }

     $string_table .= "</tr>\n";
     $cnt++;
  }

  $sth->finish;

  my $text="<table WIDTH=100% border=1 align=center cellspacing=1 cellpadding=5>"
    ."<tr><TH ALIGN=CENTER WIDTH=50>ID</TH>"
    ."<TH ALIGN=CENTER WIDTH=75>Date</TH>"
    ."<TH ALIGN=CENTER WIDTH=\"*\">Author</TH>"
    ."<TH ALIGN=CENTER WIDTH=55>Problem</TH>"
    ."<TH ALIGN=CENTER WIDTH=160>Result (test)</TH>"
    ."<TH ALIGN=CENTER WIDTH=70>&nbsp;</TH>"
    ."<TH ALIGN=CENTER WIDTH=100>&nbsp;</TH>"
    ."<TH ALIGN=CENTER WIDTH=110>&nbsp;</TH></tr>"
    ."$string_table</table><TABLE WIDTH=100% BORDER=0><TR>"
    ."<TD WIDTH=50% ALIGN=RIGHT><a href=$this_script?id_stat=-1>TOP</a>&nbsp"
    ."<a href=$this_script?id_stat=$prev_rec>Previous $record_count</a>&nbsp"
    ."<a href=$this_script?id_stat=$next_rec>Next $record_count</a>&nbsp</TD></TR></TABLE>\n";

  return $text;
}


sub server_manager
{
  my ($st,$id_srv,$host,$cpu) = @_;
  
  my $query,$sth;

  if ($st==1) {
    start_servers($host,$cpu);
  } elsif ($st==2) {
    if ($id_srv) {
       $query="delete from test_servers where id_srv=$id_srv";
    } else {
       $query="delete from test_servers";
    }
    $sth=$db->prepare($query);
    $sth->execute();
    $db->commit;
  }
  sleep(1);
}


sub rejudge_status
{
  my ($id_stat,$prover) = @_;
  my $hex_name,$src,$query,$sth,@row,$tmpl_src,$fh;

  $hex_name=sprintf('%x',$id_stat);
  read_file("$DirSrcArh\\$hex_name.src",\$src);
  if (!$src) { return "file source $hex_name.src not found in arhive!!!"; }

  $query = "select id_cmp from status where id_stat=$id_stat and id_rsl<100";
  $sth = $db->prepare($query);
  $sth->execute;
  @row = $sth->fetchrow_array;
  $sth->finish;

  if ($row[0] eq "") { return "record id_stat=$id_stat not found in database!!!"; }

  if ($prover) { return 1; }

  $tmpl_src = $Compilers{$row[0]}->{'FileIn'};
  $tmpl_src =~ s/\$\(id\)/$hex_name/;

  $fh=new IO::File;
  $fh->open("> $DirTempSrc\\$tmpl_src");
  print $fh $src;
  $fh->close;

  $query = "update status set id_rsl=100, test_no = null,time_work = null,"
          ."mem_use = null where id_stat=$id_stat";

  $sth = $db->prepare($query);
  $sth->execute;

  return 1;
}


sub rejudge_group
{
   my ($where_sec,$prover) = @_;

   $where_sec =~ s/problem_id/id_prb/g;
   $where_sec =~ s/result_id/id_rsl/g;
   $where_sec =~ s/warn_result/warn_rsl/g;
   $where_sec =~ s/author_id/id_publ/g;
   $where_sec =~ s/compiler_id/id_cmp/g;
   $where_sec =~ s/status_id/id_stat/g;
   $where_sec =~ s/date_time/dt_tm/g;
   $where_sec =~ s/test_num/test_no/g;

   my $query = "select id_stat from status where $where_sec";
#   print_err($query);
   my $sth = $db->prepare($query);
   $sth->execute;
   my @row = ();
   my @all_rows = ();
   my $cnt=0;
   my $rezult="";
   my $rs=0;

   while (@row = $sth->fetchrow_array) {
      $all_rows[$cnt++]=$row[0];
   }
   $sth->finish;

   my $id_s = 0;
   foreach $id_s (@all_rows) {
      $rs = rejudge_status($id_s,$prover);
      if ($rs != 1) {
         $rezult .= "$rs<br>";
      }
      if (($prover==0) && ($rs != 1)) {
         $sth = $db->prepare("update status set id_rsl=100 where id_stat=$id_s");
         $sth->execute;
         #$sth->finish;
         $sth = $db->prepare("delete from status where id_stat=$id_s");
         $sth->execute;
         #$sth->finish;
      }
   }

   if ($rezult eq "") { return 1; }
   else  { return $rezult; }

}


sub get_servers_status
{
   
   my @servers=(),$query,$sth,@row=(),$text='';
   my %srv=(),%srv_cpu=(),$k='',$old_host='',$cpu='',$i=0;

   get_runing_servers(\@servers);
   #return '<div>Error</div>';
   parse_servers_cfg(\%srv,\%srv_cpu);

   $query='select id_srv,upper(host_name),pid,processor_num,testing,start_time,last_test_time,testing_time
           from test_servers where id_srv in ('.join(',',0,@servers).') order by host_name,processor_num,pid';

   #to_log("query=$query");
   $sth=$db->prepare($query);
   $sth->execute();
   while (1) {
      @row=$sth->fetchrow_array;
      $row[1] =~ s/ *$//m if @row;
      $old_host=$row[1] if (@row && !$i);

      #to_log('row='.@row."; i=$i; old_host=$old_host;");

      if (!@row || ($old_host ne $row[1])) {
         foreach $k (keys %srv_cpu) {
            if (!$i || ($k =~ m/$old_host\$/)) {
               
               ($old_host,$cpu)=($k =~ m/(.+)\$(.+)/);
               while ($srv_cpu{$k}>0 && $srv{$old_host}>0) {

      $text.="<tr><td>$old_host</td><td>&nbsp;</td><td>$cpu</td>"
            .'<td>Stopped</td><td>&nbsp;</td><td>&nbsp;</td><td>&nbsp;</td>
             <td align="center"><form action="'.$this_script.'" method="GET">
             <input type="hidden" name="manager" value="1">
             <input type="hidden" name="host" value="'.$old_host.'">
             <input type="hidden" name="cpu" value="'.$cpu.'">
             <input type="submit" value="Start" style="width:100%;">
             </form></td></tr>';
                  
                  $srv_cpu{$k}--;
                  $srv{$old_host}--;
               }
            
            }
         }
         if ($i>0 && !@row) {
            $i=0;
            next;
         }

         last if (!@row);
      }

      grep($_=($_.'' ne '')?$_:'&nbsp;',@row);
      $text.="<tr><td>$row[1]</td><td>$row[2]</td><td>$row[3]</td>"
            ."<td>".($row[4]?"Testing":"Wait")."</td><td>$row[5]</td><td>$row[6]</td><td>$row[7]</td>"
            .'<td align="center"><form action="'.$this_script.'" method="GET">
             <input type="hidden" name="manager" value="2">
             <input type="hidden" name="id_srv" value="'.$row[0].'">
             <input type="submit" value="Stop" style="width:100%;">
             </form></td></tr>';

      
      if (exists $srv{$row[1]}) {
         $srv{$row[1]}--;
      }

      $k=$row[1].'$'.$row[3];
      if (exists $srv_cpu{$k}) {
         $srv_cpu{$k}--;
      }

      $old_host=$row[1];
      $i++;
   }
   $sth->finish();

   $text='<table border="1" cellspacing="1" cellpadding="5">
          <tr><th width="130">Host name</th>
          <th width="50">PID</th>
          <th width="50">#CPU</th>
          <th width="60">Status</th>
          <th width="140">Start</th>
          <th width="140">Last test</th>
          <th width="90">Total testing<br> time(sec)</th>
          <th width="90">&nbsp;</th>
          </tr>'.$text.'</table>';

   return $text;
}

#--------------------------------------------------------
sub set_status_filter
{
   my ($user,$filter) = @_;
   my $query,$sth;

   $query="update authors set filter_sbm=? where id_publ=$user";
   $sth=$db->prepare($query);
   $sth->execute($filter);
   $db->commit;

}

#--------------------------------------------------------
sub get_status_filter
{
   my ($user) = @_;
   my $query,$sth,$filter;

   $query="select filter_sbm from authors where id_publ=$user";
   $sth=$db->prepare($query);
   $sth->execute();
   ($filter)=$sth->fetchrow_array;
   $sth->finish();

   return $filter;
}



