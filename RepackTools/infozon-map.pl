use GD;
require "./gxt_read.pl";
$map=GD::Image->new(6000,6000,1);
$map->saveAlpha(1);
$map->alphaBlending(0);
$map->filledRectangle(0,0,6000,6000,0x7f000000);
$map->alphaBlending(1);


$gta3_root="/dev/shm/cache/img_unpacked/models/gta3";
$infozon="/dev/shm/gta-micro/Clean/data/info.zon";

%zones=();
open(dd,$infozon) or die;
while(<dd>){
if(/^(zone|end)/){next;}
#SFGLF2, 0, -2667.81, -302.135, -28.8305, -2646.4, -262.32, 71.1695, 1, CUNTC^M
tr/\r//d;
chomp;
($zone_id,$type,$x1,$y1,$z1,$x2,$y2,$z2,$level,$label)=split(/\s*,\s*/);
$label=resolve_GXT($label);

if(!exists $zones{$label}){
# bb, area, parent
$zones{$label}=[[],0,-1];
}
updateBB($zones{$label}->[0],$x1,$y1,$z1,$x2,$y2,$z2);
}

foreach $zonename(keys %zones){
$bb=$zones{$zonename}->[0];
$width=$bb->[3]-$bb->[0];
$height=$bb->[4]-$bb->[1];
$area=$width*$height;
$zones{$zonename}->[1]=$area;
}

@zones=sort{$zones{$b}->[1] <=> $zones{$a}->[1]}keys %zones;

$count=@zones;
for($w=0;$w<$count;$w++){
for($q=$w+1;$q<$count;$q++){
$wbb=$zones{$zones[$w]}->[0];
$qbb=$zones{$zones[$q]}->[0];
if($qbb->[0]>=$wbb->[0] && $qbb->[3]<=$wbb->[3]+100 && $qbb->[1]>=$wbb->[1] && $qbb->[4]<=$wbb->[4]+100){
#print "$zones[$q] inside of $zones[$w]\n";
$zones{$zones[$q]}->[2]=$w;
}
}
}

printParent(-1,"",0);


sub printParent{
my $parent=shift;
my $parent_path=shift;
my $level=shift;
my $levelpad=" " x $level;
my $q;

my $is_final=1;
for($q=0;$q<$count;$q++){
if($zones{$zones[$q]}->[2]==$parent){
$is_final=0;
printParent($q,$parent_path."/".$zones[$q],$level+1);
}
}
if($is_final){
$parent_path=~s/[\'\.]//gs;
$parent_path=~s/[^a-zA-Z0-9\/]+/_/gs;
$parent_path=~s/^.//s;
print "$parent_path\n";
}

}

die;

foreach $zonename(keys %zones){

$x1+=3000;
$y1=3000-$y1;
$x2+=3000;
$y2=3000-$y2;

$bb=$zones{$zonename}->[0];

$x1=$bb->[0]+3000;
$y2=3000-$bb->[1];
$x2=$bb->[3]+3000;
$y1=3000-$bb->[4];


$color=int(rand()*256) | (int(rand()*256)<<8) | (int(rand()*256)<<16);
$opacity=0x70;
$filled_color=($opacity<<24)|$color;

$map->filledRectangle($x1,$y1,$x2,$y2,$filled_color);
$map->rectangle($x1,$y1,$x2,$y2,$color);
$map->string(gdSmallFont,$x1+2,$y1+2,$zonename,0);
}

open(oo,">info_zon_map.png");
print oo $map->png(9);
close(oo);



sub updateBB{
my $bb=shift;
my @axis=@_;
my $q;

if(@{$bb}==0){
for($q=0;$q<6;$q++){
$bb->[0+$q]=$axis[$q];
}
return;
}

for($q=0;$q<3;$q++){
if($bb->[0+$q]>$axis[$q]){$bb->[0+$q]=$axis[$q];}
if($bb->[3+$q]<$axis[$q+3]){$bb->[3+$q]=$axis[$q+3];}
}
}





