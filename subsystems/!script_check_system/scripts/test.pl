use Error qw(:try);
try{
print "Ok";
}
catch Error with{
}
finally {
 print  "fin"
}
