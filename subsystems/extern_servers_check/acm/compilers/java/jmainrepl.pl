open $f,"<",$ARGV[0];
while ($q=<$f>) 
{
  $s = $s.$q;
}
if ($s =~ m/public\s+(static\s+)?class\s+(\w+)/s)
{
  $s =~ s/$2/$ARGV[1]/sg;
}
print $s;
 