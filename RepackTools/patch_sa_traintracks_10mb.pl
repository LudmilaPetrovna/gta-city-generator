open(dd,"gta_sa.exe");
read(dd,$file,-s(dd));

$sign="\x68".pack("I",46384);
$replacement="\x68".pack("I",10*1024*1024);

$len=length($file);

$pos=0;
while($pos>=0){
$pos=index($file,$sign,$pos+1);
if($pos>=0){
substr($file,$pos,5)=$replacement;
print "Patched at $pos\n";
}

}

open(oo,">gta_sa_patched.exe");
print oo $file;
close(oo);
close(dd);
rename("gta_sa.exe","gta_sa.exe.old");
rename("gta_sa_patched.exe","gta_sa.exe");

