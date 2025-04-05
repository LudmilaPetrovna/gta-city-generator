use GD;
use File::Find;
use Data::Dumper;
use File::Path qw(make_path remove_tree);
use File::Basename;
use Digest::MD5 "md5_hex";
use Digest::CRC qw(crc64 crc32 crc16);

$src_dir="newcol";
$ref_dir="/dev/shm/gta-micro/Projects/ColorRadar/samples/REF/";
$title="RoadMap";
$scale=2;
$radar_centre="radar_centre.png";
$tilesize=128*$scale;
@zoomname=qw/zero normal HIGH high high high high high ULTRA/;


$out_dir="release_$title/${title}_x${scale}_${zoomname[$scale]}_${tilesize}x${tilesize}";
#remove_tree($out_dir);
make_path($out_dir);

create_radar_icon();
create_zoomout_map();
create_radar_tiles();

sub create_radar_icon{
my $tempdir="tmp_radar_".rand();
print "Creating new radar icon in $tempdir with scale: $scale...\n";
remove_tree($tempdir);
make_path($tempdir);
my $size=8*$scale;
my $temptxd="$tempdir/hud-radar-center.txd";

print "  ...resizing icon to ${size}x${size}...\n";
`convert $radar_centre -resize ${size}x${size}\! $tempdir/radar_centre.png`;
print "  ...converting icon to TXD...\n";
`perl /dev/shm/gta-city-generator/RepackTools/png2txd.pl "$temptxd" "$tempdir/radar_centre.png"`;
print "  ...merging icon with main hud.txd...\n";
make_path("$out_dir/models/");
`perl /dev/shm/gta-city-generator/RepackTools/txd_join.pl "$out_dir/models/hud.txd" "$ref_dir/hud.txd" "$temptxd"`;
remove_tree($tempdir);
}

sub create_zoomout_map{
my $tempdir="tmp_radar_".rand();
my $temptxd="$tempdir/fronten2-map.txd";

print "Creating zoomout radar map in $tempdir with scale: $scale...\n";
remove_tree($tempdir);
make_path($tempdir);
my $panosize=512*$scale;

my $pano=undef;
my $pano2=undef;
my $tile_size=0;
print "  ...creating really big pano...\n";
for($q=0;$q<144;$q++){
$ox=$q%12;
$oy=int($q/12);
$filename=$src_dir.'/'.sprintf("frames%.4d.png",$q);
$filesize=-s($filename);
print "    ...processing tile at ${ox}x${oy}, $filename ($filesize bytes)...\n";
$tile=GD::Image->new($filename);
if(!$tile){
print "Can't load $filename\n";
die
}

($tile_size,$tile_h)=$tile->getBounds();

$offset_x=$ox*$tile_size;
$offset_y=$oy*$tile_size;

if(!$pano){
$pano=GD::Image->new($tile_size*12,$tile_size*12,1);
}

$pano->copy($tile,$offset_x,$offset_y,0,0,$tile_size,$tile_size);
}

print "  ...resizing to ${panosize}x$panosize...\n";
$pano2=GD::Image->new($panosize,$panosize,1);
$pano2->copyResampled($pano,0,0,0,0,$panosize,$panosize,$tile_size*12,$tile_size*12);

print "  ...saving pano...\n";
open(dd,">$tempdir/map.png");
binmode(dd);
print dd $pano2->png(0);
close(dd);

$panosize=2048;
print "  ...resizing to ${panosize}x$panosize for preview...\n";
$pano2=GD::Image->new($panosize,$panosize,1);
$pano2->copyResampled($pano,0,0,0,0,$panosize,$panosize,$tile_size*12,$tile_size*12);

print "  ...saving map preview...\n";
open(dd,">$out_dir/Preview.jpg");
binmode(dd);
print dd $pano2->jpeg(70);
close(dd);


$pano=undef;
$pano2=undef;

print "  ...converting to TXD...\n";
`perl /dev/shm/gta-city-generator/RepackTools/png2txd.pl "$temptxd" "$tempdir/map.png"`;
print "  ...join with fronten2.txd...\n";
`perl /dev/shm/gta-city-generator/RepackTools/txd_join.pl "$out_dir/models/fronten2.txd" "$ref_dir/fronten2.txd" "$temptxd"`;

remove_tree($tempdir);
}

sub create_radar_tiles{
my $tempdir="tmp_radar_".rand();
remove_tree($tempdir);
make_path($tempdir);
my $tilesize=128*$scale;
my $q;

make_path("$out_dir/gta3.img");
# convert new radar map to TXD files
for($q=0;$q<144;$q++){
$src_filename=$src_dir.'/'.sprintf("frames%.4d.png",$q);
$radname=sprintf("radar%.2d",$q);

`convert $src_filename -interpolate Integer -filter point -alpha off -resize 256x256 $tempdir/$radname.png`;
`perl /dev/shm/gta-city-generator/RepackTools/png2txd.pl $out_dir/gta3.img/$radname.txd $tempdir/$radname.png`;
}

# pack to img
#` perl /dev/shm/gta-city-generator/Lesson3/packer.pl gta3.img img_unpacked/models/gta3/ out_radar/`;
remove_tree($tempdir);

}



die;



# for compare and checking quality
$compare_size_block="256x256";
$list="";
`rm -rf tmp`;
`mkdir tmp`;
for($q=0;$q<144;$q++){
$src_filename=sprintf("newcol/frames%.4d.png",$q);
$tmp_filename=sprintf("tmp/frames%.4d.png",$q);
$list.=" $tmp_filename";
`convert $src_filename -interpolate Integer -filter point -resize $compare_size_block $tmp_filename`;
}
`montage -tile 12x -geometry ${compare_size_block}+0+0 $list radar-compare-new.png`;

# result 3072x3072
`convert radar-gtasa-ref.png -interpolate Integer -filter point -resize 3072x3072 radar-compare-ref.png`;
`convert radar-compare-ref.png radar-compare-new.png radar-anim0.gif`;
`gifsicle -O99 -f --lossy=90 --delay 50 -o radar-anim.gif radar-anim0.gif`;

die;



#`convert picture.jpg -resize 768x768^ -gravity center -extent 768x768+0+0 picture-resized.png`;
#`convert picture-resized.png -crop 64x64 tmp/frames.png`;


`convert radar-compare-sat.png radar-compare-new.png radar-anim0.gif`;
`gifsicle -O99 -f --lossy=90 --delay 50 -o radar-anim.gif radar-anim0.gif`;
die;


