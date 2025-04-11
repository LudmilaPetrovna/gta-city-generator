use Data::Dumper;
use File::Find;
use File::Path qw(make_path remove_tree);
use File::Basename;
use Digest::MD5 "md5_hex";
use Digest::CRC qw(crc64 crc32 crc16);


$src_dir="img_unpacked/";
$build=0x1803FFFF;
load_names();

($action,$workfile)=@ARGV;

if($action eq "dump"){
dump_dff($workfile);
}

if($action eq "join"){
join_dff($workfile);
}



sub join_dff{

$filename=shift;
$filename_short=basename($filename);
$file_prefix=$filename_short;
$file_prefix=~s/\.dff$//si;
$file_prefix.='-chunkdump';
$file="";
$workdir=dirname($filename);

# searching for previous dump
@src_files=();
opendir(ddd,$workdir);
map{
push(@src_files,$workdir.'/'.$_);
}grep{index($_,$file_prefix)==0 && /\.bin$/}readdir(ddd);
closedir(ddd);

@src_files=sort @src_files;

$struct=[];
foreach $src_chunk(@src_files){
if($src_chunk=~/chunkdump((-[\da-f]+\(\d+\))+)\.bin$/si){
$path=$1;

open(dd,$src_chunk) or die $!;
read(dd,$chunk_data,-s(dd));
close(dd);

#$chunk_data="DATA";

$cp=$struct;
@paths=split(/-/,$path);
$last_path=@paths-1;
for($q=0;$q<=$last_path;$q++){
$path_id=$paths[$q];
if(!$path_id){next;}
if($path_id!~/([\da-f]+)\((\d+)\)/si){next;}
($chunk_id,$chunk_pos)=($1,$2);
$chunk_id=hex($chunk_id);
#$chunk_pos/=10;
if(!exists $cp->[$chunk_pos]){
$cp->[$chunk_pos]=[$chunk_id,[]];
}
$cp=$cp->[$chunk_pos]->[1];
}
push(@{$cp},$chunk_data);

}
}

my $dff=join_walk($struct);

open(oo,">".$file_prefix."-rebuld.dff") or die $!;
print oo $dff;
close(oo);
}


sub join_walk{
my $arr=shift;
my $level=shift;
my $el;
my $type;
my $ret;
my $joined;
foreach $el(@{$arr}){
$type=ref $el;
if(!defined $el){next;}
if($type eq 'ARRAY'){
$joined=join_walk($el->[1],$level+1);
$el=pack("III",$el->[0],length($joined),$build).$joined;
}
$ret.=$el;
}
return($ret);
}


sub dump_dff{

$filename=shift;
$filename_short=basename($filename);
$file_prefix=$filename_short;
$file_prefix=~s/\.dff$//si;
$file_prefix.='-chunkdump';
$file="";
$workdir=dirname($filename);

open(dd,$filename) or die $!;
read(dd,$file,-s(dd));
close(dd);

print "dumping structure of $filename...                             \n";
$file_build=unpack("I",substr($file,8,4));

if($file_build!=$build){
die "$filename: possible broken or not SA file ".sprintf("(we expect build %08x, but have %08x)\n",$build,$file_build);
}

# remove previous dump

opendir(ddd,$workdir);
map{
my $fpath=$workdir.'/'.$_;
print "Removing $fpath\n";
unlink($fpath);
}grep{index($_,$file_prefix)==0 && /\.bin$/}readdir(ddd);
closedir(ddd);

walk_dump(0,length($file),0,0,"");
}



sub write_chunk{
my $offset=shift;
my $len=shift;
my $level=shift;
my $path=shift;
my $out_chunk=$file_prefix.$path.'.bin';
print "$filename: ".("  " x $level)." Writing chunk to $out_chunk\n";
open(oo,">".$out_chunk);binmode(oo);print oo substr($file,$offset,$len);close(oo);
print_color_hex(substr($file,$offset,$len),16,$level);
}


