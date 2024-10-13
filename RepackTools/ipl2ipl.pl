use File::Path qw(make_path remove_tree);
use GD;
use Data::Dumper;

$map=GD::Image->new(6000,6000,1);
$map->saveAlpha(1);
$map->alphaBlending(0);
$map->filledRectangle(0,0,6000,6000,0x7f000000);
$map->alphaBlending(1);

$gta3_root="/dev/shm/cache/img_unpacked/models/gta3";
$dst_dir="ipl_unpacked";

%usage=();
%moved=();

make_path($dst_dir);

open(pp,"/dev/shm/cache/zones_info.txt");
while(<pp>){
chomp;
($x1,$y1,$x2,$y2,$path)=split(/,/);
push(@paths,[$x1,$y1,$x2,$y2,$path]);
}
close(pp);

#collect names
$files=`find Src -iname "*.ide"`;
%ide=();
foreach $filename(split(/\n/,$files)){
open(ii,$filename);
while(<ii>){
if(/^\d+\s*,/){
@fields=split(/\s*,\s*/);
$ide{$fields[0]}=[$fields[1],$fields[2]];
}
}
close(ii);
}


#ipl
$files=`find $gta3_root -iname "*stream*.ipl"`;

foreach $filename(split(/\n/,$files)){
open(dd,$filename) or die;
read(dd,$file,-s(dd));
close(dd);

$newfile=$dst_dir."/"."debug.txt";


$bb=[];

open(oo,">".$newfile) or die;

if(substr($file,0,4) eq "bnry"){ #this is binary IPL
($items_count,$null,$null,$null,$cars_count,$null)=unpack("IIIIII",substr($file,4,24));
for($q=0;$q<6;$q++){
($offset,$size)=unpack("II",substr($file,28+$q*8,8));
if($q==0){$items_offset=$offset;}
if($q==4){$cars_offset=$offset;}
}
}

if($items_offset!=0x4C){die "Items offset must be 0x4c, your file may be broken";}
#print STDERR "We have $items_count items, offset: $items_offset; we have $cars_count, offset: $cars_offset\n";


$color=int(rand()*256) | (int(rand()*256)<<8) | (int(rand()*256)<<16);
$opacity=0x70;
$filled_color=($opacity<<24)|$color;

print oo "inst\n";
# structs by 40 bytes
for($q=0;$q<$items_count;$q++){
($pos_x,$pos_y,$pos_z,$rot_x,$rot_y,$rot_z,$rot_w,$obj_id,$interrior,$lod_index)=unpack("fffffffIIi",substr($file,$items_offset+$q*40,40));
if(!exists $ide{$obj_id}){die "WARNING!!! Unknown ID ($obj_id), not found in IDE file!!!";}
$obj_name=$ide{$obj_id}->[0];

($model,$texture)=@{$ide{$obj_id}};

$usage{lc($model.'.dff')}++;
$usage{lc($texture.'.txd')}++;


$path="UNKNOWN";

foreach $pp(@paths){
if($pos_x>=$pp->[0] && $pos_x<=$pp->[2] && $pos_y>=$pp->[1] && $pos_y<=$pp->[3]){
$path=$pp->[4];
}
}


$moved{lc($model.'.dff')}=$path;
$moved{lc($texture.'.txd')}=$path;

print oo join(", ",$obj_id,$obj_name,$interrior,$pos_x,$pos_y,$pos_z,$rot_x,$rot_y,$rot_z,$rot_w,$lod_index)."\n";
updateBB($bb,$pos_x,$pos_y,$pos_z);
$map->setPixel(3000+$pos_x,3000-$pos_y,$color);

}
print oo "end\n";
print oo "cull\n";
print oo "end\n";
print oo "path\n";
print oo "end\n";
print oo "grge\n";
print oo "end\n";
print oo "enex\n";
print oo "end\n";
print oo "pick\n";
print oo "end\n";
print oo "cars\n";

# structs by 48 bytes
for($q=0;$q<$cars_count;$q++){
($pos_x,$pos_y,$pos_z,$rot_angle,$obj_id,$color_primary,$color_secondary,$force_spawn,$alarm,$locked,
$unk1,$unk2)=unpack("ffffIIIIIIII",substr($file,$cars_offset+$q*48,48));


print oo join(", ",$pos_x,$pos_y,$pos_z,$rot_angle,$obj_id,$color_primary,$color_secondary,$force_spawn,$alarm,$locked,$unk1,$unk2)."\n";
updateBB($bb,$pos_x,$pos_y,$pos_z);
$map->setPixel(3000+$pos_x,3000-$pos_y,$color);

}
print oo "end\n";
print oo "jump\n";
print oo "end\n";
print oo "tcyc\n";
print oo "end\n";
print oo "auzo\n";
print oo "end\n";
print oo "mult\n";
print oo "end\n";
close(oo);
print "Bounding box for $filename: ".join(" ",@{$bb})."\n";

$location_width=$bb->[3]-$bb->[0];
$location_height=$bb->[4]-$bb->[1];
$location_area=$location_width*$location_height;
push(@locations,[$filename,$location_width,$location_height,int($location_area/1000000)]);

$x1=$bb->[0]+3000;
$y2=3000-$bb->[1];
$x2=$bb->[3]+3000;
$y1=3000-$bb->[4];
$map->filledRectangle($x1,$y1,$x2,$y2,$filled_color);
$map->rectangle($x1,$y1,$x2,$y2,$color);
$map->string(gdSmallFont,$x1+2,$y1+2,$filename,0);
}

#open(oo,">binary_ipl_map.png");
#print oo $map->png(9);
#close(oo);

#print "We found locations:\n";
#rint map{"$_->[0]: $_->[1] x $_->[2] (area $_->[3] km2)\n"}sort{$a->[3] <=> $b->[3]}@locations;


foreach(keys %usage){
if($usage{$_}!=1){
$moved{$_}="_COMMON";
}
}


foreach $filename(keys %moved){
$target=$dst_dir."/".$moved{$filename};
make_path($target);

`cp /dev/shm/cache/img_unpacked/models/gta3/$filename $target`;

}



die Dumper(\%moved);


sub updateBB{
my $bb=shift;
my @axis=@_;
my $q;

if(@{$bb}==0){
for($q=0;$q<3;$q++){
$bb->[0+$q]=$axis[$q];
$bb->[3+$q]=$axis[$q];
}
return;
}

for($q=0;$q<3;$q++){
if($bb->[0+$q]>$axis[$q]){$bb->[0+$q]=$axis[$q];}
if($bb->[3+$q]<$axis[$q]){$bb->[3+$q]=$axis[$q];}
}
}





