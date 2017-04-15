for ($i=1; $i<=9; $i++)
{
  `ren *.0$i.in $i.in`;
  `ren *.0$i.out $i.out`;
}

for ($i=10; $i<=99; $i++)
{
  `ren *.$i.in $i.in`;
  `ren *.$i.out $i.out`;
}
