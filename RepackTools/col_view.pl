
open(dd,$ARGV[0]);
binmode(dd);
read(dd,$file,-s(dd));
close(dd);

($sign,$filesize,$model_name,$model_id)=unpack("A4IZ22S",substr($file,0,32));
if($sign ne "COLL" && $sign ne "COL2"  && $sign ne "COL3"  && $sign ne "COL4"){
die "Wrong signature";
}
if($filesize!=length($file)-8){
die "Wrong file size, we have ".length($file).", but we expect ".($filesize+8);
}
print "Found collision for model \"$model_name\", id: $model_id\n";

if($sign eq "COLL"){
die "not implemented";
}

if($sign eq "COL2" ||$sign eq "COL3"){
($min_x,$min_y,$min_z,$max_x,$max_y,$max_z,
$center_x,$center_y,$center_z,$radius)=unpack("ffffffffff",substr($file,32,40));
print <<OUT;
Bounding box:
min, max: TVector: $min_x x $min_y x $min_z ... $max_x x $max_y x $max_z
center  : TVector: $center_x x $center_y x $center_z
radius  : float: $radius
OUT
}


if($sign eq "COL2" || $sign eq "COL3"){
($num_spheres,$num_boxes,$num_mesh_faces,$num_lines,$null,$flags,
$off_spheres,$off_boxes,$off_lines,$off_mesh_verts,$off_mesh_faces,$off_planes)=unpack("SSSCCIIIIIII",
substr($file,32+40,36));

print <<OUT;

Version 2 info
Spheres: $num_spheres\t(offset: $off_spheres)
Boxes:   $num_boxes\t(offset: $off_boxes)
Lines:   $num_lines\t(offset: $off_lines)
Mesh faces: $num_mesh_faces\t(offset verts: $off_mesh_verts, faces: $off_mesh_faces, planes: $off_planes)
Null:    $null
OUT

print "Flags: $flags\n";
if($flags&1){print " - collision uses cones instead of lines (flag forced to false by engine upon loading)\n";}
if($flags&2){print " - not empty (collision model has spheres or boxes or a mesh)\n";}
if($flags&8){print " - has face groups (if not empty)\n";}
if($flags&16){print " - has shadow mesh (col 3)}\n";}
}



if($sign eq "COL3"){
($num_shadow_faces,$off_shadow_verts,$off_shadow_faces)=unpack("III",substr($file,32+40+36,12));

print <<OUT;

Version 3 info
Shadow faces: $num_shadow_faces, offset to verts: $off_shadow_verts, faces: $off_shadow_faces
OUT
}

print "Parsing shadow model...\n";
# TODO: add version validation and flags checking

$verts=substr($file,$off_mesh_verts+4);
@verts=();
#showhex($verts);
$len=length($verts)/6;
print "here vertex data: ".$len." verts\n";
for($q=0;$q<$len;$q++){
push(@verts,[map{sprintf("%.3f",$_/128)}unpack("sss",substr($verts,$q*6,6))]);
#print "$q: ".join(" x ",map{sprintf("%.3f",$_/128)}unpack("sss",substr($verts,$q*6,6)))."\n";
}

$faces=substr($file,$off_shadow_faces+4);
$len=length($faces)/8;
#showhex($faces);
print "here face data: ".$len." faces (must be ~$num_shadow_faces)\n";
for($q=0;$q<$len;$q++){
push(@poly,[unpack("SSS",substr($faces,$q*8,6))]);
#print "$q: ".join(" x ",unpack("SSSCC",substr($faces,$q*8,8)))."\n";
}

writeSTL("shadow",[@verts],[@poly]);


print "Parsing main collision model...";



$verts=substr($file,$off_shadow_verts+4,$off_shadow_faces-$off_shadow_verts);
#showhex($verts);
$len=length($verts)/6;
print "here vertex data: ".$len." verts\n";
for($q=0;$q<$len;$q++){
push(@verts,[map{sprintf("%.3f",$_/128)}unpack("sss",substr($verts,$q*6,6))]);
#print "$q: ".join(" x ",map{sprintf("%.3f",$_/128)}unpack("sss",substr($verts,$q*6,6)))."\n";
}

$faces=substr($file,$off_mesh_faces+4);
$len=$num_mesh_faces;
@poly=();
#showhex($faces);
print "here face data: ".$len." faces\n";
for($q=0;$q<$len;$q++){
push(@poly,[unpack("SSS",substr($faces,$q*8,6))]);
#print "$q: ".join(" x ",unpack("SSSCC",substr($faces,$q*8,8)))."\n";
}

writeSTL("mainmesh",[@verts],[@poly]);

print "loading box data...\n";
$box=substr($file,$off_boxes+4);
@verts=();
@poly=();
for($q=0;$q<$num_boxes;$q++){
($min_x,$min_y,$min_z,$max_x,$max_y,$max_z,$surf_mat,$surf_flag,$surf_bright,$surf_light)=unpack("ffffffCCCC",substr($box,$q*12,12));

$h=@verts;
push(@verts,[$min_x,$min_y,$min_z]);
push(@verts,[$min_x,$min_y,$max_z]);
push(@verts,[$max_x,$min_y,$min_z]);
push(@verts,[$max_x,$min_y,$max_z]);
push(@verts,[$min_x,$max_y,$min_z]);
push(@verts,[$min_x,$max_y,$max_z]);
push(@verts,[$max_x,$max_y,$min_z]);
push(@verts,[$max_x,$max_y,$max_z]);
push(@poly,[$h,]

print
}


sub showhex{
open(hh,"|hexdump -C");
print hh $_[0];
close(hh);

}



sub writeSTL{
my $filename=shift;
my $verts=shift;
my $polys=shift;
my @poly=@{$polys};
my @vert=map{join("",pack("fff",@{$_}))}@{$verts};
my $poly_count=@poly;

open(ss,">test-".$filename.".stl");
binmode(ss);
print ss "\x00" x 80;
print ss pack("I",$poly_count);


for($q=0;$q<$poly_count;$q++){
# normal vector
print ss pack("III",0,0,0);
$p=$polys->[$q];
print ss $vert[$p->[0]];
print ss $vert[$p->[1]];
print ss $vert[$p->[2]];
print ss pack("S",0);
}


}