sub walk_dump{
my $offset=shift;
my $len=shift;
my $level=shift;
my $parent_id=shift;
my $path=shift;
my $buf;
my($chunk_id,$chunk_len,$chunk_version);
my $pos=0;
my $uid=0;

while($pos+12<=$len){
print "$filename: ".("  " x $level)." Reading at $offset+$pos/$len in ".get_named_path($path)."...\n";
($chunk_id,$chunk_len,$chunk_version)=unpack("III",substr($file,$offset+$pos,12));
if($chunk_version!=$build){ # possible we in a leaf node, dump it all
write_chunk($offset+$pos,$len-$pos,$level,$path);
return;
}
if($chunk_len>$len){die "$filename: Internal chunk ($path:".sprintf("%08X",$chunk_id)." len size ($chunk_len) is more than parent chunk ($path:$len)! Data may be broken!";}
#print "$filename: ".("  " x $level)." we got $chunk_id ($names{$chunk_id}->[0]),$chunk_len,$chunk_version)\n";

$path2=sprintf("%s-%.2X(%d)",$path,$chunk_id,(++$uid)*10);

if($chunk_len>=12){
walk_dump($offset+$pos+12,$chunk_len,$level+1,$chunk_id,$path2);
} else {
# write even 0 bytes, let's empty sections persist
write_chunk($offset+$pos+12,$chunk_len,$level+1,$path2);
}
$pos+=$chunk_len+12;
}

if($pos!=$len){
write_chunk($offset+$pos,$len-$pos,$level,$path2.'-tail');
}

}



