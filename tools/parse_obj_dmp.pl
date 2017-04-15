#!c:\perl\bin\perl.exe

   use IO;

   %sgm_hash=();

   $n_obj=$ARGV[0];
   $n_dmp=$ARGV[1];
   $n_out=$ARGV[2];
   $type_fl=$ARGV[3];
   
   print "Dump parser v0.01\n";

   $f_dmp=new IO::File;
   $f_dmp->open("< $n_dmp");
   $f_obj=new IO::File;
   $f_obj->open("< $n_obj");
   binmode($f_obj);
   $f_out=new IO::File;
   $f_out->open("> $n_out");
   binmode($f_out);

   #первые 3 строки неинтересны
   $ln=<$f_dmp>;
   $ln=<$f_dmp>;
   $ln=<$f_dmp>;

   print "User segments:\n";

   while ($ln=<$f_dmp>) {
      if ($ln =~ m/([0-9a-fA-F]+)\s+(\w+)/ && $2 eq 'COMDEF') {
         $ln1=<$f_dmp>;
         $ln1 =~ m/\s*Name:\s*\d+\s*:\s*(\w+|\'[^\']+\')\s+virtual\((\w+)\)/;
         $sgm_hash{$1} = $2;
      }
      elsif ($ln =~ m/([0-9a-fA-F]+)\s+(\w+)\s+Segment:\s*(\w+|\'[^\']+\')\s*Offset:\s*([0-9a-fA-F]+)\s*Length:\s*([0-9a-fA-F]+)/i && $2 eq 'LEDATA') {
         $name_seg=$3;
         $offset=hex($1)+0;
         $len=hex($5)+0;
         $name_seg1=$name_seg;
         while($name_seg1=~s/(\<[^\<]+?\>)//g) {;}
         #истина, если секция является данными, а не кодом
         $is_data = $name_seg1=~m/_DATA|__odtbl__|__ectbl__|__chtbl__|__tpdsc__|__thrwl__|__vdthk__/ || $sgm_hash{$name_seg} eq '_DATA';

         if ($type_fl=~m/cpp/) {
            $name_seg2=$name_seg;
            $name_seg2=~s/\W*_STL::\w+\W*//g;
            $is_not_user_code = $name_seg1=~m/_INIT_|\b_?_STL(::[\w~]+)+\(/ || !$name_seg2;
         } elsif ($type_fl=~m/pas/) {
            $is_not_user_code = $name_seg1=~m/_TEXT|_INIT_|Finalization/;
         } elsif ($type_fl=~m/asm/) {
            $is_not_user_code = '';
         } else {
            $is_not_user_code = '';
         }

         if (!$is_data && !$is_not_user_code) {
            if ($name_seg eq "_TEXT") {$offset1=6;}
            else {$offset1=7;}
            $v=seek($f_obj,$offset+$offset1,0);
            read($f_obj,$buffer,$len);
            if (length($buffer)>8) {
               $a1=ord(substr($buffer,0,1))+(ord(substr($buffer,1,1))<<8)+(ord(substr($buffer,2,1))<<16)+(ord(substr($buffer,3,1))<<24);
               $a2=ord(substr($buffer,4,1))+(ord(substr($buffer,5,1))<<8)+(ord(substr($buffer,6,1))<<16)+(ord(substr($buffer,7,1))<<24);
            } else { $a1=$a2=0; }
            #if (!($buffer =~ m/\03\0\0\0\010\0\0\0\0\0\0\0\0\0\0\0/)) {
            if ($a1*$a2+8!=length($buffer)) {
                print "$name_seg; size=$len\n";
                print $f_out $buffer;
            }
         }
      }
   }

   $f_dmp->close;
   $f_obj->close;
   $f_out->close;
