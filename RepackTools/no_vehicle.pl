#`rm -r gta3-dst`;
#`mkdir gta3-dst`;



$want_model="vcnmav"; #heli
$want_model="rhino";  #car

%vehicle_classes=();
%vehcs=();
# pass 1: find right options
open(dd,"/dev/shm/cache/Src/data/vehicles.ide");
while(<dd>){
@want_fields=split(/\s*,\s*/,$_);
if($want_fields[0]!~/^\d+$/){next;}
($id,$model,$texture,$obj_class)=@want_fields;
$model_size=-s("img_unpacked/models/gta3/$model.dff");
$replacement=[$model,$model_size,[@want_fields]];
$vehcs{lc($model)}=[$model,$texture,$obj_class];

if(!exists $vehicle_classes{$obj_class}){
$vehicle_classes{$obj_class}=$replacement;
}

if($vehicle_classes{$obj_class}->[1]>$replacement->[1]){
$vehicle_classes{$obj_class}=$replacement;
}

if(/vcnmav/){
$obj_class="train";
$vehicle_classes{$obj_class}=$replacement;
$vehicle_classes{$obj_class}->[1]=0;
}

}
close(dd);

open(dd,"/dev/shm/cache/Src/data/vehicles.ide");
#open(oo,">/dev/shm/cache/Dst/data/vehicles.ide");
while(<dd>){

@fields=split(/\s*,\s*/,$_);

($vehicle_id,$model,$texture,$obj_class)=@fields;
#$obj_class="car";
if(exists $vehicle_classes{$obj_class}){
#if(exists $vehicle_classes{$obj_class} && $obj_class=~/^(bike|bmx|boat|car|DODO|EMPEROR|heli|mtruck|plane|quad|trailer|train|WAYFARER)/i){
@want_fields=@{$vehicle_classes{$obj_class}->[2]};
($src_model,$src_texture)=($want_fields[1],$want_fields[2]);
`cp ./img_unpacked/models/gta3/$src_texture.txd gta3-dst/$texture.txd`;
`cp ./img_unpacked/models/gta3/$src_model.dff gta3-dst/$model.dff`;
print STDERR "Copy   ./img_unpacked/models/gta3/$src_model.dff gta3-dst/$model.dff\n";
print STDERR "Copy  ./img_unpacked/models/gta3/$src_texture.txd gta3-dst/$texture.txd\n";
for($q=3;$q<@want_fields;$q++){
$fields[$q]=$want_fields[$q];
}
$_=join(", ",@fields)."\r\n";
}
print oo $_;
}
close(oo);

#opendir(dd,"/dev/shm/vehicle/seat");
#@files=grep{!/kart.dff/}grep{/dff/}readdir(dd);
#foreach $filename(@files){
#`cp /dev/shm/vehicle/seat/kart.dff
#}






#### grep -rl chassi . | grep dff$ | sed "s,^..,,g;s,.dff,,g" | sort | tr "\n" " "
###@models=qw/csbobcat92 csbravura csburrito92 cscopcarla cscopcarla92 cscopcarsf csfirela csglendale92 csgreenwood cslegend566 csmonster csmothership csmtbike92 cspolic cspolicesa csremington92 cssabre92 cssadler cssavanna cssecurica92 cstaxi92 csvoodoo cswashington cszr350 cszr350b/;


# do it in hard way
%cars=();

$files=`grep -ri door_rr_ok img_unpacked/models/cutscene/`;
$files.=`grep -ri door_rf_ok img_unpacked/models/cutscene/`;
$files.=`grep -ri door_lr_ok img_unpacked/models/cutscene/`;
$files.=`grep -ri door_lf_ok img_unpacked/models/cutscene/`;
$files.=`grep -ri exhaust_ok img_unpacked/models/cutscene/`;

foreach $model(@models){
@want_fields=@{$vehicle_classes{car}->[2]};
($src_model,$src_texture)=($want_fields[1],$want_fields[2]);
#`cp ./img_unpacked/models/gta3/$src_texture.txd cutscene-dst/$model.txd`;
#`cp ./img_unpacked/models/gta3/$src_model.dff cutscene-dst/$model.dff`;
#print STDERR "Copy   ./img_unpacked/models/gta3/$src_model.dff cutscene-dst/$model.dff\n";
#print STDERR "Copy  ./img_unpacked/models/gta3/$src_texture.txd cutscene-dst/$model.txd\n";
}

open(dd,"Src/data/txdcut.ide");
while(<dd>){

if(/,/){
($after,$before)=split(/[\s*,]+/);
($model,$texture,$obj_class)=@{$vehcs{$before}};
print "Found replacement $before -> $after (class: $obj_class)\n";
@want_fields=@{$vehicle_classes{$obj_class}->[2]};
($src_model,$src_texture)=($want_fields[1],$want_fields[2]);
#`cp ./img_unpacked/models/gta3/$src_texture.txd cutscene-dst/$after.txd`;
#`cp ./img_unpacked/models/gta3/$src_model.dff cutscene-dst/$after.dff`;
#print STDERR "Copy2   ./img_unpacked/models/gta3/$src_model.dff cutscene-dst/$after.dff\n";
#print STDERR "Copy2  ./img_unpacked/models/gta3/$src_texture.txd cutscene-dst/$after.txd\n";


}

}


