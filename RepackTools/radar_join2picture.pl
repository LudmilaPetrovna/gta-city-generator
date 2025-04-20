use File::Find;
use Data::Dumper;
use File::Path qw(make_path remove_tree);
use File::Basename;
use Digest::MD5 "md5_hex";
use Digest::CRC qw(crc64 crc32 crc16);

$radar_back="Minimap";
$picture_front="newcol";
$joined_dir="minimap_color";

my $outdir="$joined_dir/final_image/";
my $tempdir="$joined_dir/tmp/";
my $q;
my $src_filename;
my $radar_tile;
my $list="";
my $size;

for($q=0;$q<144;$q++){
$radar_tile=sprintf("radar%.2d.txd",$q);
$framename_tile=sprintf("frames%04d.png",$q);
$txd_filename=$radar_back.'/'.$radar_tile;
$png_filename=$tempdir.'/'.sprintf("png/radar%.2d.png",$q);
if(!-s($txd_filename)){die "Can't read $txd_filename";}
if(!-s($png_filename)){
make_path($tempdir);
print `perl /dev/shm/gta-city-generator/Lesson3/txd_unpacker.pl "$txd_filename" "$tempdir"`;
print `identify "$png_filename"`;
}

make_path($outdir);
`convert $png_filename -alpha off -colorspace gray -normalize -level "0%,90%" -resize 1024x1024 -compose colorize $picture_front/$framename_tile -composite $outdir/$framename_tile`;
print `stat $outdir/$framename_tile`;

}

