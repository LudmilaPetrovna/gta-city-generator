use Data::Dumper;
use File::Slurp;
use File::Find;
use File::Path qw(make_path remove_tree);
use File::Basename;


$path_data="data";
$path_dst_game="no_world/game";
$path_dst_cols="no_world/col_patched";
$path_unpacked="/dev/shm/t/gta/unpacked/";
$path_cols="col_unpacked/";
@imgs=('anim/anim','anim/cuts','models/cutscene','models/gta3','models/gta_int','models/player');

remove_tree($path_dst_game);
remove_tree($path_dst_cols);
make_path($path_dst_cols);

%ide=();
%used=();
%col2id=();
@binipl=();

# index all files

print "Indexing files...\n";
my %files=();
find({no_chdir=>1,follow=>1,wanted=>sub{
if(-d($File::Find::name)){return;}
my $key=lc(basename($File::Find::name));
$files{$key}=$File::Find::name;
}},$path_unpacked,$path_data);


# step1: collect %ide as id->model/textures/anim file names

print "Parsing IDE files...\n";
@idefiles=grep{/\.ide$/ && !/leveldes\.ide/}values %files;
foreach $idefile(@idefiles){
open(dd,$idefile);
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
if($idefile=~/data\/maps\/(vegas|country|la|sf|interior)\//i){ # some models not used, but defined in maps area
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

##############

# step2: collect text and binary IPL to collect %lod and %used info

print "Parsing IPL files...\n";
@ipl_files=grep{/\.ipl$/}values %files;
foreach $ipl_filename(@ipl_files){
$ipl_data=read_file($ipl_filename);
if(substr($ipl_data,0,4) eq "bnry"){ #this is binary IPL
($items_count,$null,$null,$null,$cars_count,$null)=unpack("IIIIII",substr($ipl_data,4,24));
for($q=0;$q<6;$q++){
($offset,$size)=unpack("II",substr($ipl_data,28+$q*8,8));
if($q==0){$items_offset=$offset;}
if($q==4){$cars_offset=$offset;}
}
if($items_offset!=0x4C){print STDERR "$ipl_filename: Items offset must be 0x4c, your file may be broken\n";}
for($q=0;$q<$items_count;$q++){
($pos_x,$pos_y,$pos_z,$rot_x,$rot_y,$rot_z,$rot_w,$obj_id,$interrior,$lod_index)=unpack("fffffffIIi",substr($file,$items_offset+$q*40,40));
$isint{$obj_id}+=$interrior&0xff;
$used{$obj_id}++;
}
} else { #this is text IPL
$in_inst=0;
foreach(split(/\n/,$ipl_data)){
s/[\r\n]*$//s;

if(/^inst/){$in_inst=1;$inst_id=0;}
if(/^end/){$in_inst=0;}
if(/^\s*\d/ && $in_inst){
($model_id,$model_name,$interrior,$pos_x,$pos_y,$pos_z,$rot_x,$rot_y,$rot_z,$rot_w,$lod_id)=split(/\s*,\s*/);
$isint{$obj_id}+=$interrior&0xff;
$used{$model_id}++;
}
}
}
}

# part 3: patch text IPL files

print "Patching IPL files...\n";
foreach $ipl_filename(grep{index($_,$path_data)==0 && /\.ipl$/}values %files){
open(ii,$ipl_filename) or die;
make_path($path_dst_game.'/'.dirname($ipl_filename));
open(oo,'>'.$path_dst_game.'/'.$ipl_filename) or die "Can't $!";
$in_inst=0;
$inst_id=0;
$in_remove=0;
while(<ii>){
s/[\r\n]*$//s;

if(/^inst/){$in_inst=1;$inst_id=0;}
if(/^(path|grge|enex)/){$in_remove=1;}
if(/^end/){$in_inst=0;$in_remove=0;}
if(/^\s*\d/ && $in_inst){
($model_id,$model_name,$interrior,$pos_x,$pos_y,$pos_z,$rot_x,$rot_y,$rot_z,$rot_w,$lod_id)=split(/\s*,\s*/);
if(exists $used{$model_id}){
$_="";
}
}

if(/\d/ && $in_remove){
$_="";
}

#if(/^\s*\d/ && $in_inst){$_="";}
if($_){
print oo "$_\r\n";
}
}
close(ii);
close(oo);
}

# step 7: patch IDE files

print "Patching IDE files...\n";
foreach $ide_filename(grep{index($_,$path_data)==0 && /\.ide$/ && !/leveldes\.ide/}values %files){
$out_file=$path_dst_game.'/'.$ide_filename;
make_path(dirname($out_file));

open(dd,$ide_filename);
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


# step 8: remove some col-files
# join files

%files=();
%col_packages=();
find({no_chdir=>1,follow=>1,wanted=>sub{
if(-d($File::Find::name)){return;}
my $key=lc(basename($File::Find::name));
$files{$key}=$File::Find::name;
}},$path_cols);

print "Creating COL files...\n";
foreach $col_filename(grep{index($_,$path_cols)==0 && /\.col$/}sort values %files){
#col_unpacked/gta_int/gen_int2_3/coll.col
($col_path,$image_dir,$col_package,$col_name)=split(/\//,$col_filename);

$package=$col_package.'.col'; # for remove files
$col_packages{$package}=1;

$col_id=$col_name;
$col_id=~s/\.col$//si;

$model_id=$col2id{$col_id};
print "($col_path,$image_dir,$col_package,$col_name) model id:$model_id, used:$used{$model_id}\n";

if($used{$model_id}){next;} # we don't need COL, if it was removed
print "...used!\n";

$out_col=$path_dst_cols.'/'.$image_dir.'/'.$col_package.'.col';
$want_col_packages{$package}++;

make_path(dirname($out_col));
open(oo,">>".$out_col) or die "Can't open $out_col for writing $!";
print oo read_file($col_filename);
close(oo);
}


# create list to remove

print "Creating list of removed files...\n";
open(oo,">no_world_remove.txt") or die;
map{print oo "".basename($_)."\t!REMOVE!\n"}grep{!exists $want_col_packages{basename($_)}}keys %col_packages;
map{print oo "".basename($_)."\t!REMOVE!\n"}@ipl_files;

foreach $id(grep{exists $used{$_}}keys %ide){
@files=@{$ide{$id}};
map{print oo "$_\t!REMOVE!\n"}@files;
}
close(oo);



die "done";
