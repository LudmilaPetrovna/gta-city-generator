use Geo::Coordinates::GMap;

$zoom=19;
$meters_per_pixel=0.16;
$center_geo=[56.63109683633924,47.88093660864732];
$center_pix=proj0($center_geo);

%mari_levels=();
open(ii,"mari-levels.txt");
while(<ii>){
chomp;
($addr,$levels)=split(/=/,$_,2);
$mari_levels{$addr}=$levels;
}
close(ii);

open(oo,">test.txt");

while(<STDIN>){
@coords=();
$shapes=0;
$levels=0;
$height=0;
$obj_name="UID".(++$uid);
print "Parsing string $obj_name $_\n";

if(/(LINESTRING\(|MULTIPOLYGON\(\(\()([^\)]+)\)/){
$coords=$2;
$shapes=1;
@coords=map{proj([reverse split(/\s+/)])}split(/,\s*/,$coords);
}

%tags=();
while(/([a-z][a-z:]+)=([^,]+)/gs){
($key,$value)=($1,$2);
$value=~s/\%(..)\%/pack("C",hex($1))/egs;
$tags{$key}=$value;
}


if($shapes && /landuse=grass|landuse=flowerbed|leisure=park/){
splice(@coords,0,1);
$uniq_key=join(";",sort map{join(",",map{int($_)}@{$_})}@coords);
if(! exists $uniq_db{$uniq_key}){
$uniq_db{$uniq_key}=$obj_name;
print oo join(" ","Grass1",$obj_name,map{int($_)}map{@{$_}}@coords)."\n";
}
next;
}


if($shapes && /landuse=forest/){
splice(@coords,0,1);
$uniq_key=join(";",sort map{join(",",map{int($_)}@{$_})}@coords);
if(! exists $uniq_db{$uniq_key}){
$uniq_db{$uniq_key}=$obj_name;
print oo join(" ","Forest1",$obj_name,map{int($_)}map{@{$_}}@coords)."\n";
}
next;
}




if($shapes && /amenity=public_building|building=yes/){

$levels=-1;
$height=0;

if(/building:levels=(\d+)/){
$levels=$1;
$height=3.5*$levels;
}
if(/height=(\d+)/){
$height=$1;
}


$mari_key=$tags{'addr:street'}.', house '.$tags{'addr:housenumber'};
$mari_key=~s/(^| )(ул\.?|улица|пр-кт\.?|проспект|проезд|пл\.?|площадь|наб\.?|набережная|пер\.?|переулок|тракт|бульвар)\s+//;
$mari_levels=$mari_levels{$mari_key};

print STDERR "mari $obj_name \"$levels\" != \"$mari_levels\", $mari_key\n";

if($levels<0 && $mari_levels>0){
#addr:city=Йошкар-Ола,addr:housenumber=183,addr:postcode=424006,addr:street=Советская%20%улица,building=yes,building:levels=12
$levels=$mari_levels;

if($levels){
open(hh,">>debug-levels.txt");
print hh $_;
close(hh);
}

}

splice(@coords,0,1);
$uniq_key=join(";",sort map{join(",",map{int($_)}@{$_})}@coords);

if(! exists $uniq_db{$uniq_key}){
$uniq_db{$uniq_key}=$obj_name;
print oo join(" ","Building1",$obj_name,$levels,$height,map{int($_)}map{@{$_}}@coords)."\n";
} else {
print STDERR "Object $obj_name already in a map as $uniq_db{$uniq_key}\n";
}

} # /buildings


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
