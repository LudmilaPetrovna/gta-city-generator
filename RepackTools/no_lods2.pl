use Data::Dumper;
use File::Find;
use File::Path qw(make_path remove_tree);
use File::Basename;

remove_tree("gta3-dst");
make_path("gta3-dst");



%ide=();
%lod=();
%lodof=();
%used=();
%storage=();
%replfiles=();
%errors=();

# step1: collect %ide as id->model/textures

find({no_chdir=>1,follow=>1,wanted=>sub{
if(-d($File::Find::name)){return;}
if($File::Find::name=~/\.ide$/i){
open(dd,$File::Find::name);
$in_objs=0;
while(<dd>){
if(/^objs/){$in_objs=1;}
if(/^end/){$in_objs=0;}
if(/\s*\d/ && $in_objs==1){
($model_id,$model_name,$texture_name)=split(/[,\s]+/,$_);
$ide{$model_id}=[$model_name,$texture_name];

}
}
close(dd);
}
}},"data");

##############

# step2: collect text and binary IPL to collect %lod and %used info
# step2.1: text IPL

find({no_chdir=>1,follow=>1,wanted=>sub{
if(-d($File::Find::name)){return;}
if($File::Find::name=~/\.ipl$/i){

open(ii,$File::Find::name);
$in_inst=0;
$inst_id=0;
$storage_name=lc(basename($File::Find::name));
$storage_name=~s/\.ipl$//i;

if(!exists $storage{$storage_name}){
$storage{$storage_name}=[];
}

while(<ii>){
chomp;
s/[\r\n]*$//s;

if(/^inst/){$in_inst=1;$inst_id=0;}
if(/^end/){$in_inst=0;}
if(/^\s*\d/ && $in_inst){
($model_id,$model_name,$interrior,$pos_x,$pos_y,$pos_z,$rot_x,$rot_y,$rot_z,$rot_w,$lod_id)=split(/\s*,\s*/);
push(@{$storage{$storage_name}},[$model_id,$lod_id]);
$used{$model_id}++;
$inst_id++; # not need?
}
}
close(ii);
}
}},"data");


# step2.2: binary IPL

find({no_chdir=>1,follow=>1,wanted=>sub{
if(-d($File::Find::name)){return;}
if($File::Find::name=~/_stream0\.ipl$/i){

$prefix=$File::Find::name;
$prefix=~s/0\.ipl$//s;

$storage_name=lc(basename($File::Find::name));
$storage_name=~s/_stream\d+\.ipl$//i;

if(!exists $storage{$storage_name}){
$storage{$storage_name}=[];
die "$storage_name: Only in binary IPL!!!";
}

for($pp=0;$pp<20;$pp++){
$file_in=$prefix.$pp.".ipl";

open(dd,$file_in) or next;
read(dd,$file,-s(dd));
close(dd);

# read IPL
if(substr($file,0,4) eq "bnry"){ #this is binary IPL
($items_count,$null,$null,$null,$cars_count,$null)=unpack("IIIIII",substr($file,4,24));
for($q=0;$q<6;$q++){
($offset,$size)=unpack("II",substr($file,28+$q*8,8));
if($q==0){$items_offset=$offset;}
if($q==4){$cars_offset=$offset;}
}
}
if($items_offset!=0x4C){die "Items offset must be 0x4c, your file may be broken";}

for($q=0;$q<$items_count;$q++){
($pos_x,$pos_y,$pos_z,$rot_x,$rot_y,$rot_z,$rot_w,$obj_id,$interrior,$lod_index)=unpack("fffffffIIi",substr($file,$items_offset+$q*40,40));
$used{$obj_id}++;
push(@{$storage{$storage_name}},[$obj_id,$lod_index]);
}

}

}
}},"img_unpacked");

#print Dumper(\%storage);

# step3: calc reverse list

foreach $location(keys %storage){
foreach $el(@{$storage{$location}}){
($model_id,$lod_rec_id)=@{$el};
if($lod_rec_id==-1){next;}
if(!exists $ide{$model_id}){next;} # for ANIM section

$lod_id=$storage{$location}->[$lod_rec_id]->[0];
if(exists $lod{$model_id} && $lod{$model_id}!=$lod_id){
print "".$model_id.":".$ide{$model_id}->[0]."(".$used{$model_id}.") already used lod ".$ide{$lod{$model_id}}->[0].", but now have ".$ide{$lod_id}->[0]."\n";
}
$lod{$model_id}=$lod_id;
$lodof{$lod_id}=$model_id;
#print "".$ide{$model_id}->[0]." uses lod ($lod_id) ".$ide{$lod_id}->[0]."\n";

}
}


# step4: calc list files to replace
# step5: copy or join files



die;

