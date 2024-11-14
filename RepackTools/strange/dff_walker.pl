
$g_version=0x1803FFFF;

$rpGEOMETRYTRISTRIP =0x00000001;         	#Is triangle strip (if disabled it will be an triangle list)
$rpGEOMETRYPOSITIONS=0x00000002;        	#Vertex translation
$rpGEOMETRYTEXTURED =0x00000004;         	#Texture coordinates
$rpGEOMETRYPRELIT   =0x00000008;   		#Vertex colors
$rpGEOMETRYNORMALS  =0x00000010;  		#Store normals
$rpGEOMETRYLIGHT    =0x00000020;    		#Geometry is lit (dynamic and static)
$rpGEOMETRYMODULATEMATERIALCOLOR=0x00000040;    #Modulate material color
$rpGEOMETRYTEXTURED2=0x00000080;       		#Texture coordinates 2
$rpGEOMETRYNATIVE   =0x01000000;   		#Native Geometry

$types={};
map{($id,$text)=split(/ - /,$_,2);$types->{hex($id)}=$text;}split(/\n+/,<<AAA);
105 - CHUNK_MORPH
110 - CHUNK_SKYMIPMAP
116 - CHUNK_SKIN
118 - CHUNK_PARTICLES
120 - CHUNK_MATERIALEFFECTS
131 - CHUNK_PDSPLG
134 - CHUNK_ADCPLG
135 - CHUNK_UVANIMPLG
253F2F3 - Rocks Pipeline Set
253F2F6 - Rocks Specular Material
253F2F8 - Rocks 2dfx
253F2F9 - Rocks Night Vertex Colors
253F2FA - Rocks Collision Model
253F2FC - Rocks Reflection Material
253F2FD - Rocks Mesh Extension
253F2FE - Rocks Frame
50E - rwMATERIALSPLIT / CHUNK_BINMESH
01 - STRUCT (data)
02 - Plain string
0E - Frame List (RW Section)
03 - Extension (RW Section)
08 - Material List (RW Section)
510 - Native Data PLG (RW Section) / CHUNK_VERTEXFORMAT
11E - HAnim PLG (RW Section)
1A - Geometry List (RW Section)
253F2FE - Node Name (RW Section)
14 − rwID_ATOMIC - составная часть модели (тип RpAtomic)
05 − rwID_CAMERA - камера (тип RwCamera)
10 − rwID_CLUMP - Clump (тип RpClump)
0F − rwID_GEOMETRY - геометрия модели (тип RpGeometry)
18 − rwID_IMAGE - картинка (тип RwImage)
12 − rwID_LIGHT - источник освещения (тип RpLight)
07 − rwID_MATERIAL - материал модели (тип RpMaterial)
0D − rwID_MATRIX - матрица (тип RwMatrix)
16 − rwID_TEXDICTIONARY - список текстур (тип RwTexDictionary)
06 − rwID_TEXTURE - текстура (тип RwTexture)
0B − rwID_WORLD - мир/уровень (тип RpWorld)
29 − rwID_CHUNKGROUPSTART – старт группы Chunk (тип RwChunkGroup)
2A − rwID_CHUNKGROUPEND – конец группы Chunk (тип RwChunkGroup)
AAA

open(dd,$ARGV[0]);
binmode(dd);
read(dd,$file,-s(dd));


walk(0,length($file),0);


