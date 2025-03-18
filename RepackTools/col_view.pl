use Data::Dumper;

$target=$ARGV[0];

open(dd,$target) or die;
binmode(dd);
read(dd,$file,-s(dd));
close(dd);

#if(length($file)<500){exit(0);}

($sign,$filesize,$model_name,$model_id)=unpack("A4IZ22S",substr($file,0,32));
if($sign ne "COLL" && $sign ne "COL2"  && $sign ne "COL3"  && $sign ne "COL4"){
die "Wrong signature";
}
if($filesize!=length($file)-8){
die "Wrong file size, we have ".length($file).", but we expect ".($filesize+8).", maybe it archive? or try to unpack by other tool";
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

$has_cones=0;
$has_face_groups=0;
$has_shadows=0;
$has_planes=0;

if($off_planes>0){
$has_planes=1;
}

print "Flags: $flags\n";
if($flags&1){
print " - collision uses cones instead of lines (flag forced to false by engine upon loading)\n";
$has_cones=1;
}
if($flags&2){
print " - not empty (collision model has spheres or boxes or a mesh)\n";
}
if($flags&8){
print " - has face groups (if not empty)\n";
$has_face_groups=1;
}
if($flags&16){
print " - has shadow mesh (col 3)}\n";
$has_shadows=1;
}

}



if($sign eq "COL3"){
($num_shadow_faces,$off_shadow_verts,$off_shadow_faces)=unpack("III",substr($file,32+40+36,12));

print <<OUT;

Version 3 info
Shadow faces: $num_shadow_faces, offset to verts: $off_shadow_verts, faces: $off_shadow_faces
OUT
}


if(
$off_shadow_verts>$filesize ||
$off_shadow_faces>$filesize ||
$off_spheres>$filesize ||
$off_boxes>$filesize ||
$off_lines>$filesize ||
$off_mesh_verts>$filesize ||
$off_mesh_faces>$filesize ||
$off_planes>$filesize){print "$target: one or more offsets targets over file end, file may be corrupted or from other game (like Bully)\n";exit(0);}


print "$target: $sign have ".($filesize+8)." bytes $num_spheres spheres, $num_boxes boxes, $num_mesh_faces meshface, $num_lines lines, $has_shadows ($num_shadow_faces) shadows, $has_cones cones, $has_face_groups fgroups, $has_planes planes\n";

print "Parsing shadow model...\n";
# TODO: add version validation and flags checking

%mat_used=();

$verts=substr($file,$off_shadow_verts+4);
@verts=();
@poly=();
#showhex($verts);
$len=length($verts)/6;
print "here vertex data: ".$len." verts\n";
for($q=0;$q<$len;$q++){
push(@verts,[map{sprintf("%.3f",$_/128)}unpack("sss",substr($verts,$q*6,6))]);
#print "$q: ".join(" x ",map{sprintf("%.3f",$_/128)}unpack("sss",substr($verts,$q*6,6)))."\n";
}


$faces=substr($file,$off_shadow_faces+4);
$len=$num_shadow_faces;
#showhex($faces);
print "here face data: ".$len." faces (must be ~$num_shadow_faces)\n";
for($q=0;$q<$len;$q++){
push(@poly,[unpack("SSS",substr($faces,$q*8,6))]);
print "$q: ".join(" x ",unpack("SSSCC",substr($faces,$q*8,8)))."\n";
}

writeSTL("shadow",[@verts],[@poly]);

print "Parsing main collision model...";


@verts=();
@poly=();

$verts=substr($file,$off_mesh_verts+4);
#showhex($verts);
$len=length($verts)/6;
print "here vertex data: ".$len." verts\n";
for($q=0;$q<$len;$q++){
push(@verts,[map{sprintf("%.3f",$_/128)}unpack("sss",substr($verts,$q*6,6))]);
#print "$q: ".join(" x ",map{sprintf("%.3f",$_/128)}unpack("sss",substr($verts,$q*6,6)))."\n";
}

$faces=substr($file,$off_mesh_faces+4);
$len=$num_mesh_faces;
#showhex($faces);
print "here face data: ".$len." faces\n";
for($q=0;$q<$len;$q++){
push(@poly,[unpack("SSS",substr($faces,$q*8,6))]);
($mat,$light)=unpack("CC",substr($faces,$q*8+6,2));
$mat_used{$mat}++;
#print "$q: ".join(" x ",unpack("SSSCC",substr($faces,$q*8,8)))."\n";
}

writeSTL("mainmesh",[@verts],[@poly]);



print "loading box data...\n";

$cube_verts=[
[0,0,0],
[1,0,0],
[0,1,0],
[1,1,0],
[0,0,1],
[1,0,1],
[0,1,1],
[1,1,1]
];

$cube_faces=[
[1,3,4],
[4,2,1],
[5,6,8],

[8,7,5],
[1,2,6],
[6,5,1],

[2,4,8],
[8,6,2],
[4,3,7],

[7,8,4],
[3,1,5],
[5,7,3]
];

