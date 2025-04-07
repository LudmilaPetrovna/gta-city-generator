open(dd,"gta_sa.exe");
read(dd,$file,-s(dd));


$town="00 80 3B 45 00 C0 05 44 00 00 00 00 00 E0 DB 44 00 00 10 44 00 00 00 00 00 40 77 44 00 40 2D 44 00 00 00 00 00 00 00 C3";
$town=~s/(\S\S)\s*/pack("C",hex($1))/egs;
$town_file=index($file,$town);
$town_mem=0x8A5EC8;


for($q=0;$q<length($town);$q+=4){
printf("%04x: %.3f\n",$q,unpack("f",substr($town,$q,4)));
}


$len=length($file);

for($q=0;$q<$len;$q++){
if(($q%123500)==0){print STDERR "Searching at offset $q...\n";}
($x1,$y1,$z1,$x2,$y2,$z2)=unpack("ffffff",substr($file,$q,24));

$is_bad=0;
foreach(($x1,$y1,$z1,$x2,$y2,$z2)){
$str="$_:";
if(length($str)>7 || $str eq "NaN:"){$is_bad=1;last;}

}

if($is_bad){next;}

if($x1==$y1 && $z1==$x2 && $y2==$z2){next;}
if($x1==0 && $y1==0 && $z1==0){next;}

if(
$x1>=-3000 && $x1<=3000 && $y1>=-3000 && $y1<=3000 &&
$x2>=-3000 && $x2<=3000 && $y2>=-3000 && $y2<=3000){

$mem=$q-$town_file+$town_mem;
printf("%08x (mem:%08x):",$q,$mem);
print " ($x1,$y1,$z1,$x2,$y2,$z2)\n";
$q+=24-1;
}




}
