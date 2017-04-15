#!c:\perl\bin\perl.exe

   use IO;

   $n_pas0=$ARGV[0];
   $n_pas1=$ARGV[1];
   
   print "Deleter Delphi preprocess v0.01\n";

   $f_in=new IO::File;
   $f_in->open("< $n_pas0");
   $f_out=new IO::File;
   $f_out->open("> $n_pas1");

   $text='';
   while($ln=<$f_in>) {
      $text.=$ln;
   }

   $pp_cnt1=$text =~ s/\{\$[\w\s\-\+\d\,\:\.\n]+\}//gm;
   $pp_cnt2=$text =~ s/\(\*\$[\w\s\-\+\d\,\:\.\n]+\*\)//gm;

   print "Delete sections: ".($pp_cnt1+$pp_cnt2)."\n";
   print $f_out $text;

   $f_in->close;
   $f_out->close;
