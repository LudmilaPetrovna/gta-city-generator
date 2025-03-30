use File::Find;
use Data::Dumper;
use File::Path qw(make_path remove_tree);
use File::Basename;
use Digest::MD5 "md5_hex";
use Digest::CRC qw(crc64 crc32 crc16);


$filename="/dev/shm/gta-micro/Projects/ColorRadar/samples/REF/radar91.txd";
$filename="/dev/shm/gta-micro/Projects/ColorRadar/samples/Proper_Radar/(PC 512)/Proper Radar/radar00.txd";
$filename="/dev/shm/gta-micro/Projects/ColorRadar/samples/1503318561_happymap/radar00.txd";
unpack_radar_dir(dirname($filename));

sub unpack_radar_dir{
my $basedir=shift;
my $tempdir="tmp_radar_".rand();
my $outdir=sprintf("radar-%08X",crc32($basedir));
my $q;
my $src_filename;
my $radar_tile;
my $list="";
my $size;

remove_tree($tempdir);
make_path($tempdir);

remove_tree($outdir);
make_path($outdir);

for($q=0;$q<144;$q++){
$radar_tile=sprintf("radar%.2d.txd",$q);
$txd_filename=$basedir.'/'.$radar_tile;
$png_filename=$tempdir.'/'.sprintf("png/radar%.2d.png",$q);
$list.=" $png_filename";
print "$txd_filename\n";
if(!-s($txd_filename)){next;}
print `perl /dev/shm/gta-city-generator/Lesson3/txd_unpacker.pl "$txd_filename" "$tempdir"`;
}

$q=`identify "$png_filename"`;
if($q=~/(\d+x\d+\+0\+0)/){
$size=$1;
} else {
die "Can't read unpacked image";
}

print "Creating pano...\n";
`montage -tile 12x -geometry $size $list $outdir/radar-glued.png`;
print `identify $outdir/radar-glued.png`;




# clean up
remove_tree($tempdir);
}
