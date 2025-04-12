use Math::Trig;
use strict;

sub latlonlev2xy{
my($lat,$lon,$level)=@_;
my $lat_rad=$lat/180*pi;
my $n=2**$level;
my $xtile=$n*(($lon+180)/360);
my $ytile=$n*(1 - (log(tan($lat_rad) + 1/cos($lat_rad)) / pi)) / 2;
return($xtile,$ytile);
}

sub lxy2latlon{
my($level,$xtile,$ytile)=@_;
my $n=2**$level;
my $lon_deg = $xtile / $n * 360.0 - 180.0;
my $lat_rad = atan(sinh(pi * (1 - 2 * $ytile / $n)));
my $lat_deg = $lat_rad * 180.0 / pi;
return($lat_deg,$lon_deg);
}

1