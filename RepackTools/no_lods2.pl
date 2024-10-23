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
%lod=();
%lodof=();
%used=();
%storage=();
%replfiles=();
%errors=();
%fs=();
%isint=();

# step1: collect %ide as id->model/textures

find({no_chdir=>1,follow=>1,wanted=>sub{
if(-d($File::Find::name)){return;}
if($File::Find::name=~/leveldes.ide/i){return;} #not used in game
if($File::Find::name=~/\.ide$/i){
open(dd,$File::Find::name);
$in_objs=0;
while(<dd>){
if(/^objs/){$in_objs=1;}
if(/^end/){$in_objs=0;}
if(/\s*\d/ && $in_objs==1){
($model_id,$model_name,$texture_name)=split(/[,\s]+/,$_);
$ide{$model_id}=[lc($model_name),lc($texture_name)];

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
$isint{$model_id}+=$interrior;
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
$isint{$obj_id}+=$interrior;
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
#print "".$model_id.":".$ide{$model_id}->[0]."(".$used{$model_id}.") already used lod ".$ide{$lod{$model_id}}->[0].", but now have ".$ide{$lod_id}->[0]."\n";
$errors{$model_id}++;
next;
}
$lod{$model_id}=$lod_id;

#if(exists $lodof{$lod_id} && $lodof{$lod_id}!=$model_id){
#print "BACK ".$lod_id.":".$ide{$lod_id}->[0]."(".$used{$lod_id}.") lod of ".$ide{$lodof{$lod_id}}->[0].", but now have ".$ide{$model_id}->[0]."\n";
#$errors{$model_id}++;
#}
$lodof{$lod_id}=$model_id;
#print "".$ide{$model_id}->[0]." uses lod ($lod_id) ".$ide{$lod_id}->[0]."\n";

}
}

# remove models with different lods (errors)
foreach $err(keys %errors){
delete $lod{$err};
}


foreach $id(keys %isint){
if($isint{$id}>0){
delete $lod{$id};
}
}

foreach $id(keys %lodof){
delete $lod{$id};
}


# step4: calc list files to replace
foreach $model_id(keys %lod){


if($used{$model_id}!=1){next;}

$lod_id=$lod{$model_id};
#print "copy ".$ide{$lod_id}->[0]." --> ".$ide{$model_id}->[0]."\n";
$lodfile=lc($ide{$lod_id}->[0]).".dff";
$modfile=lc($ide{$model_id}->[0]).".dff";
if(exists $replfiles{$modfile} && exists $replfiles{$modfile}{$lodfile}){
print "$replfiles{$modfile} want be replaced with $replfiles{$modfile}{$lodfile} and $lodfile\n";
die;
}
$replfiles{$modfile}{$lodfile}++;


$lodfile=lc($ide{$lod_id}->[1]).".txd";
$modfile=lc($ide{$model_id}->[1]).".txd";
if(exists $replfiles{$modfile} && exists $replfiles{$modfile}{$lodfile}){
print "$modfile want be replaced with $replfiles{$modfile}{$lodfile}\n";
}
$replfiles{$modfile}{$lodfile}++;

}


# step5: copy or join files
=pod
foreach $basefile(keys %replfiles){

$basepath=find_file($basefile);

@rep=map{find_file($_)}keys %{$replfiles{$basefile}};
if(@rep==0){next;}
if(@rep==1){
$cmd="cp $rep[0] gta3-dst/$basefile";
} else {
$cmd="perl txd_join.pl gta3-dst/$basefile ".join(" ",@rep);
$cmd="cp $rep[0] gta3-dst/$basefile";
}
print "exec: $cmd\n".`$cmd`."\n";
}
=cut

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
if(exists $lod{$model_id}){
$model_id=$lod{$model_id};
$model_name=$ide{$model_id}->[0];
$_=join(", ",$model_id,$model_name,$interrior,$pos_x,$pos_y,$pos_z,$rot_x,$rot_y,$rot_z,$rot_w,$lod_id);
}
}

#if(/^\s*\d/ && $in_inst){$_="";}

print oo "$_\r\n";
}
close(ii);
close(oo);
}
}},"data");


# part 7: patch binary IPL files

find({no_chdir=>1,follow=>1,wanted=>sub{
if(-d($File::Find::name)){return;}
if($File::Find::name=~/_stream\d+\.ipl$/i){

open(dd,$File::Find::name) or die;
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
if(exists $lod{$obj_id}){
$obj_id=$lod{$obj_id};
substr($file,$items_offset+$q*40,40)=pack("fffffffIIi",$pos_x,$pos_y,$pos_z,$rot_x,$rot_y,$rot_z,$rot_w,$obj_id,$interrior,$lod_index);
}
}
open(oo,">".'gta3-dst/'.basename($File::Find::name));
print oo $file;
close(oo);

}


}},"img_unpacked");

# step 8: patch col-files
%cols=();
find({no_chdir=>1,follow=>1,wanted=>sub{
if(-d($File::Find::name)){return;}
if($File::Find::name=~/.col$/i){
$key=lc(basename($File::Find::name));
$key=~s/\.col$//s;
$cols{$key}=$File::Find::name;
}
}},"col_unpacked");

foreach $model_id(keys %lod){
$lod_id=$lod{$model_id};

$col=$model_id;
while(exists $lodof{$col}){
$col=$lodof{$col};
}

$modelfile=$ide{$col}->[0];
if(!exists $cols{$modelfile}){
die "Can't find collision for $modelfile (model:$model_id) collision:$col int:$isint{$model_id}!";
}

open(dd,$cols{$modelfile}) or die $!;
read(dd,$buf,-s(dd));
close(dd);

substr($buf,8,22)=pack("Z22",$ide{$lod_id}->[0]);
substr($buf,30,2)=pack("S",$lod_id);

$package="default";
if($cols{$modelfile}=~/([^\/]+)\/([^\/]+)$/){
$package=$1;
}

$outfile="col_prepared/".$package."/".$ide{$lod_id}->[0].".col";
make_path(dirname($outfile));
open(oo,">".$outfile);
print oo $buf;
close(oo);

}


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
