use File::Find;
use Data::Dumper;
use File::Path qw(make_path remove_tree);
use File::Basename;
use Digest::CRC qw(crc64 crc32 crc16);

$type=pack("I",0x0253F2F8);
$subtype=7;

find({no_chdir=>1,follow=>1,wanted=>sub{
if(-d($File::Find::name)){return;}

open(dd,$File::Find::name);
read(dd,$file,-s(dd));
close(dd);
$t1=index($file,$type);
if($t1>=0){
$t2=unpack("I",substr($file,$t1+28,4));
if($t2==$subtype){
($size_x,$size_y,$rot_x,$rot_y,$rot_z,$flags,$text)=unpack("fffffSA64",substr($file,$t1+58-22));

print "text found in $File::Find::name:\t".$text." (size: $size_x x $size_y, $rot_x,$rot_y,$rot_z,$flags)\n";
}
}

}},".");

