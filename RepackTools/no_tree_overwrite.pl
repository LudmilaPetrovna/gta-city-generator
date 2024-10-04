use File::Path qw(make_path remove_tree);

@trees=split(/\n/,<<CODE);
veg_tree
gta_tree_boak
veg_palm
gta_tree_palm
pinetree
gta_tree_oldpine
gta_cactus
bushytree
vgs_palm
gta_tree_bevhills
gtatreesh
Cedar
tree2
tree1
tree3
Cedar3
Cedar2
Cedar1
tree1prc
tree2prc
tree3prc
tree
palm
cedar
oak
CODE

$tree_re="cedar|cedar1|cedar2|cedar3|bushytree|cedar|gta_cactus|gta_tree_bevhills|gta_tree_boak|gta_tree_oldpine|gta_tree_palm|gtatreesh|oak|palm|pinetree|tree|tree1|tree1prc|tree2|tree2prc|tree3|tree3prc|veg_palm|veg_tree|vgs_palm";

$files=`find Src -iname "*.ide"`;

%need_patch=();

foreach $filename(split(/\n/,$files)){
$newfile=$filename;
$newfile=~s/^Src/Dst/s;
$newdir=$newfile;
$newdir=~s/\/[^\/]+$//s;


`mkdir -p $newdir`;

$replacement1=[1395, "TwrCrane_L_03", "Cranes_DYN2"];
$replacement2=[7291, "vegasplant10", "vgnpwroutbld2"];

open(ii,$filename);
while(<ii>){
s/[\r\n]+//gs;

if(/^\d+,.+?,/){
@fields=split(/\s*,\s*/);

if($filename eq "Src/data/maps/generic/vegepart.ide" && $fields[3]>=5){
overwrite($replacement2,$fields[1],$fields[2]);
}

if($filename eq "Src/data/maps/generic/procobj.ide" && $fields[3]>=5){
overwrite($replacement2,$fields[1],$fields[2]);
}

if($fields[1]=~/$tree_re/ || $fields[2]=~/$tree_re/){
overwrite($replacement1,$fields[1],$fields[2]);
}
}
}
close(ii);

}

sub overwrite{
my $repl=shift;
my $model_id=shift;
my $texture_id=shift;

$source_dir="./img_unpacked/models/gta3/";
$dest_dir="./gta3-dst";

make_path($dest_dir);

$modelfile=lc($model_id).".dff";
$texturefile=lc($texture_id).".txd";

$source_modelfile=lc($repl->[1]).".dff";
$source_texturefile=lc($repl->[2]).".txd";

`cp $source_dir/$source_modelfile $dest_dir/$modelfile`;
`cp $source_dir/$source_texturefile $dest_dir/$texturefile`;

}


