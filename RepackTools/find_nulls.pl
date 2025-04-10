use Data::Dumper;
use File::Find;
use File::Path qw(make_path remove_tree);
use File::Basename;
use Digest::MD5 "md5_hex";
use Digest::CRC qw(crc64 crc32 crc16);


$src_dir="img_unpacked/";
$null="\x00" x 100;

find({no_chdir=>1,follow=>1,wanted=>sub{
if(-d($File::Find::name)){return;}

open(dd,$File::Find::name);
read(dd,$file,-s(dd));
close(dd);

$ind=index($file,$null,length($file)-100);
if($ind>=0){
print "$File::Find::name: $ind\n";
}


}},$src_dir);

