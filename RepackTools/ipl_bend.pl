use File::Find;
use File::Path qw(make_path remove_tree);
use File::Basename;
use Digest::CRC qw(crc64 crc32 crc16);

$src_dir="data";
$src_img_dir="img_unpacked";
$dst_dir="Dst";

remove_tree("Dst/data/maps");
make_path("Dst/data/maps");

find({no_chdir=>1,follow=>1,wanted=>sub{
if(-d($File::Find::name)){return;}
if($File::Find::name=~/\.ipl$/i){
bend_text_ipl($File::Find::name,$dst_dir."/".$File::Find::name);
}
}},$src_dir);

find({no_chdir=>1,follow=>1,wanted=>sub{
if(-d($File::Find::name)){return;}
if($File::Find::name=~/\.ipl$/i){
bend_text_ipl($File::Find::name,$dst_dir."/".$File::Find::name);
}
}},$src_dir);

find({no_chdir=>1,follow=>1,wanted=>sub{
if(-d($File::Find::name)){return;}
if($File::Find::name=~/stream.*\.ipl$/i){
bend_bin_ipl($File::Find::name,"ipl_bended/".$File::Find::name);
}
}},$src_img_dir);


sub bend_bin_ipl{
my $src=shift;
my $dst=shift;

print STDERR "Bending binary IPL $src ---> $dst\n";
make_path(dirname($dst));

open(dd,$src) or die $!;
read(dd,$file,-s(dd));
close(dd);

if(substr($file,0,4) ne "bnry"){die "This is binary IPL?????";}
($items_count,$null,$null,$null,$cars_count,$null)=unpack("IIIIII",substr($file,4,24));
for($q=0;$q<6;$q++){
($offset,$size)=unpack("II",substr($file,28+$q*8,8));
if($q==0){$items_offset=$offset;}
if($q==4){$cars_offset=$offset;}
}

if($items_offset!=0x4C){die "Items offset must be 0x4c, your file may be broken";}

for($q=0;$q<$items_count;$q++){
($pos_x,$pos_y,$pos_z,$rot_x,$rot_y,$rot_z,$rot_w,$obj_id,$interrior,$lod_index)=unpack("fffffffIIi",substr($file,$items_offset+$q*40,40));
$seed=crc32(join(":",map{int($_)}($interrior,$pos_x,$pos_y,$pos_z)));
print "seed: $seed\n";
$angle1=$seed&0xFFFF;
$angle2=($seed>>16)&0xFFFF;
$rot_x=($angle1/65535-.5)*.18;
$rot_y=($angle2/65535-.5)*.18;

substr($file,$items_offset+$q*40,40)=pack("fffffffIIi",$pos_x,$pos_y,$pos_z,$rot_x,$rot_y,$rot_z,$rot_w,$obj_id,$interrior,$lod_index);
}

open(oo,'>'.$dst) or die $!;
print oo $file;
close(oo);

}

sub bend_text_ipl{
my $src=shift;
my $dst=shift;

make_path(dirname($dst));

print STDERR "Bending text IPL $src ---> $dst\n";

open(dd,$src) or die $!;
open(oo,'>'.$dst) or die $!;

my $in_inst=0;
while(<dd>){
if(/^inst/){$in_inst=1;}
if(/^end/){$in_inst=0;}
if(/^\s*\d/){
@fields=split(/\s*,\s*/);
$seed=crc32(join(":",map{int($_)}($fields[2],$fields[3],$fields[4],$fields[5])));
$angle1=$seed&0xFFFF;
$angle2=($seed>>16)&0xFFFF;
$fields[6]=($angle1/65535-.5)*.18;
$fields[7]=($angle2/65535-.5)*.18;
$_=join(", ",@fields);
}

print oo $_;

}

close(dd);
close(oo);

}

