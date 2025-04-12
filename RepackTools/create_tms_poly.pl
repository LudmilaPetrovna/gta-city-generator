use Math::Trig;
require "/dev/shm/cache/coords.pl";

$EARTH_RADIUS_M=6371008.7714; #Arithmetic mean radius
$EARTH_RADIUS_M=6378137; # Equatorial radius
$meters_per_pixel=0.200249402969238;
$meters_per_tile=256*$meters_per_pixel;

$center_geo=[56.63109683633924,47.88093660864732];
$level=19;
($origin_x,$origin_y)=latlonlev2xy($center_geo->[0],$center_geo->[1],$level);
$invert_y=2**19;

open(oo,">poly.txt");
#[0,0,0];[0,1,0];[3,1,0];[2,0,0];"first";xor-numbered.png

%used=();
for($w=-.008;$w<=.008;$w+=.0001){
for($q=-.008;$q<=.008;$q+=.0001){
($px,$py)=proj_to_game($center_geo->[0]+$w,$center_geo->[1]+$q,$level);
($tile_x,$tile_y)=latlonlev2xy($center_geo->[0]+$w,$center_geo->[1]+$q,$level);
$tile_x=int($tile_x);
$tile_y=int($tile_y);
if($px<-3000 || $px>3000 || $py<-3000 || $py>3000){
next;
}
$tilekey="tile:$tile_x:$tile_y";
if(exists $used{$tilekey}){next;}
$used{$tilekey}++;

$tl=[lxy2latlon($level,$tile_x,$tile_y-1)];
print " $tl->[0]x$tl->[1]\n";
$br=[lxy2latlon($level,$tile_x+1,$tile_y)];
$tl=[proj_to_game($tl->[0],$tl->[1],$level)];
$br=[proj_to_game($br->[0],$br->[1],$level)];

$filename="19/$tile_x/".($invert_y-$tile_y).".jpg";
$filesize=-s("../".$filename);
print "($px,$py) ($tile_x,$tile_y) $tl->[0]x$tl->[1] xx $br->[0]x$br->[1], size: $filesize\n";
print oo "[$tl->[0],$br->[1],0];[$tl->[0],$tl->[1],0];[$br->[0],$tl->[1],0];[$br->[0],$br->[1],0];\"tile_${tile_x}x${tile_y}_\";$filename\n";


}
}







sub proj_to_game{
my($lat,$lon,$level)=@_;
my($tile_x,$tile_y)=latlonlev2xy($lat,$lon,$level);
return(($tile_x-$origin_x)*$meters_per_tile,-($tile_y-$origin_y)*$meters_per_tile);
}

sub distance_deg{
my $p1_deg_lat=shift;
my $p1_deg_lon=shift;
my $p2_deg_lat=shift;
my $p2_deg_lon=shift;
return(distance_greatcircle(deg2rad($p1_deg_lat),deg2rad($p1_deg_lon),deg2rad($p2_deg_lat),deg2rad($p2_deg_lon)));
}


sub distance_greatcircle{
my $p1_rad_lat=shift;
my $p1_rad_lon=shift;
my $p2_rad_lat=shift;
my $p2_rad_lon=shift;
return(acos(sin($p1_rad_lat)*sin($p2_rad_lat)+cos($p1_rad_lat)*cos($p2_rad_lat)*cos($p1_rad_lon-$p2_rad_lon))*$EARTH_RADIUS_M);
}
sub acos { atan2( sqrt(1 - $_[0] * $_[0]), $_[0] ) }
