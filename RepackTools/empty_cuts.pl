opendir(dd,"/dev/shm/t/gta/unpacked/anim/cuts");
@files=grep{/cut$/}readdir(dd);
closedir(dd);

$outpath='/dev/shm/mini/cuts';


$cut_template=<<CODE;
info
offset 2484.087891 -1722.250000 12.620000
end
model
end
text
end
uncompress
end
motion
end
CODE

$cut_template=~s/[\r\n]+/\r\n/sg;

@dat_counts=qw/3 3 9 9/;

$dat_template="";
for($s=0;$s<4;$s++){
$dat_template.="2,\r\n";
for($w=0;$w<2;$w++){
$dat_template.="".($w*3).".000000f,".join("",map{($w*int(rand()*10)).".0,"}(1..$dat_counts[$s]))."\r\n";
}
$dat_template.=";\r\n";
}
$dat_template.=";\r\n";



foreach $cutfile(@files){
print STDERR "Processing cutscene $cutfile\n";
open(oo,">$outpath/".$cutfile);
print oo $cut_template;
close(oo);

$datfile=$cutfile;
$datfile=~s/cut$/dat/s;

open(oo,">$outpath/".$datfile);
print oo $dat_template;
close(oo);

$ifpfile=$cutfile;
$ifpfile=~s/cut$/ifp/s;

open(dd,"/dev/shm/t/gta/unpacked/anim/cuts/".$ifpfile) or die "Can't open source $ifpfile: $!";
binmode(dd);
seek(dd,0x14,0);
read(dd,$animname,8);
close(dd);


open(oo,">$outpath/".$ifpfile);
print oo pack("A4IA4IIZ8","ANPK",20,"INFO",12,0,$animname);
close(oo);


}




