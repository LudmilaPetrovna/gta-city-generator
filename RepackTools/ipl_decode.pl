use File::Find;
use Data::Dumper;
use File::Path qw(make_path remove_tree);
use File::Basename;
use Digest::CRC qw(crc64 crc32 crc16);


%files=();
%ids=();
%inst=();
%ipl=();

# step 1: find files and make shortcuts
# Not perfect was, as we have some collisions, but enough for IPL files

print STDERR "Indexing files...\n";
find({no_chdir=>1,follow=>1,wanted=>sub{
if(-d($File::Find::name)){return;}
my $key=lc(basename($File::Find::name));
if(exists $files{$key}){
#$sum1=substr(`md5sum $File::Find::name`,0,32);
#$sum2=substr(`md5sum $files{$key}`,0,32);
if($sum1 eq $sum2){next;}
#print "WARNING!!! Collision of key $key: $File::Find::name (previous was $files{$key})\n";
}
$files{$key}=$File::Find::name;
}},"data","img_unpacked","col_unpacked");

# step 2: find ids and files
# we can "restore" names in binary IPL files with this info

print STDERR "Searching for id of models...\n";
foreach $file_key(grep{/\.ide$/}keys %files){
open(dd,$files{$file_key}) or die;
$in_objs=0;
while(<dd>){
if(/^(objs|tobj|anim)/){$in_objs=1;}
if(/^end/){$in_objs=0;}
if(/\s*\d/ && $in_objs==1){
@fields=split(/[,\s]+/,$_);
$ids{$fields[0]}=lc($fields[1]);
}
}
close(dd);
}

# step 3: read IPL

%ipl_files=();
print STDERR "Searching for IPL files...\n";
foreach $file_key(grep{/\.ipl$/ && !/_stream\d+\.ipl$/}keys %files){
$ipl_files{$file_key}=$files{$file_key};
$inst{$file_key}=parse_IPL($files{$file_key});
dump_inst($file_key);
$ipl_prefix=$file_key;
$ipl_prefix=~s/\.ipl$//s;

# add streamable files


for($e=0;$e<100;$e++){
$stream_key=$ipl_prefix."_stream".$e.".ipl";
if(!exists $files{$stream_key}){next;}
$inst{$stream_key}=parse_IPL($files{$stream_key});
dump_inst($stream_key);
}
}

# TODO: FIXME: Count line numbers and check correctness of LODs...

# step 4: write txt
# produce files:
# id, file_path.col, pos, quat

#my $center=[2743.4375, -2120.640625, 15.421875];
#my $center=[-2254, -66, 35];
#my $center=[-152,235,9];
#my $center=[-152,235,9];
#my $center=[-164,16,9];
#my $center=[-439.086,1041.41,16.6484];
my $center=[-1204.12,1032.61,53.5703];
my $rad=11700;
my $max_count=5000;

my @ret=();
foreach $ipl_key(grep{!/barrier.+ipl/}keys %inst){
print STDERR "Transforming $ipl_key...\n";
foreach(@{$inst{$ipl_key}}){
($id,$model_name,$interrior,$pos_x,$pos_y,$pos_z,$rot_x,$rot_y,$rot_z,$rot_w,$lod_id)=@{$_};
if($interrior!=0){next;} # today we interested only in "main world"

#print "($id,$pos_x,$pos_y,$pos_z,$rot_x,$rot_y,$rot_z,$rot_w,$lod_id)\n";
$dist=sqrt(($center->[0]-$pos_x)**2+($center->[1]-$pos_y)**2+($center->[2]-$pos_z)**2);
if($dist>$rad){next;}
$col_key=$ids{$id}.".col";
if(exists $files{$col_key}){
push(@ret,[$id,join("\t",$id,$files{$col_key},$pos_x,$pos_y,$pos_z,$rot_x,$rot_y,$rot_z,$rot_w)]);
}
}
}

@ret=sort{rand()>.5?1:-1}@ret;
if(@ret>$max_count){
splice(@ret,$max_count);
}
@ret=sort{$a->[0] <=> $b->[0]}@ret;
open(oo,">map.txt");
print oo map{$_->[1]."\r\n"}@ret;
close(oo);

die "Map completed";

sub parse_IPL{
my $ipl_file=shift;
my $data;

print STDERR "Processing IPL $ipl_file...\n";
open(dd,$ipl_file);
binmode(dd);
read(dd,$data,-s(dd));
close(dd);

my $sign=substr($data,0,4);
if($sign eq "bnry"){return parse_binary_IPL($data);}
if($sign eq "# IP"){return parse_text_IPL($data);}

print "WARNING: Very strange IPL file: $ipl_file!!!\n";
}


sub parse_text_IPL{
my $ret=[];
my $file=shift;
my $in_inst=0;
foreach(split(/[\r\n]+/,$file)){
#print "debug: $_  ($in_inst)\n";
if(/^inst/i){$in_inst=1;next;}
if(/^end/i){$in_inst=0;next;}
if(/^\s*\d/ && $in_inst){
($id,$dummy_name,$interrior,$pos_x,$pos_y,$pos_z,$rot_x,$rot_y,$rot_z,$rot_w,$lod_id)=split(/\s*,\s*/);
$interrior&=0xFF;
push(@{$ret},[$id,$ids{$obj_id},$interrior,$pos_x,$pos_y,$pos_z,$rot_x,$rot_y,$rot_z,$rot_w,$lod_id]);
}
}
return($ret)
}

sub parse_binary_IPL{
my $ret=[];
my $file=shift;
my $q;
my $e;

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
$interrior&=0xFF;
push(@{$ret},[$obj_id,$ids{$obj_id},$interrior,$pos_x,$pos_y,$pos_z,$rot_x,$rot_y,$rot_z,$rot_w,$lod_id]);
}
return($ret);
}

sub dump_inst{
my $key=shift;
mkdir "ipl_decoded",0777;
open(oo,">ipl_decoded/".$key.".inst.txt");
print oo map{join(", ",@{$_})."\n"}@{$inst{$key}};
close(oo);
}
