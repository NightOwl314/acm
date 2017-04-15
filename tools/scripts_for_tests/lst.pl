$n = $ARGV[0];
open F, ">index.lst";
for($i=1; $i<=$n; $i++)
{
  print F "$i\n";
}
close F;
