open $f,"<",$ARGV[0];
while ($q=<$f>) 
{
  $s = $s.$q;
}
close $f;
$s =~ m/public\s+(static\s+)?class\s+(\w+)/sg;
open $manifest, ">", "manifest.mf";
$classname = $2;
print $manifest "Main-Class: $classname\n";
close $manifest;

#переименовываем файл
rename $ARGV[0], "$classname.java";

#компилируем
$cmd = "\"C:\\prog\\src\\java\\jdk1.8.0_91_x64\\bin\\javac\" $classname.java 2>&1";
$err_code = system($cmd);
exit($err_code);
