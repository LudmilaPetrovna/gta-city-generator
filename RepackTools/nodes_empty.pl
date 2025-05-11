use GD;
use File::Find;
use Data::Dumper;
use File::Path qw(make_path remove_tree);
use File::Basename;
use Digest::MD5 "md5_hex";
use Digest::CRC qw(crc64 crc32 crc16);

$out_dir="3";
make_path($out_dir);

$filler1="\xFF\xFF\x00\x00" x 192;
$filler2="\x00" x 192;

# will crash at file boundary, possible need some points...

for($file_id=0;$file_id<=63;$file_id++){
$filename=lc("$out_dir/nodes${file_id}.dat");
open(oo,'>'.$filename) or die $!;
print oo pack("IIIII",0,0,0,0,0);
print oo $filler1;
print oo $filler2;
print oo $filler2;
close(oo);
}