sub load_names{
%names=map{@v=split(/\t/);hex($v[0]),[@v[1..3]]}split(/[\r\n]+/,<<DATA);
0x00000001	Struct	Core	A generic section that stores data for its parent.
0x00000002	String	Core	Stores a 4-byte aligned ASCII string.
0x00000003	Extension	Core	A container for non-standard extensions of its parent section.
0x00000005	Camera	Core	Contains a camera (unused in GTA games).
0x00000006	Texture	Core	Stores the sampler state of a texture.
0x00000007	Material	Core	Defines a material to be used on a geometry.
0x00000008	Material List	Core	Container for a list of materials.
0x00000009	Atomic Section	Core	
0x0000000A	Plane Section	Core	
0x0000000B	World	Core	The root section of the level geometry.
0x0000000C	Spline	Core	
0x0000000D	Matrix	Core	
0x0000000E	Frame List	Core	Container for a list of frames. A frame holds the transformation that is applied to an Atomic.
0x0000000F	Geometry	Core	A platform-independent container for meshes.
0x00000010	Clump	Core	The root section for a 3D model.
0x00000012	Light	Core	Stores different dynamic lights.
0x00000013	Unicode String	Core	
0x00000014	Atomic	Core	Defines the basic unit for the RenderWare graphics pipeline. Generally speaking, an Atomic can be directly converted to a single draw call.
0x00000015	Raster	Core	Stores a platform-dependent (i.e. native) texture image.
0x00000016	Texture Dictionary	Core	A container for texture images (also called raster).
0x00000017	Animation Database	Core	
0x00000018	Image	Core	An individual texture image.
0x00000019	Skin Animation	Core	
0x0000001A	Geometry List	Core	A container for a list of geometries.
0x0000001B	Anim Animation	Core	
0x0000001C	Team	Core	
0x0000001D	Crowd	Core	
0x0000001E	Delta Morph Animation	Core	
0x0000001f	Right To Render	Core	Stores the render pipeline the engine uses to draw an atomic or material.
0x00000020	MultiTexture Effect Native	Core	
0x00000021	MultiTexture Effect Dictionary	Core	
0x00000022	Team Dictionary	Core	
0x00000023	Platform Independent Texture Dictionary	Core	
0x00000024	Table of Contents	Core	
0x00000025	Particle Standard Global Data	Core	
0x00000026	AltPipe	Core	
0x00000027	Platform Independent Peds	Core	
0x00000028	Patch Mesh	Core	
0x00000029	Chunk Group Start	Core	
0x0000002A	Chunk Group End	Core	
0x0000002B	UV Animation Dictionary	Core	
0x0000002C	Coll Tree	Core	
0x00000101	Metrics PLG	Toolkit	
0x00000102	Spline PLG	Toolkit	
0x00000103	Stereo PLG	Toolkit	
0x00000104	VRML PLG	Toolkit	
0x00000105	Morph PLG	Toolkit	
0x00000106	PVS PLG	Toolkit	
0x00000107	Memory Leak PLG	Toolkit	
0x00000108	Animation PLG	Toolkit	
0x00000109	Gloss PLG	Toolkit	
0x0000010a	Logo PLG	Toolkit	
0x0000010b	Memory Info PLG	Toolkit	
0x0000010c	Random PLG	Toolkit	
0x0000010d	PNG Image PLG	Toolkit	
0x0000010e	Bone PLG	Toolkit	
0x0000010f	VRML Anim PLG	Toolkit	
0x00000110	Sky Mipmap Val	Toolkit	Stores MipMap parameters for the PS2 version of the engine (codenamed Sky).
0x00000111	MRM PLG	Toolkit	
0x00000112	LOD Atomic PLG	Toolkit	
0x00000113	ME PLG	Toolkit	
0x00000114	Lightmap PLG	Toolkit	
0x00000115	Refine PLG	Toolkit	
0x00000116	Skin PLG	Toolkit	
0x00000117	Label PLG	Toolkit	
0x00000118	Particles PLG	Toolkit	
0x00000119	GeomTX PLG	Toolkit	
0x0000011a	Synth Core PLG	Toolkit	
0x0000011b	STQPP PLG	Toolkit	
0x0000011c	Part PP PLG	Toolkit	
0x0000011d	Collision PLG	Toolkit	
0x0000011e	HAnim PLG	Toolkit	
0x0000011f	User Data PLG	Toolkit	
0x00000120	Material Effects PLG	Toolkit	
0x00000121	Particle System PLG	Toolkit	
0x00000122	Delta Morph PLG	Toolkit	
0x00000123	Patch PLG	Toolkit	
0x00000124	Team PLG	Toolkit	
0x00000125	Crowd PP PLG	Toolkit	
0x00000126	Mip Split PLG	Toolkit	
0x00000127	Anisotropy PLG	Toolkit	Stores the anisotropy for a texture filter.
0x00000129	GCN Material PLG	Toolkit	
0x0000012a	Geometric PVS PLG	Toolkit	
0x0000012b	XBOX Material PLG	Toolkit	
0x0000012c	Multi Texture PLG	Toolkit	
0x0000012d	Chain PLG	Toolkit	
0x0000012e	Toon PLG	Toolkit	
0x0000012f	PTank PLG	Toolkit	
0x00000130	Particle Standard PLG	Toolkit	
0x00000131	PDS PLG	Toolkit	
0x00000132	PrtAdv PLG	Toolkit	
0x00000133	Normal Map PLG	Toolkit	
0x00000134	ADC PLG	Toolkit	
0x00000135	UV Animation PLG	Toolkit	
0x00000180	Character Set PLG	Toolkit	
0x00000181	NOHS World PLG	Toolkit	
0x00000182	Import Util PLG	Toolkit	
0x00000183	Slerp PLG	Toolkit	
0x00000184	Optim PLG	Toolkit	
0x00000185	TL World PLG	Toolkit	
0x00000186	Database PLG	Toolkit	
0x00000187	Raytrace PLG	Toolkit	
0x00000188	Ray PLG	Toolkit	
0x00000189	Library PLG	Toolkit	
0x00000190	2D PLG	Toolkit	
0x00000191	Tile Render PLG	Toolkit	
0x00000192	JPEG Image PLG	Toolkit	
0x00000193	TGA Image PLG	Toolkit	
0x00000194	GIF Image PLG	Toolkit	
0x00000195	Quat PLG	Toolkit	
0x00000196	Spline PVS PLG	Toolkit	
0x00000197	Mipmap PLG	Toolkit	
0x00000198	MipmapK PLG	Toolkit	
0x00000199	2D Font	Toolkit	
0x0000019a	Intersection PLG	Toolkit	
0x0000019b	TIFF Image PLG	Toolkit	
0x0000019c	Pick PLG	Toolkit	
0x0000019d	BMP Image PLG	Toolkit	
0x0000019e	RAS Image PLG	Toolkit	
0x0000019f	Skin FX PLG	Toolkit	
0x000001a0	VCAT PLG	Toolkit	
0x000001a1	2D Path	Toolkit	
0x000001a2	2D Brush	Toolkit	
0x000001a3	2D Object	Toolkit	
0x000001a4	2D Shape	Toolkit	
0x000001a5	2D Scene	Toolkit	
0x000001a6	2D Pick Region	Toolkit	
0x000001a7	2D Object String	Toolkit	
0x000001a8	2D Animation PLG	Toolkit	
0x000001a9	2D Animation	Toolkit	
0x000001b0	2D Keyframe	Toolkit	
0x000001b1	2D Maestro	Toolkit	
0x000001b2	Barycentric	Toolkit	
0x000001b3	Platform Independent Texture Dictionary TK	Toolkit	
0x000001b4	TOC TK	Toolkit	
0x000001b5	TPL TK	Toolkit	
0x000001b6	AltPipe TK	Toolkit	
0x000001b7	Animation TK	Toolkit	
0x000001b8	Skin Split Tookit	Toolkit	
0x000001b9	Compressed Key TK	Toolkit	
0x000001ba	Geometry Conditioning PLG	Toolkit	
0x000001bb	Wing PLG	Toolkit	
0x000001bc	Generic Pipeline TK	Toolkit	
0x000001bd	Lightmap Conversion TK	Toolkit	
0x000001be	Filesystem PLG	Toolkit	
0x000001bf	Dictionary TK	Toolkit	
0x000001c0	UV Animation Linear	Toolkit	
0x000001c1	UV Animation Parameter	Toolkit	
0x0000050E	Bin Mesh PLG	World	
0x00000510	Native Data PLG	World	
0x0000EA13	EARS Material Data	EARS	
0x0000EA15		EARS	
0x0000EA16	EARS Mesh Plugin	EARS	
0x0000EA20		EARS	
0x0000EA28	EARS Zone Plugin	EARS	
0x0000EA2D	EARS Lt Map 2	EARS	
0x0000EA2E	EARS Rp Partial Instance	EARS	
0x0000EA2F	EARS Texture Plugin	EARS	
0x0000EA33	EARS Mesh	EARS	Stores mesh data.
0x0000EA40	EARS Atomic Plugin	EARS	
0x0000EA44	EARS Display List	EARS	
0x0000EA45	EARS Rp Shader	EARS	
0x0000EA80	EARS Rp Alchemy	EARS	
0x0000EA92	EARS Morph Target Data	EARS	
0x0000F21E	ZModeler Lock	ZModeler	Unofficial extension that stores a password that protects the file from being modified when opened in ZModeler. Ignored by other applications like RWAnalyze and the GTA games.
0x00CAFE40	THQ Atomic	THQ	Jimmy Neutron: Attack of the Twonkies custom. Atomic rendering flags.
0x00CAFE45	THQ Material	THQ	Jimmy Neutron: Attack of the Twonkies custom. Extended material parameters.
0x0253F200	Atomic Visibility Distance	R*	
0x0253F201	Clump Visibility Distance	R*	
0x0253F202	Frame Visibility Distance	R*	
0x0253F2F3	Pipeline Set	R*	Stores the render pipeline used to draw objects with R*-specific plug-ins.
0x0253F2F5	TexDictionary Link	R*	
0x0253F2F6	Specular Material	R*	Stores a specularity map.
0x0253F2F8	2d Effect	R*	Used to attach various GTA-specific effects to models, for example to enable script interaction or particle effects.
0x0253F2F9	Extra Vert Colour	R*	Stores an additional array of vertex colors, that are used in GTA during night-time to simulate some effects of dynamic global lighting.
0x0253F2FA	Collision Model	R*	Stores a collision model.
0x0253F2FB	GTA HAnim	R*	
0x0253F2FC	Reflection Material	R*	Enables advanced environment mapping.
0x0253F2FD	Breakable	R*	Contains a mesh that is used to render objects that are breakable (like windows or tables).
0x0253F2FE	Frame	R*	Stores the name of a frame within a Frame List.
DATA
}

