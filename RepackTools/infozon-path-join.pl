use GD;
require "./gxt_read.pl";

$gta3_root="/dev/shm/cache/img_unpacked/models/gta3";
$infozon="/dev/shm/gta-micro/Clean/data/info.zon";

open(pp,"zones_path.txt") or die;
@paths=<pp>;

open(dd,$infozon) or die;
while(<dd>){
if(/^(zone|end)/){next;}
#SFGLF2, 0, -2667.81, -302.135, -28.8305, -2646.4, -262.32, 71.1695, 1, CUNTC^M
tr/\r//d;
chomp;
($zone_id,$type,$x1,$y1,$z1,$x2,$y2,$z2,$level,$label)=split(/\s*,\s*/);
$label=resolve_GXT($label);
$width=$x2-$x1;
$height=$y2-$y1;
$path="!!!$label";
foreach(@paths){
$label1=$label;
$label1=~s/[\'\.]//gs;
$label1=~s/[^a-zA-Z0-9\/]+/_/gs;

if(index($_,$label1)>=0){$path=$_;}
}

print "$x1,$y1,$x2,$y2,$path";

}

