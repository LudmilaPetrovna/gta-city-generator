use GD;
use File::Find;
use Data::Dumper;
use File::Path qw(make_path remove_tree);
use File::Basename;
use Digest::MD5 "md5_hex";
use Digest::CRC qw(crc64 crc32 crc16);

$dummy_file='radar-dummy.png';
$ref_dir='/dev/shm/gta-micro/Clean/models';
$out_dir="radar_dummy/";
make_path($out_dir);
make_path($out_dir.'/models');

`echo -n "0101101001011010" | ffmpeg -f rawvideo -pix_fmt gray -s 4x4 -i - -vf normalize -y $dummy_file`;


create_zoomout_map();
#create_radar_tiles();

sub create_zoomout_map{
my $tempdir="tmp_radar_".rand();
my $temptxd="$tempdir/fronten2-map.txd";

remove_tree($tempdir);
make_path($tempdir);
`cp $dummy_file $tempdir/map.png`;
`perl /dev/shm/gta-city-generator/RepackTools/png2txd.pl $temptxd $tempdir/map.png`;
`perl /dev/shm/gta-city-generator/RepackTools/txd_join.pl "$out_dir/models/fronten2.txd" "$ref_dir/fronten2.txd" "$temptxd"`;

remove_tree($tempdir);
}

sub create_radar_tiles{
my $tempdir="tmp_radar_".rand();

# convert new radar map to TXD files
make_path($out_dir.'/gta3.img');
make_path($tempdir);
for($q=0;$q<144;$q++){
$radname=sprintf("radar%.2d",$q);
`cp $dummy_file $tempdir/$radname.png`;
`perl /dev/shm/gta-city-generator/RepackTools/png2txd.pl $out_dir/gta3.img/$radname.txd $tempdir/$radname.png`;
}

# pack to img
#` perl /dev/shm/gta-city-generator/Lesson3/packer.pl gta3.img img_unpacked/models/gta3/ out_radar/`;
remove_tree($tempdir);

}

