use Geo::Coordinates::GMap;

$zoom=19;
$meters_per_pixel=0.16;
$center_geo=[56.63109683633924,47.88093660864732];
$center_pix=proj0($center_geo);

open(oo,">test.txt");

while(<STDIN>){
if(/amenity=public_building|building=yes/){

$shapes=0;
$levels=0;
$height=0;
$obj_name="UID".(++$uid);

print "Parsing string $obj_name $_\n";

#47.8892554 56.6390265,47.8886763 56.6391434,47.8885692 56.6389829,47.8885982 56.6389772,47.8885714 56.6389364,47.8885435 56.638894,47.8885138 56.6388999,47.8881038 56.6382854,47.889317 56.6380406,47.8894772 56.6382807,47.8889702 56.6383831,47.8890093 56.6384417,47.8889557 56.6384525,47.8890783 56.6386363,47.8890049 56.6386511,47.8891365 56.6388485,47.8897176 56.6387322,47.889674 56.6386663,47.8900091 56.6385993,47.8901101 56.6387521,47.8902499 56.6389627,47.8895686 56.6390986,47.8893333 56.6391457,47.8892554 56.6390265
if(/(LINESTRING\(|MULTIPOLYGON\(\(\()([^\)]+)\)/){
$coords=$2;
$shapes=1;
}


if(/building:levels=(\d+)/){
$levels=$1;
$height=3.5*$levels;
}
if(/height=(\d+)/){
$height=$1;
}

if($shapes){
@coords=map{proj([reverse split(/\s+/)])}split(/,\s*/,$coords);
splice(@coords,0,1);

$uniq_key=join(";",sort map{join(",",map{int($_)}@{$_})}@coords);

if(! exists $uniq_db{$uniq_key}){
$uniq_db{$uniq_key}=$obj_name;
print oo join(" ","Building1",$obj_name,$levels,$height,map{int($_)}map{@{$_}}@coords)."\n";
} else {
print STDERR "Object $obj_name already in a map as $uniq_db{$uniq_key}\n";
}


}


}
}

sub proj0{
my $src=shift;
my($tile_x,$tile_y)=coord_to_gmap_tile($src->[0],$src->[1],$zoom);
my $res=[int($tile_x*256),int($tile_y*256)];
return($res);
}

sub proj{
my $src=shift;
my($tile_x,$tile_y)=coord_to_gmap_tile($src->[0],$src->[1],$zoom);
my $res=[(($tile_x*256-$center_pix->[0])*$meters_per_pixel),-(($tile_y*256-$center_pix->[1])*$meters_per_pixel)];
return($res);
}