$box=substr($file,$off_boxes+4);
#@verts=();@poly=();
for($q=0;$q<$num_boxes;$q++){
($min_x,$min_y,$min_z,$max_x,$max_y,$max_z,$surf_mat,$surf_flag,$surf_bright,$surf_light)=unpack("ffffffCCCC",substr($box,$q*28,28));
@sizes=($max_x-$min_x,$max_y-$min_y,$max_z-$min_z);
$h=@verts;
$mat_used{$surf_mat}++;

for($p=0;$p<8;$p++){
push(@verts,[
$cube_verts->[$p]->[0]*$sizes[0]+$min_x,
$cube_verts->[$p]->[1]*$sizes[1]+$min_y,
$cube_verts->[$p]->[2]*$sizes[2]+$min_z
]);
}

for($p=0;$p<12;$p++){
push(@poly,[
$h+$cube_faces->[$p]->[0]-1,
$h+$cube_faces->[$p]->[1]-1,
$h+$cube_faces->[$p]->[2]-1
]);
}

}


writeSTL("boxes",[@verts],[@poly]);



#Writing spheres

print "Loading spheres: count: $num_spheres, offset: $off_spheres\n";
$sp=substr($file,$off_spheres+4);
for($q=0;$q<$num_spheres;$q++){
($center_x,$center_y,$center_z,$radius,$surf_mat,$surf_flag,$surf_bright,$surf_light)=unpack("ffffCCCC",substr($sp,$q*20,20));
$mat_used{$surf_mat}++;
print "Material: $surf_mat\n";
createSphere([$center_x,$center_y,$center_z],$radius,55);
}

stlClose();

print "Materials used:".Dumper(\%mat_used);


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
if(grep{length($_)!=12}@vert){die "wrong vertex";}
my $poly_count=@poly;

open(ss,">test-".$filename.".stl");
binmode(ss);
print ss "\x00" x 80;
print ss pack("I",$poly_count);

$bounds=[];

for($q=0;$q<$poly_count;$q++){
# normal vector
print ss pack("III",0,0,0);
$face=$polys->[$q];
print ss $vert[$face->[0]];
print ss $vert[$face->[1]];
print ss $vert[$face->[2]];
print ss pack("S",0);

for($vid=0;$vid<3;$vid++){
for($ax=0;$ax<3;$ax++){

if($q==0){
$bounds->[0+$ax]=$verts->[$face->[$vid]]->[$ax];
$bounds->[3+$ax]=$verts->[$face->[$vid]]->[$ax];
} else {
if($bounds->[0+$ax]>$verts->[$face->[$vid]]->[$ax]){$bounds->[0+$ax]=$verts->[$face->[$vid]]->[$ax];}
if($bounds->[3+$ax]<$verts->[$face->[$vid]]->[$ax]){$bounds->[3+$ax]=$verts->[$face->[$vid]]->[$ax];}
}

}
}
}

#print "Bounding box: ".Dumper($bounds);

}


sub stlClose{
my $fpos=tell(ss);
my $poly_count=($fpos-80-4)/50;
seek(ss,80,0);
print ss pack("I",$poly_count);
close(ss);
}

sub writeTriangle{
my $pp1=shift;
my $pp2=shift;
my $pp3=shift;
my $offset=shift;
my $q;
print ss pack("III",0,0,0);
foreach my $vert(($pp1,$pp2,$pp3)){
for($q=0;$q<3;$q++){
print ss pack("f",$vert->[$q]+$offset->[$q]);
}
}
print ss pack("S",0);

}




sub getSpherePoint{
my $R=shift;
my $SEGS=shift;
my $q=shift;
my $w=shift;

my $qTheta;
my $wTheta;
my $pp;

$wTheta=($w-1)*1.0/$SEGS*180.0/360*2.0*3.14159265;
$qTheta=($q-1)*1.0/$SEGS*360.0/360*2.0*3.14159265;
$pp=[sin($qTheta)*sin($wTheta)*$R,cos($qTheta)*sin($wTheta)*$R,cos($wTheta)*$R];
return($pp);
}

sub createSphere{
my $POS=shift;
my $R=shift;
my $SEGS=shift;
print "Creating sphere at ".join("x",@{$POS})." ($R radius, $SEGS segments)...\n";

my $q;
my $w;
my $pp1;
my $pp2;
my $pp3;
my $pp4;

for($w=1;$w<=$SEGS;$w++){
for($q=1;$q<=$SEGS;$q++){

$pp1=getSpherePoint($R,$SEGS,$q,  $w);
$pp2=getSpherePoint($R,$SEGS,$q+1,$w);
$pp3=getSpherePoint($R,$SEGS,$q+1,$w+1);
$pp4=getSpherePoint($R,$SEGS,$q,  $w+1);

writeTriangle($pp1,$pp2,$pp3,$POS);
writeTriangle($pp4,$pp1,$pp3,$POS);
}
}

}

