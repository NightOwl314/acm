#!c:\perl\bin\perl.exe

#Удаляем старые неверные исходники и отчеты

use DBI;
use IO;
use POSIX;

require 'common_func.pl';
use vars qw($request $db $DirTemplates $incgi %cookies %ENV);

read_config();
connect_db();

$query=<<SQL;
       select id_stat from status where dt_tm<'01.10.2008' and id_rsl<>0
SQL
              
 $sth = $db->prepare($query);
 $sth->execute;

 while (@row=$sth->fetchrow_array) {
   $hex_name=sprintf('%x',$row[0]);
   $mv1 = "move $DirSrcArh\\$hex_name.src c:\\temp\\dir_src\\";
   $mv2 = "move $DirSrcArh\\$hex_name.otch c:\\temp\\dir_src\\";

   `$mv1`;
   `$mv2`;
   
 }