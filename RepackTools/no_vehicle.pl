

$want_model="vcnmav"; #heli
$want_model="rhino";  #car

%vehicle_classes=();
# pass 1: find right options
open(dd,"/dev/shm/cache/Src/data/vehicles.ide");
while(<dd>){
@want_fields=split(/\s*,\s*/,$_);
if($want_fields[0]!~/^\d+$/){next;}
($id,$model,$texture,$obj_class)=@want_fields;
$model_size=-s("gta3-src/$model.dff");
$replacement=[$model,$model_size,[@want_fields]];
if(!exists $vehicle_classes{$obj_class}){
$vehicle_classes{$obj_class}=$replacement;
}

if($model eq "romero"){# || $vehicle_classes{$obj_class}->[1]>$replacement->[0]){
$vehicle_classes{$obj_class}=$replacement;
}



if(/^\d+\s*,\s*$want_model/){
}
}
close(dd);

open(dd,"/dev/shm/cache/Src/data/vehicles.ide");
open(oo,">/dev/shm/cache/Dst/data/vehicles.ide");
while(<dd>){

@fields=split(/\s*,\s*/,$_);

($vehicle_id,$model,$texture,$obj_class)=@fields;
$obj_class="car";
if(exists $vehicle_classes{$obj_class} && $obj_class=~/^(car)/i){
#if(exists $vehicle_classes{$obj_class} && $obj_class=~/^(bike|bmx|boat|car|DODO|EMPEROR|heli|mtruck|plane|quad|trailer|train|WAYFARER)/i){
@want_fields=@{$vehicle_classes{$obj_class}->[2]};
($src_model,$src_texture)=($want_fields[1],$want_fields[2]);
print STDERR "Copy  ./gta3-src/$src_texture.txd gta3-dst/$texture.txd\n";
`cp ./gta3-src/$src_texture.txd gta3-dst/$texture.txd`;
print STDERR "Copy   ./gta3-src/$src_model.dff gta3-dst/$model.dff\n";
`cp ./gta3-src/$src_model.dff gta3-dst/$model.dff`;
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