sub walk{
my $offset=shift;
my $len=shift;
my $level=shift;
my $parent_id=shift;
my $buf;
my($chunk_id,$chunk_len,$chunk_version);;
my $pos=0;

#print "Entering in $offset, len $len (level $level)\n";

while($pos<$len){
$buf=substr($file,$offset+$pos,12);
($chunk_id,$chunk_len,$chunk_version)=unpack("III",$buf);



if($chunk_version != $g_version){
last;
}

if($chunk_len>$len){
die "Internal chunk len size is more than parent chunk! Data may be broken!";
}

print "".("  " x $level).sprintf("%08x: chunk %02x, len %04x (%d) bytes ... up to %08x",$offset+$pos,$chunk_id,$chunk_len,$chunk_len,$offset+$pos+$chunk_len+12).": ".$types->{$chunk_id}."\n";


if($parent_id==0x10 && $chunk_id==0x01 && $chunk_len>=12){
($models_parts,$lights_count,$cams_count)=unpack("III",substr($file,$offset+$pos+12,12));
print "".("  " x $level)."We found: parts: $models_parts, lights: $lights_count, cams: $cams_count\n";
}

if($parent_id==0x0E && $chunk_id==0x01 && $chunk_len>=4){
($frames_count)=unpack("I",substr($file,$offset+$pos+12,4));
print "".("  " x $level)."We found: frames: $frames_count\n";
}

if($parent_id==0x03 && $chunk_id==0x253F2FE && $chunk_len>=1){
$node_name=substr($file,$offset+$pos+12,$chunk_len);
print "".("  " x $level)."We found name: \"$node_name\"\n";
}

if($chunk_id==0x02 && $chunk_len>=1){
$string=substr($file,$offset+$pos+12,$chunk_len);
print "".("  " x $level)."We found string: \"$string\"\n";
}

if($parent_id==0x1a && $chunk_id==0x1 && $chunk_len==4){
($geometries_count)=unpack("I",substr($file,$offset+$pos+12,4));
print "".("  " x $level)."We found: $geometries_count geomeries\n";
}

if($parent_id==0x0f && $chunk_id==0x1 && $chunk_len>=16){
($format,$triangles_count,$verts_count,$morph_count)=unpack("iiii",substr($file,$offset+$pos+12,16));
$numTexSets=($format>>16)&0xFF;

my $polys=[];
my $verts=[];
my $q;

if($morph_count!=1){
die "GTA San Andreas not using morph targets!";
}
$minipos=12+16;
if(($format&$rpGEOMETRYNATIVE)==0){

if($format&$rpGEOMETRYPRELIT){
$color=unpack("I",substr($file,$offset+$pos+$minipos,4));
$minipos+=4*$verts_count;
print "skipped $verts_count prelite points, we at ".sprintf("%08x",$offset+$pos+$minipos)."\n";
}

if($format&$rpGEOMETRYTEXTURED){
#skip UV coords
$minipos+=8*$numTexSets*$verts_count;
print "skipped $numTexSets UV\n";
}

# load triangles
for($q=0;$q<$triangles_count;$q++){
($vertex2, $vertex1, $materialId, $vertex3)=unpack("SSSS",substr($file,$offset+$pos+$minipos,8));
$minipos+=8;
$polys->[$q]=[$vertex1,$vertex2,$vertex3];
#print "poly $vertex1,$vertex2,$vertex3\n";
}
print "$triangles_count triangles loaded\n";

}

# decode morphs
($bound_x,$bound_y,$bound_z,$bound_r)=unpack("ffff",substr($file,$offset+$pos+$minipos,16));
$minipos+=16;

print "bounding box: $bound_x,$bound_y,$bound_z,$bound_r\n";

($has_verts,$has_normals)=unpack("II",substr($file,$offset+$pos+$minipos,8));
$minipos+=8;
if($has_verts){
# load vertexes
for($q=0;$q<$verts_count;$q++){
($ox,$oy,$oz)=unpack("fff",substr($file,$offset+$pos+$minipos,12));
$minipos+=12;;
$verts->[$q]=[$ox,$oy,$oz];
}
print "loaded $verts_count vertex\n";
}

if($has_normals && $format&$rpGEOMETRYNORMALS){
# skip normals
$minipos+=12*$verts_count;
print "skipped $verts_count normals\n";

}

print "".("  " x $level)."Prelit color: $color, triangles: $triangles_count, verts: $verts_count\n";
print "".("  " x $level)."end of data at: ".sprintf("%08x",$offset+$pos+$minipos)."\n";
writeSTL("shit.".(++$uniqstl),$verts,$polys);
}

if($parent_id==0x08 && $chunk_id==0x1 && $chunk_len>4){
($mats_count)=unpack("I",substr($file,$offset+$pos+12,4));
print "".("  " x $level)."We found: materials $mats_count\n";
for($q=0;$q<$mats_count;$q++){
($mat_id)=unpack("i",substr($file,$offset+$pos+12+4+$q*4,4));
print "".("  " x $level)."We found: mat id: $mat_id\n";
}
}



walk($offset+$pos+12,$chunk_len,$level+1,$chunk_id);
$pos+=$chunk_len+12;

}



return($pos);
}




sub writeSTL{
my $filename=shift;
my $verts=shift;
my $polys=shift;

my $poly_count=@{$polys};

my @verts2=map{pack("fff",@{$_})}@{$verts};
my $verts3=join("",@verts2);

print "Building model out of ".(length($verts3)/12)." vertexes\n";
print "Building model out of ".@verts2." vertexes\n";

open(ss,">".$filename."-debug.stl");
binmode(ss);
print ss "\x00" x 80;
print ss pack("I",$poly_count);
my $q;
for($q=0;$q<$poly_count;$q++){
# normal vector
print ss pack("III",0,0,0);


if(!$verts2[$polys->[$q]->[0]]){die "wrong 1 $q, we want $polys->[$q]->[0]";}
if(!$verts2[$polys->[$q]->[1]]){die "wrong 2 $q, we want $polys->[$q]->[1]";}
if(!$verts2[$polys->[$q]->[2]]){die "wrong 3 $q, we want $polys->[$q]->[2]";}

print ss $verts2[$polys->[$q]->[0]];
print ss $verts2[$polys->[$q]->[1]];
print ss $verts2[$polys->[$q]->[2]];
print ss pack("S",0);
}

}