sub get_named_path{
my $path=shift;
my $named=$path;
$named=~s/([\da-f]+)(\(\d+\))/$1.'['.$names{hex($1)}->[0].']'/egsi;
$named="chunk".$named;
return($named);
}

sub print_color_hex{
my $data=shift;
my $width=shift;
my $level=shift;
my $format=shift;

my $text="";
my $pad="";
my $offset=0;
my $q;
my $len=length($data);
my $byte;
my $line=1;
while($offset<$len){
printf('%s: %s '."\x1b".'[1;44;33m%08X: (line %2d) ',$filename,"  " x $level,$offset,$line);
$line++;
for($q=0;$q<$width;$q++){
if($offset+$q>=$len){last;}
$byte=ord(substr($data,$offset+$q,1));
printf("\x1b[38;5;%d;48;5;%dm%02X\x1b[0m ",$byte^0x80,$byte,$byte);
}
$pad=$q%$width;
print "    ".($pad?("   " x (16-$pad)):"");
if($format){
print "vals: ".join(", ",unpack($format,substr($data,$offset,$width)));
} else {
# writing text
for($q=0;$q<$width;$q++){
if($offset+$q>=$len){last;}
$byte=ord(substr($data,$offset+$q,1));
printf("\x1b[38;5;%d;48;5;%dm%c",$byte^0x80,$byte,$byte>=0x20&&$byte<=0x7E?$byte:ord('.'));
}

}
print "\x1b[0m\n";
$offset+=$width;
}

}
