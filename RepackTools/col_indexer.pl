use File::Find;
use Data::Dumper;
use File::Path qw(make_path remove_tree);
use File::Basename;
use Digest::CRC qw(crc64 crc32 crc16);

find({no_chdir=>1,follow=>1,wanted=>sub{
if(-d($File::Find::name)){return;}
if($File::Find::name=~/\.col$/i){
print_col_info($File::Find::name);
}
}},".");

sub print_col_info{
my $colfile=shift;
open(dd,$colfile) or die;
binmode(dd);
read(dd,$file,-s(dd));
close(dd);

($sign,$filesize,$model_name,$model_id)=unpack("A4IZ22S",substr($file,0,32));
($min_x,$min_y,$min_z,$max_x,$max_y,$max_z,$center_x,$center_y,$center_z,$radius)=unpack("ffffffffff",substr($file,32,40));

$size_x=$max_x-$min_x;
$size_y=$max_y-$min_y;
$size_z=$max_z-$min_z;

$squareness=$size_x/$size_y;
$vol=$size_x*$size_y;

if($size_z<2 && $size_x>10 && $size_x<50 && $size_y>10 && $size_y<50){
print join("\t",length($file),$sign,$model_name,$model_id,$squareness,$vol,$size_x,$size_y,$size_z)."\n";
}

}