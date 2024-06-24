use Data::Dumper;

@ipls=`find -iname "*.ipl"`;

foreach $filename(@ipls){
chomp($filename);

open(dd,$filename);
read(dd,$file,-s(dd));
close(dd);

@lines=split(/[\r\n]+/,$file);

$bbox=[0xFFFF,0xFFFF,-0xFFFF,-0xFFFF];

foreach(@lines){
if(/^inst$/){
$in_inst=1;
next;
}

if(/^end$/){
$in_inst=0;
next;
}
if(/^\d+,/){
($id,$model_name,$inter,$ox,$oy,$oz,$rot_x,$rot_y,$rot_z,$rot_w,$lod)=split(/,\s*/);
if($inter){next;}
if($bbox->[0]>$ox){$bbox->[0]=$ox;}
if($bbox->[1]>$oy){$bbox->[1]=$oy;}
if($bbox->[2]<$ox){$bbox->[2]=$ox;}
if($bbox->[3]<$oy){$bbox->[3]=$oy;}
}



}

print "$filename: $bbox->[0] $bbox->[1] $bbox->[2] $bbox->[3]\n";

if($bbox->[0]<0 && $bbox->[2]>0 && $bbox->[1]<0 && $bbox->[3]>0){
print "!!!!!!!!!!!!!!!!!!!!\n";
}

}


