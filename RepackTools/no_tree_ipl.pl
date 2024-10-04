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

die $tree_re;
$files=`find Src -iname "*.ide"`;

`rm -rf Dst`;

%need_patch=();

foreach $filename(split(/\n/,$files)){
$newfile=$filename;
$newfile=~s/^Src/Dst/s;
$newdir=$newfile;
$newdir=~s/\/[^\/]+$//s;


`mkdir -p $newdir`;

open(ii,$filename);
while(<ii>){
s/[\r\n]+//gs;

if(/^\d+,.+?,/){
@fields=split(/\s*,\s*/);

if($filename eq "Src/data/maps/generic/vegepart.ide" && $fields[3]>=5){
$need_patch{$fields[0]}=7291;
}

if($filename eq "Src/data/maps/generic/procobj.ide" && $fields[3]>=5){
$need_patch{$fields[0]}=7291;
}

if($fields[1]=~/$tree_re/ || $fields[2]=~/$tree_re/){
$need_patch{$fields[0]}=1395;
}
}
}
close(ii);


if(!$is_patched){
unlink($newfile);
} else {
print "Processing $filename --> $newfile\n";

}


}


#ipl

$files=`find Src -iname "*.ipl"`;


foreach $filename(split(/\n/,$files)){
$newfile=$filename;
$newfile=~s/^Src/Dst/s;
$newdir=$newfile;
$newdir=~s/\/[^\/]+$//s;

print "Processing $filename --> $newfile\n";

`mkdir -p $newdir`;

open(ii,$filename) or die;
open(oo,">".$newfile) or die;
$is_patched=0;
while(<ii>){

if(/^inst/){
$in_inst=1;
}

if(/^end/){
$in_inst=0;
}


if($in_inst && /^\d+,/){
@fields=split(/\s*,\s*/);
$fields[1]="non_name5";
if(exists $need_patch{$fields[0]}){
$fields[0]=$need_patch{$fields[0]};
$is_patched=1;
}
$_=join(", ",@fields);
}

print oo $_;
}
close(oo);
close(ii);

if(!$is_patched){
#unlink($newfile);
}

}



#binary IPL

$files=`find gta3-src -iname "*.ipl"`;

foreach $filename(split(/\n/,$files)){
$newfile=$filename;
$newfile=~s/^gta3-src/gta3-dst/s;
$newdir=$newfile;
$newdir=~s/\/[^\/]+$//s;

print "Processing $filename --> $newfile\n";

`mkdir -p $newdir`;

open(ii,$filename) or die;
open(oo,">".$newfile) or die;
read(ii,$file,-s(ii));

if(substr($file,0,4) eq "bnry"){ #this is binary IPL
($items_count,$null,$null,$null,$cars_count,$null)=unpack("IIIIII",substr($file,4,24));
for($q=0;$q<6;$q++){
($offset,$size)=unpack("II",substr($file,28+$q*8,8));
if($q==0){$items_offset=$offset;}
if($q==4){$cars_offset=$offset;}
}
}

if($items_offset!=0x4C){die "Items offset must be 0x4c, your file may be broken";}
print STDERR "We have $items_count items, offset: $items_offset; we have $cars_count, offset: $cars_offset\n";

# structs by 40 bytes
for($q=0;$q<$items_count;$q++){
($pos_x,$pos_y,$pos_z,$rot_x,$rot_y,$rot_z,$rot_w,$obj_id,$interrior,$lod_index)=unpack("fffffffIII",substr($file,$items_offset+$q*40,40));

if(exists $need_patch{$obj_id}){
$obj_id=$need_patch{$obj_id};
}

substr($file,$items_offset+$q*40,40)=
pack("fffffffIII",$pos_x,$pos_y,$pos_z,$rot_x,$rot_y,$rot_z,$rot_w,$obj_id,$interrior,$lod_index);
}

print oo $file;
close(oo);
close(ii);

}