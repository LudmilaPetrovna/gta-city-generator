
open(dd,$ARGV[0]);
$prevuniq="";
$prev_x=0;
$prev_y=0;
$prev_z=0;
while(<dd>){
tr/\r\n//d;
($pos_x,$pos_y,$pos_z)=split(',');

$uniqpos=int($pos_x/2).':'.int($pos_y/2).':'.int($pos_z/2);
if($prevuniq eq $uniqpos){next;}
$prevuniq=$uniqpos;

$dx=$prev_x-$pos_x;
$dy=$prev_y-$pos_y;
$dz=$prev_z-$pos_z;

$len=sqrt($dx**2+$dy**2+$dz**2);
if($len<5){next;}

$pos_z-=.55;
push(@points,"$pos_x $pos_y $pos_z 0\n");

}

$count=@points;


for($t=1;$t<=4;$t++){
open(oo,">tracks".($t>1?$t:"").".dat");
print oo "$count\n";
print oo @points;
close(oo);
}

