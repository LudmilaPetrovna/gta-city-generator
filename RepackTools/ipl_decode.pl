use File::Find;
use Data::Dumper;
use File::Path qw(make_path remove_tree);
use File::Basename;
use File::Slurp;
use Digest::CRC qw(crc64 crc32 crc16);


%files=();
%ids=();
%inst=();
%occl=();
%ipl=();

%txd=();
%lod=();
%lod_txd=();

remove_tree("ipl_decoded");
make_path("ipl_decoded/inst/");
make_path("ipl_decoded/occl/");

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
$txd{lc($fields[1])}=lc($fields[2]);
}
}
close(dd);
}

# step 3: read IPL

%ipl_files=();
print STDERR "Searching for IPL files...\n";
foreach $file_key(sort grep{/\.ipl$/ && !/_stream\d+\.ipl$/}keys %files){
$ipl_files{$file_key}=$files{$file_key};
$inst{$file_key}=parse_IPL($files{$file_key},$file_key);
dump_inst($file_key);
dump_occl($file_key);
$ipl_prefix=$file_key;
$ipl_prefix=~s/\.ipl$//s;

# add streamable files
print "parsed ".($#{$inst{$file_key}})." items\n";

for($e=0;$e<100;$e++){
$stream_key=$ipl_prefix."_stream".$e.".ipl";
if(!exists $files{$stream_key}){next;}
$inst{$stream_key}=parse_IPL($files{$stream_key},$file_key);
dump_inst($stream_key);
}
}


%lod=();
%nonlod=();
foreach $key(keys %inst){
$ip=$inst{$key};
foreach $ii(@{$ip}){
if($ii->[10] && $ii->[10]>=0){
$nonlod{$ii->[0]}=1;
$lod{$ids{$ii->[0]}}=$ip->[$ii->[10]]->[1];
$lod_txd{$txd{$ip->[$ii->[10]]->[1]}}=1;
}
}
}

foreach $id(keys %nonlod){
$lod_txd{$txd{$ids{$id}}}=0;
}


print join("|",sort grep{$lod_txd{$_}} keys %lod_txd);

exit(1);
#used_count
#lod_by_coords


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
my $center=[-3000,-3000,0];
my $rad=500;
my $max_count=500000;


$center_preview=[2416,2351];
$center_preview=[516,1450];
$center_preview=[2747,2111];
$center=[$center_preview->[0]/3072*6000-3000,3000-$center_preview->[1]/3072*6000,0];

$center=[-1894.98,105.789,23.1719];
$center=[1263.88,-770.375,1083]; # in sky

my @ret=();
foreach $ipl_key(grep{!/barrier.+ipl/}keys %inst){
print STDERR "Transforming $ipl_key...\n";
foreach(@{$inst{$ipl_key}}){
($id,$model_name,$interrior,$pos_x,$pos_y,$pos_z,$rot_x,$rot_y,$rot_z,$rot_w,$lod_id)=@{$_};

$interrior&=0xFF;

#if($interrior!=0 && $interrior!=13){next;} # today we interested only in "main world"
#if($interrior==0){next;} # today we interested only in "internal worlds"

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
open(dd,$ipl_file) or die $!;
binmode(dd);
read(dd,$data,-s(dd));
close(dd);

my $tag=lc(basename($ipl_file));
my $sign=substr($data,0,4);
if($sign eq "bnry"){return parse_binary_IPL($data,$tag);}
if($sign eq "# IP" || $sign eq "occl"){return parse_text_IPL($data,$tag);}

print "WARNING: Very strange IPL file: $ipl_file!!!\n";
}


sub parse_text_IPL{
my $ret=[];
my $file=shift;
my $tag=shift;
my $in_inst=0;
my $in_occl=0;
if(!exists $occl{$tag}){
$occl{$tag}=[];
}

foreach(split(/[\r\n]+/,$file)){
#print "debug: $_  ($in_inst)\n";
if(/^inst/i){$in_inst=1;next;}
if(/^occl/i){$in_occl=1;

print "in occl\n";
next;}
if(/^end/i){$in_inst=0;$in_occl=0;next;}
if(/^\s*\d/ && $in_inst){
($id,$dummy_name,$interrior,$pos_x,$pos_y,$pos_z,$rot_x,$rot_y,$rot_z,$rot_w,$lod_id)=split(/\s*,\s*/);

$real_model_name=exists $ids{$id}?$ids{$id}:"UNKNOWN_ID";

push(@{$ret},[$id,$real_model_name,$interrior,$pos_x,$pos_y,$pos_z,$rot_x,$rot_y,$rot_z,$rot_w,$lod_id]);

}

if(/^\s*\-?\d/ && $in_occl){
push(@{$occl{$tag}},[split(/[\s*,]+/)]);
}


}

return($ret)
}

sub parse_binary_IPL{
my $ret=[];
my $file=shift;
my $q;
my $e;
my $lod_min=0xFFFFFF;
my $lod_max=0;

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

if($lod_index>=0){
if($lod_min>$lod_index){$lod_min=$lod_index;}
if($lod_max<$lod_index){$lod_max=$lod_index;}
}

$model_name=exists $ids{$obj_id}?$ids{$obj_id}:"UNKNOWN_ID";
push(@{$ret},[$obj_id,$model_name,$interrior,$pos_x,$pos_y,$pos_z,$rot_x,$rot_y,$rot_z,$rot_w,$lod_id]);
}
print "Lod ids: $lod_min .. $lod_max\n";
return($ret);
}

sub dump_inst{
my $key=shift;
my $out=$key;
$out=~s/\.ipl$//s;
open(oo,">ipl_decoded/inst/".$out.".txt");
print oo map{join(", ",@{$_})."\n"}@{$inst{$key}};
close(oo);
}

sub dump_occl{
my $key=shift;
my $out=$key;
$out=~s/\.ipl$//s;
my $count=@{$occl{$key}};
if($count){
open(oo,">ipl_decoded/occl/".$out.".txt");
print oo map{join(", ",@{$_})."\n"}@{$occl{$key}};
close(oo);
}
}

