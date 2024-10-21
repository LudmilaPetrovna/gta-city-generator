use File::Find;
use File::Path qw(make_path remove_tree);
use File::Basename;
use Digest::CRC qw(crc64 crc32 crc16);
use Data::Dumper;


@srcs=("data/maps/LA","data/maps/SF","data/maps/country","data/maps/vegas");

remove_tree("Dst/data/maps");
make_path("Dst/data/maps");


$src_dir="data";
$src_img_dir="img_unpacked";
$dst_dir="Dst";

foreach $src_dir(@srcs){
find({no_chdir=>1,follow=>1,wanted=>sub{
if(-d($File::Find::name)){return;}
if($File::Find::name=~/\.ide$/i){
$out_file=$dst_dir.'/'.$File::Find::name;
print STDERR "Processing $File::Find::name -> $out_file...\n";
open(dd,$File::Find::name);
open(oo,">tmp.ide");
$in_objs=0;
$is_patched=0;
while(<dd>){
s/[\r\n]//gs;
if(/^objs/){$in_objs=1;}
if(/^end/){$in_objs=0;}
if(/\s*\d/ && $in_objs==1){
@fields=split(/[,\s]+/,$_);
if(($fields[4]&1)==0){ # is not IS_ROAD
#if(($fields[4]&1)==0 && $fields[0]>=5000 && $fields[0]<=17000){ # is not IS_ROAD
#$fields[4]|=0x2000; # IS_TREE
$fields[4]|=0x4000; # IS_PALM
$_=join(", ",@fields);
$is_patched=1;
}
}
print oo "$_\r\n";
}
close(dd);
close(oo);
if($is_patched){
make_path(dirname($out_file));
rename("tmp.ide",$out_file) or die "Can't move file: $!";
} else {
unlink("tmp.ide");
}
}
}},$src_dir);

}
