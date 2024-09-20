open(dd,"gta_sa.txt");
read(dd,$exe,-s(dd));
close(dd);


open(dd,"files1.txt");
while(<dd>){
chomp;
$_=lc($_);
s/\.\/gta-micro\/clean\///s;
s/gta-micro\/clean\///s;

$fullname=$_;

$suspend=0;
do{
$ok=checkStr($_);
if($ok){
$suspend=1;
}
$ok=(s/^[^\/]+\///s);

} while(!$suspend && $ok);


}

sub checkStr{
my $str=shift;
my $ret=0;
#print "Checking for $str\n";
if(index($exe,$str)>=0){
print "Found $_ ($fullname)\n";
$ret=1;
}

$str=~tr/\//\\/;

if(index($exe,$str)>=0){
print "Found $_ ($fullname)\n";
$ret=1;
}

return($ret);
}












