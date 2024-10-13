use Data::Dumper;

$gta3_root="/dev/shm/cache/img_unpacked/models/gta3";

`rm -r gta3-dst`;
`mkdir gta3-dst`;


%lods=();
%ide=();
%count=();

#collect names
$files=`find Src -iname "*.ide"`;

foreach $filename(split(/\n/,$files)){
open(ii,$filename);
while(<ii>){
if(/^\d+/){
($model_id,$model_name,$texture_name)=split(/\s*,\s*/);
$ide{$model_id}=[$model_name,$texture_name];
}
}
close(ii);
}


# collect base lods
$files=`find Src -iname "*.ipl"`;

foreach $filename(split(/\n/,$files)){
if($filename=~/([^\/]+?)\.ipl/){
$basename=lc($1);
}

open(ii,$filename);
$in_inst=0;
$inst_id=0;
while(<ii>){
chomp;
s/[\r\n]*$//s;

if(/^inst/){
$in_inst=1;
$inst_id=0;
}

if(/^end/){
$in_inst=0;
}

if(/^\d+/){
#3300, lod_conhoos4, 0, -1534.445313, 2689.273438, 56.6484375, 0, 0, -0.7071067691, 0.7071067691, -1^M
($model_id, $model_name, $interrior, $pos_x, $pos_y, $pos_z, $rot_x, $rot_y, $rot_z, $rot_w, $lod_id)=split(/\s*,\s*/);
$lods{$basename}{$inst_id}=$model_id;
$inst_id++;
$count{$model_id}++;
}
}
close(ii);
}


#die Dumper(\%lods);

#ipl
mkdir "binary_ipl";
$files=`find $gta3_root -iname "*.ipl"`;

foreach $filename(split(/\n/,$files)){
print STDERR "Processing binary IPL file: $filename\n";
open(dd,$filename) or die;
read(dd,$file,-s(dd));
close(dd);

#countn2_stream1.ipl
if($filename=~/([^\/]+?)_stream\d+\.ipl/){
$basename=lc($1);
}

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
$obj_name=exists $names{$obj_id}?$names{$obj_id}:"UNKNOWN_OBJ_ID";
$count{$obj_id}++;
if($lod_index>=0){
if(exists $lods{$basename}{$lod_index}){
#print "Found lod in $basename, id $lod_index: ".$lods{$basename}{$lod_index}."\n";
#print "Found lod of $obj_id -> $lod_index ($ide{$obj_id}->[0] -> $ide{$lods{$basename}{$lod_index}}->[0])\n";
$replacements{$obj_id}=$lods{$basename}{$lod_index};

}
}
}


}

%txdcount=();

foreach $to_id(keys %replacements){
$from_id=$replacements{$to_id};
if($to_id eq $from_id){next;}

$from_file=lc($ide{$from_id}->[0]);
$to_file=lc($ide{$to_id}->[0]);

$from2_file=lc($ide{$from_id}->[1]);
$to2_file=lc($ide{$to_id}->[1]);

$txdcount{$to2_file}++;

}

foreach $to_id(keys %replacements){
$from_id=$replacements{$to_id};
if($to_id eq $from_id){next;}

$from_file=lc($ide{$from_id}->[0]);
$to_file=lc($ide{$to_id}->[0]);

$from2_file=lc($ide{$from_id}->[1]);
$to2_file=lc($ide{$to_id}->[1]);

if($count{$from_id}!=1 && $count{$to_id}!=1){next;}
if($txdcount{$to2_file}!=1){next;}

print "Copy $from_file -> $to_file ($count{$from_id} to $count{$to_id})\n";

`cp /dev/shm/cache/img_unpacked/models/gta3/$from_file.dff gta3-dst/$to_file.dff`;
`cp /dev/shm/cache/img_unpacked/models/gta3/$from2_file.txd gta3-dst/$to2_file.txd`;
#`cp /dev/shm/gta-micro/Clean/img_unpacked/models/gta3.img/$from2_file.txd gta3-dst/$to2_file.txd`;

}






