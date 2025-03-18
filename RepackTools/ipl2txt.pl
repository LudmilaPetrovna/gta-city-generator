use File::Find;
use Data::Dumper;
use File::Path qw(make_path remove_tree);
use File::Basename;
use Digest::CRC qw(crc64 crc32 crc16);


%files=();
%ids=();
%id_files=();
%inst=();
%ipl=();

# step 1: find files and make shortcuts
# in this version we will work with *.col files only

print STDERR "Indexing files...\n";
find({no_chdir=>1,follow=>1,wanted=>sub{
if(-d($File::Find::name)){return;}
my $key=lc(basename($File::Find::name));
$key=~s/\.(col|ipl)$//s;
$files{$key}=$File::Find::name;
}},".");


# step 2: find ids and files

print STDERR "Searching for id of models...\n";
find({no_chdir=>1,follow=>1,wanted=>sub{
if(-d($File::Find::name)){return;}
if($File::Find::name=~/\.ide$/i){
open(dd,$File::Find::name);
$in_objs=0;
while(<dd>){
if(/^objs/){$in_objs=1;}
if(/^end/){$in_objs=0;}
if(/\s*\d/ && $in_objs==1){
@fields=split(/[,\s]+/,$_);
$ids{$fields[0]}=lc($fields[1]);
}
}
close(dd);
}
}},".");

# step 2.1: speedup id-to-file lookup
foreach(keys %ids){
if(exists $files{$ids{$_}}){
$id_files{$_}=$files{$ids{$_}}
}
}

# step 3: read IPL

print STDERR "Searching for IPL files...\n";
find({no_chdir=>1,follow=>1,wanted=>sub{
if(-d($File::Find::name)){return;}
if($File::Find::name=~/\.ipl$/i){
parseIPL($File::Find::name);
}
}},".");


# step 4: write txt
# produce files:
# id, file_path.col, pos, quat

#my $center=[2743.4375, -2120.640625, 15.421875];
my $center=[-2254, -66, 35];
my $rad=500;

my @ret=();
foreach $ipl_prefix(keys %ipl){
print STDERR "Transforming $ipl_prefix...\n";
foreach(@{$ipl{$ipl_prefix}}){
($id,$pos_x,$pos_y,$pos_z,$rot_x,$rot_y,$rot_z,$rot_w,$lod_id)=@{$_};
#print "($id,$pos_x,$pos_y,$pos_z,$rot_x,$rot_y,$rot_z,$rot_w,$lod_id)\n";
$dist=sqrt(($center->[0]-$pos_x)**2+($center->[1]-$pos_y)**2+($center->[2]-$pos_z)**2);
if($dist>$rad){next;}
if(exists $id_files{$id}){
push(@ret,[$id,join("\t",$id,$id_files{$id},$pos_x,$pos_y,$pos_z,$rot_x,$rot_y,$rot_z,$rot_w)]);
}
}
}

@ret=sort{$a->[0] <=> $b->[0]}@ret;
open(oo,">map.txt");
print oo map{$_->[1]."\r\n"}@ret;
close(oo);


sub parseIPL{
my $ret=[];
my $ipl_file=shift;
my $ipl_prefix=lc(basename($ipl_file));
$ipl_prefix=~s/\.ipl$//s;

if($ipl_file=~/_stream\d+.ipl$/i){return;} # stream files will be processed later...

print STDERR "Processing $ipl_file...\n";

# step 1: parse main file and it's INST section

# TODO: FIXME: Main file can be binary too...
# TODO: FIXME: Count line numbers and check correctness of LODs...

my $in_inst=0;
open(dd,$ipl_file);
while(<dd>){
if(/^inst/i){$in_inst=1;}
if(/^end/i){$in_inst=0;}
if(/^\s*\d/ && $in_inst){
s/[\r\n]+//sg;
($id,$dummy_name,$interrior,$pos_x,$pos_y,$pos_z,$rot_x,$rot_y,$rot_z,$rot_w,$lod_id)=split(/\s*,\s*/);
if($interrior!=0){next;} # today we interested only in "main world"
push(@{$ret},[$id,$pos_x,$pos_y,$pos_z,$rot_x,$rot_y,$rot_z,$rot_w,$lod_id]);
}
}
close(dd);

# step 2: parse stream files
my $q;
my $e;
for($e=0;$e<100;$e++){
$ipl_file=$ipl_prefix."_stream".$e;
if(!exists $files{$ipl_file}){next;}
print STDERR "Found $ipl_file as $files{$ipl_file}...\n";
open(dd,$files{$ipl_file}) or die;
read(dd,$file,-s(dd));
close(dd);

if(substr($file,0,4) ne "bnry"){die "Streamable IPL files must be with \"bnry\" signature!";}

($items_count,$null,$null,$null,$cars_count,$null)=unpack("IIIIII",substr($file,4,24));

for($q=0;$q<6;$q++){
($offset,$size)=unpack("II",substr($file,28+$q*8,8));
if($q==0){$items_offset=$offset;}
if($q==4){$cars_offset=$offset;}
}

if($items_offset!=0x4C){die "Items offset must be 0x4c, your file may be broken";}
for($q=0;$q<$items_count;$q++){
($pos_x,$pos_y,$pos_z,$rot_x,$rot_y,$rot_z,$rot_w,$obj_id,$interrior,$lod_index)=unpack("fffffffIIi",substr($file,$items_offset+$q*40,40));
if($interrior!=0){next;} # today we interested only in "main world"
push(@{$ret},[$obj_id,$pos_x,$pos_y,$pos_z,$rot_x,$rot_y,$rot_z,$rot_w,$lod_id]);
}

}
$ipl{$ipl_prefix}=$ret;
}

