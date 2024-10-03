

$want_model="SHFYPRO";  #prostiture

%human_classes=();
# pass 1: find right options

open(dd,"Src/data/peds.ide");
while(<dd>){
@want_fields=split(/\s*,\s*/,$_);
if($want_fields[0]!~/^\d+$/){next;}
($id,$model,$texture,$obj_class)=@want_fields;
$model_size=-s("gta3-src/$model.dff");
$replacement=[$model,$model_size,[@want_fields]];
if(!exists $human_classes{$obj_class}){
$human_classes{$obj_class}=$replacement;
}

if($model eq $want_model){# || $human_classes{$obj_class}->[1]>$replacement->[0]){
$human_classes{$obj_class}=$replacement;
}



if(/^\d+\s*,\s*$want_model/){
}
}
close(dd);

`mkdir -p Dst/data/`;

open(dd,"Src/data/peds.ide");
open(oo,">Dst/data/peds.ide");

while(<dd>){
#../Src/data/peds.ide:237, SHFYPRO,  SHFYPRO , PROSTITUTE, STAT_PROSTITUTE, pro, 1000,1, null,1,4,PED_TYPE_G

@fields=split(/\s*,\s*/,$_);

($human_id,$model,$texture,$obj_class)=@fields;
if($human_id>=9 && $human_id<=288){
# && ($obj_class eq "CIVFEMALE" || $obj_class eq "CIVMALE")){
#print;
#$obj_class="PROSTITUTE";
#if(exists $human_classes{$obj_class} && $obj_class=~/^(bike|bmx|boat|car|DODO|EMPEROR|heli|mtruck|plane|quad|trailer|train|WAYFARER)/i){
@want_fields=@{$human_classes{$obj_class}->[2]};
($src_model,$src_texture)=map{lc($_)}($want_fields[1],$want_fields[2]);
$texture=lc($texture);
$model=lc($model);

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

#opendir(dd,"/dev/shm/human/seat");
#@files=grep{!/kart.dff/}grep{/dff/}readdir(dd);
#foreach $filename(@files){
#`cp /dev/shm/human/seat/kart.dff
#}

