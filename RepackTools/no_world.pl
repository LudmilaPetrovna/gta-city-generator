use Data::Dumper;
use File::Find;
use File::Path qw(make_path remove_tree);
use File::Basename;

remove_tree("Dst");
remove_tree("gta3-dst");
make_path("gta3-dst");

remove_tree("col_prepared");
make_path("col_prepared");

%ide=();
%used=();
%col2id=();
@binipl=();

# step1: collect %ide as id->model/textures

find({no_chdir=>1,follow=>1,wanted=>sub{
if(-d($File::Find::name)){return;}
if($File::Find::name=~/leveldes.ide/i){return;} #not used in game
if($File::Find::name=~/\.ide$/i){
open(dd,$File::Find::name);
$in_objs=0;
$in_anim=0;
while(<dd>){
if(/^objs|tobj/){$in_objs=1;}
if(/^anim/){$in_anim=1;}
if(/^end/){$in_objs=0;$in_anim=0;}
if(/\s*\d/ && $in_objs==1){
($model_id,$model_name,$texture_name)=split(/[,\s]+/,$_);
$ide{$model_id}=[lc($model_name).".dff",lc($texture_name).".txd"];
$col2id{lc($model_name)}=$model_id;
if($File::Find::name=~/data\/maps\/(vegas|country|la|sf|interior)\//i){ # some models not used, but defined in maps area
$used{$model_id}++;
}

}
if(/\s*\d/ && $in_anim==1){
($model_id,$model_name,$texture_name,$anim_name)=split(/[,\s]+/,$_);
$ide{$model_id}=[lc($model_name).".dff",lc($texture_name).".txd",lc($anim_name).".ifp"];
$col2id{lc($model_name)}=$model_id;
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

while(<ii>){
chomp;
s/[\r\n]*$//s;

if(/^inst/){$in_inst=1;$inst_id=0;}
if(/^end/){$in_inst=0;}
if(/^\s*\d/ && $in_inst){
($model_id,$model_name,$interrior,$pos_x,$pos_y,$pos_z,$rot_x,$rot_y,$rot_z,$rot_w,$lod_id)=split(/\s*,\s*/);
$used{$model_id}++;
}
}
close(ii);
}
}},"data");


# step2.2: binary IPL

find({no_chdir=>1,follow=>1,wanted=>sub{
if(-d($File::Find::name)){return;}
if($File::Find::name=~/\.ipl$/i){
$file_in=$File::Find::name;

push(@binipl,basename($file_in));
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
$isint{$obj_id}+=$interrior;
$used{$obj_id}++;
}

}
}},"img_unpacked");


# part 6: patch text IPL files


find({no_chdir=>1,follow=>1,wanted=>sub{
if(-d($File::Find::name)){return;}
if($File::Find::name=~/\.ipl$/i){

open(ii,$File::Find::name) or die;
make_path('Dst/'.dirname($File::Find::name));
open(oo,'>Dst/'.$File::Find::name) or die;
$in_inst=0;
$inst_id=0;

while(<ii>){
chomp;
s/[\r\n]*$//s;

if(/^inst/){$in_inst=1;$inst_id=0;}
if(/^end/){$in_inst=0;}
if(/^\s*\d/ && $in_inst){
($model_id,$model_name,$interrior,$pos_x,$pos_y,$pos_z,$rot_x,$rot_y,$rot_z,$rot_w,$lod_id)=split(/\s*,\s*/);
if(exists $used{$model_id}){
$_="";
}
}

#if(/^\s*\d/ && $in_inst){$_="";}
if($_){
print oo "$_\r\n";
}
}
close(ii);
close(oo);
}
}},"data");


# step 7: patch IDE files

find({no_chdir=>1,follow=>1,wanted=>sub{
if(-d($File::Find::name)){return;}
if($File::Find::name=~/leveldes.ide/i){return;} #not used in game
if($File::Find::name=~/\.ide$/i){

$out_file="Dst/".$File::Find::name;
make_path(dirname($out_file));

open(dd,$File::Find::name);
open(oo,">".$out_file);
$in_right=0;
while(<dd>){
if(/^objs|tobj|anim|2dfx/){$in_right=1;}
if(/^end/){$in_right=0;}
if(/\s*\d/ && $in_right){
($model_id,$model_name,$texture_name)=split(/[,\s]+/,$_);
if(exists $used{$model_id}){
$_="";
}
}
print oo $_;
}
close(dd);
close(oo);
}

}},"data");


# step 8: remove some col-files
# step 8.1: find all files
%cols=();
find({no_chdir=>1,follow=>1,wanted=>sub{
if(-d($File::Find::name)){return;}
if($File::Find::name=~/.col$/i){
$key=lc(basename($File::Find::name));
$key=~s/\.col$//s;
$cols{$key}=$File::Find::name;
}
}},"col_unpacked");

# join files
%want_col_packages=();
%col_packages=();
foreach $col_id(keys %cols){

$package=$cols{$col_id};
$package=~s/\/[^\/]+$//s;
$package=~s/^col_unpacked/col_prepared/s;
$package.=".col";
$col_packages{$package}++;

$model_id=$col2id{$col_id};
if(exists $used{$model_id}){next;} # we don't need COL, if it was removed

open(dd,$cols{$col_id}) or die $!;
read(dd,$buf,-s(dd));
close(dd);

$want_col_packages{$package}++;

make_path(dirname($package));
open(oo,">>".$package);
print oo $buf;
close(oo);

}


# create list to remove

open(oo,">no_world_remove.txt") or die;

map{print oo "".basename($_)."\t!REMOVE!\n"}grep{!exists $want_col_packages{$_}}keys %col_packages;
map{print oo "$_\t!REMOVE!\n"}@binipl;

foreach $id(grep{exists $used{$_}}keys %ide){
@files=@{$ide{$id}};
map{print oo "$_\t!REMOVE!\n"}@files;
}
close(oo);



die;


# step 9: remove all replaced files

%usedtxd=();
foreach $model_id(keys %ide){
if(!exists $lod{$model_id}){
$usedtxd{$ide{$model_id}->[1]}++;
}
}
open(oo,">nolod-dff-remove.txt");
foreach $model_id(keys %lod){
print oo "".$ide{$model_id}->[0].".dff\t!REMOVE!\n";
if(!exists $usedtxd{$ide{$model_id}->[1]}){
print oo "".$ide{$model_id}->[1].".txd\t!REMOVE!\n";
}
}
close(oo);



die "done";

sub find_file{
my $basename=shift;
my $basepath="img_unpacked/models/gta3/".$basename;
my $basesize=-s($basepath);
if($basesize==0){
$basepath="img_unpacked/models/gta_int/".$basename;
$basesize=-s($basepath);
}
if($basesize==0){die "$basename not found";}
return($basepath);
}
