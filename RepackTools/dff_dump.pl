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

my $dff=join_walk($struct,0,"");

open(oo,">".$file_prefix."-rebuld.dff") or die $!;
print oo $dff;
close(oo);
}


sub join_walk{
my $arr=shift;
my $level=shift;
my $syspath=shift;
my $el;
my $type;
my $ret;
my $joined;
my $rests;
foreach $el(@{$arr}){
$type=ref $el;
if(!defined $el){next;}
if($type eq 'ARRAY'){
my $el_path=sprintf("%s_%02x",$syspath,$el->[0]);
if(!exists $restrict{$el_path}){
die "Can't join, we have path $el_path, which is now allowed!";
}
$rests=$restrict{$el_path};
$joined=join_walk($el->[1],$level+1,$el_path);
my $el_size=length($joined);
print "joined $syspath -> $el_path, our size: ".$el_size.", ".($el_size>=$rests->[0]&&$el_size<=$rests->[1]&&(($el_size%$rests->[2])==0)?"good":"\x1b[38;5;222;48;5;33mWARN! Element must be $rests->[0]..$rests->[1], align $rests->[2]!\x1b[0m")."\n";
$el=pack("III",$el->[0],$el_size,$build).$joined;
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



sub view_chunk{
my $data=shift;
my $path=shift;
my $level=shift;

my $syspath=lc($path);
$syspath=~tr/-/_/;
$syspath=~s/\(\d+\)//g;

$func=("check".$syspath);
if(defined &$func){
$errors=&$func($data);
if($errors){
print "$filename: ".("  " x $level)." \x1b[38;5;131m$errors!!!\x1b[0m\n";
}
}

$func=("decode".$syspath);
if(defined &$func){
&$func($data,$level);
}

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
view_chunk(substr($file,$offset+$pos,$len-$pos),$path,$level);
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
view_chunk(substr($file,$offset+$pos+12,$chunk_len),$path2,$level+1);
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

%restrict=map{my($path,$vals)=split(/=/);$path,[split(/,/,$vals)]}split(/\n/,<<DATA);
_10=510,699795,1
_10_01=4,12,4
_10_03=0,14900,4
_10_03_253f2fa=160,14888,4
_10_0e=99,10203,1
_10_0e_01=60,6556,4
_10_0e_03=0,782,1
_10_0e_03_11e=12,752,4
_10_0e_03_253f2fe=2,23,1
_10_12=48,48,8
_10_12_01=24,24,8
_10_12_03=0,0,8
_10_14=40,92,4
_10_14_01=16,16,8
_10_14_03=0,52,4
_10_14_03_120=4,4,4
_10_14_03_1f=8,8,8
_10_14_03_253f2f3=4,4,4
_10_1a=292,699572,1
_10_1a_01=4,4,4
_10_1a_0f=264,699544,1
_10_1a_0f_01=84,516392,4
_10_1a_0f_03=60,180240,1
_10_1a_0f_03_116=625,45751,1
_10_1a_0f_03_134=20,2112,4
_10_1a_0f_03_134_134=8,2100,4
_10_1a_0f_03_253f2f8=36,11604,4
_10_1a_0f_03_253f2f9=4,72140,4
_10_1a_0f_03_253f2fd=4,44336,4
_10_1a_0f_03_50e=32,108060,4
_10_1a_0f_08=84,9120,4
_10_1a_0f_08_01=8,248,4
_10_1a_0f_08_07=52,352,4
_10_1a_0f_08_07_01=28,28,4
_10_1a_0f_08_07_03=0,200,4
_10_1a_0f_08_07_03_120=12,128,4
_10_1a_0f_08_07_03_135=48,48,8
_10_1a_0f_08_07_03_135_01=36,36,4
_10_1a_0f_08_07_03_1f=8,8,8
_10_1a_0f_08_07_03_253f2f6=28,28,4
_10_1a_0f_08_07_03_253f2fc=24,24,8
_10_1a_0f_08_07_06=60,112,4
_10_1a_0f_08_07_06_01=4,4,4
_10_1a_0f_08_07_06_02=4,32,4
_10_1a_0f_08_07_06_03=0,16,8
_10_1a_0f_08_07_06_03_110=4,4,4
_16=28,89884,4
_16_01=4,4,4
_16_03=0,0,8
_16_15=148,2164,4
_16_15_01=124,2140,4
_16_15_03=0,0,8
_2b=308,13652,4
_2b_01=4,4,4
_2b_1b=280,13624,8
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



sub check_10_14_01{
my $data=shift;
my $len=length($data);
if($len!=16){return "Chunk size must be 16 bytes!";}
if(substr($data,12,4) ne "\x00\x00\x00\x00"){return "last 4 bytes must be zeroes!";}
}

sub decode_10_14_01{
my $data=shift;
my $level=shift;
my($frame_index,$geometry_index,$flags)=unpack("III",$data);
print "$filename: ".("  " x $level)." \x1b[38;5;155mframe:$frame_index,geometry:$geometry_index,flags:".join(", ",($flags&1?"has_collision":"no_col"),$flags&4?"render in frustum only":"")."\x1b[0m\n";

}

sub encode_10_14_01{
}


sub check_10_1a_0f_08_07_06_02{
my $data=shift;
my $len=length($data);
if($len%4){return "Chunk size must be padded to 4 bytes!";}
if($len>32){return "Chunk size must be usually 32 bytes of less!";}
}

sub decode_10_1a_0f_08_07_06_02{
my $data=shift;
my $level=shift;
$data=~s/\x00.*//s;
print "$filename: ".("  " x $level)." \x1b[38;5;185mString: \"$data\"\x1b[0m\n";
}

sub check_10_0e_03_253f2fe{
my $data=shift;
my $len=length($data);
if($len>23){return "Chunk size too large for R* games";}
}

sub decode_10_0e_03_253f2fe{
my $data=shift;
my $level=shift;
$data=~s/\x00.*//s;
print "$filename: ".("  " x $level)." \x1b[38;5;185mFrame name: \"$data\"\x1b[0m\n";
}

sub decode_10_0e_01{ # Frame List -> Struct
my $data=shift;
my $level=shift;
my $count=unpack("I",substr($data,0,4));
my $q;
print "$filename: ".("  " x $level)." \x1b[38;5;185mElements: $count\x1b[0m\n";
for($q=0;$q<$count;$q++){
($mat_right_x,$mat_right_y,$mat_right_z,$mat_up_x,$mat_up_y,$mat_up_z,$mat_at_x,$mat_at_y,$mat_at_z,$mat_pos_x,$mat_pos_y,$mat_pos_z,$parent_id,$flags)=unpack(
"ffffffffffffiI",substr($data,$q*0x44+4,0x44));
print "$filename: ".("  " x ($level+1))." \x1b[38;5;152m".sprintf("mat right:%2.1fx%2.1fx%2.1f, mat up:%2.1fx%2.1fx%2.1f, mat at:%2.1fx%2.fx%2.1f, position:%2.1fx%2.1fx%2.1f, parent:%d, flags: %08X",
$mat_right_x,$mat_right_y,$mat_right_z,$mat_up_x,$mat_up_y,$mat_up_z,$mat_at_x,$mat_at_y,$mat_at_z,$mat_pos_x,$mat_pos_y,$mat_pos_z,$parent_id,$flags
)."\x1b[0m\n";

}
}

sub decode_10_01{ # Clump -> Struct
my $data=shift;
my $level=shift;
my($count_atom,$count_light,$count_camera)=unpack("III",substr($data,0,12));
print "$filename: ".("  " x $level)." \x1b[38;5;185mAtomics:$count_atom, Lights:$count_light, Cameras:$count_camera\x1b[0m\n";
if($count_light!=0 || $count_camera!=0){
die "In GTA SA games this sections is invalid, no lights and cameras allowed in GTA";
}
}

sub decode_10_1a_01{ # Geometry list -> struct
my $data=shift;
my $level=shift;
my($count_geometries)=unpack("I",substr($data,0,4));
print "$filename: ".("  " x $level)." \x1b[38;5;185mGeometries count:$count_geometries\x1b[0m\n";
}

sub decode_10_1a_0f_08_07_01{ # Material -> struct
my $data=shift;
my $level=shift;
my($flags,$color,$unused,$is_textured,$ambient,$specular,$diffuse)=unpack("IIIIfff",$data);
print "$filename: ".("  " x ($level))." \x1b[38;5;152m".sprintf("Color:0x%08X, diffuse:%f, ambient:%f, specular:%f, is_textured:%d, flags:0x%08X, unused:0x%08X",
$color,$diffuse,$ambient,$specular,$is_textured,$flags,$unused
)."\x1b[0m\n";
}

sub decode_10_1a_0f_03_253f2f9{ # Extra Vert Colour
my $data=shift;
my $level=shift;
my($magic)=unpack("I",$data);
my $colors_count=length($data)/4-1;
print "$filename: ".("  " x ($level))." \x1b[38;5;152m".sprintf("Magic number:0x%08X (%s), colors count: %d",
$magic,$magic==0x1A9D5F80?"using colors":"unknown",$colors_count
)."\x1b[0m\n";
}


sub decode_10_1a_0f_03_50e{ # 10[Clump]-1A[Geometry List]-0F[Geometry]-03[Extension]-50E[Bin Mesh PLG]
my $data=shift;
my $level=shift;
my($flags,$count_mesh,$count_inds)=unpack("III",substr($data,0,12));
my $is_strip=$flags&1;
my $q;
my $m;
my $pos=12;
my($min,$max);
my $ind;
print "$filename: ".("  " x ($level))." \x1b[38;5;152m".sprintf("Count of meshes:%d, mesh packing strip:%d, total indices:%d, flags:0x%08X",
$count_mesh,$is_strip,$count_inds,$flags
)."\x1b[0m\n";
for($m=0;$m<$count_mesh;$m++){
my($count_inds_mesh,$material_ind)=unpack("II",substr($data,$pos,8));
$pos+=8;
print "$filename: ".("  " x ($level+1))." \x1b[38;35;29m".sprintf("Mesh %d, indices:%d, material index:%d",
$m,$count_inds_mesh,$material_ind
)."\x1b[0m\n";
for($q=0;$q<$count_inds;$q++){
$ind=unpack("I",substr($data,$pos,4));
if($q==0){
$min=$max=$ind;
} else {
if($min>$ind){$min=$ind;}
if($max<$ind){$max=$ind;}
}


#print "$filename: ".("  " x ($level+2))." \x1b[38;32;54m".sprintf("Entry:%d, offset:%d, ind:%d",
#$q,$pos,$ind
#)."\x1b[0m\n";
if($pos>=length($data)){
print "$filename: ".("  " x ($level+2))." \x1b[38;41;27m".sprintf("Out of bounds!"
)."\x1b[0m\n";
}
$pos+=4;
}
print "$filename: ".("  " x ($level+1))." \x1b[38;32;54m".sprintf("Values usage: min:%d, max:%d",
$min,$max
)."\x1b[0m\n";



}
}






sub decode_10_1a_0f_08_07_06_01{ # Material -> Texture -> struct
my $data=shift;
my $level=shift;

my @filter_text=split(/\n/,<<DATA);
0 - FILTERNAFILTERMODE (filtering is disabled)
1 - FILTERNEAREST (Point sampled)
2 - FILTERLINEAR (Bilinear)
3 - FILTERMIPNEAREST (Point sampled per pixel mip map)
4 - FILTERMIPLINEAR (Bilinear per pixel mipmap)
5 - FILTERLINEARMIPNEAREST (MipMap interp point sampled)
6 - FILTERLINEARMIPLINEAR (Trilinear)
DATA

my @addr_text=split(/\n/,<<DATA);
0 - TEXTUREADDRESSNATEXTUREADDRESS (no tiling)
1 - TEXTUREADDRESSWRAP (tile)
2 - TEXTUREADDRESSMIRROR (mirror)
3 - TEXTUREADDRESSCLAMP
4 - TEXTUREADDRESSBORDER
DATA

my($filter_mode,$addr_modes,$mipmaps)=unpack("CCS",$data);
print "$filename: ".("  " x ($level))." \x1b[38;5;152m".sprintf("Texture filter mode: %s",
$filter_text[$filter_mode]
)."\x1b[0m\n";
print "$filename: ".("  " x ($level))." \x1b[38;5;152m".sprintf("U-addr mode: %s, V-addr mode: %s",
$addr_text[$addr_modes>>4],$addr_text[$addr_modes&0xF]
)."\x1b[0m\n";
print "$filename: ".("  " x ($level))." \x1b[38;5;152m".sprintf("Using mipmap levels: %d",
$mipmaps
)."\x1b[0m\n";
}




sub decode_10_1a_0f_03_253f2f8{ # 2dfx
my $data=shift;
my $level=shift;
my $effects_count=unpack("I",substr($data,0,4));
my $q;
my $w;
print "$filename: ".("  " x $level)." \x1b[38;5;155mEffects count: $effects_count\x1b[0m\n";
my $pos=4;
my @types=qw/Light Particle Unknown PedAttractor SunGlare Unknown ENEX Sign Trigger CoverPoint Escalator/;
my @chars_in_line=qw/16 2 4 8/;
my @colors=qw/white black gray red/;
my @texts=();
for($q=0;$q<$effects_count;$q++){
my($pos_x,$pos_y,$pos_z,$type,$size)=unpack("fffII",substr($data,$pos,20));
print "$filename: ".("  " x ($level+1))." \x1b[38;5;155m".sprintf("Position: %03fx%03fx%03f, type:%d (%s), size: 0x%04x/%d bytes",$pos_x,$pos_y,$pos_z,$type,$types[$type],$size,$size)."\x1b[0m\n";

if($type==0){ # Light

if($size==76){ # Light 76 bytes


}

if($size==80){ # Light 80 bytes
my($color,$far_clip,$near_clip,$corona_size,$shadow_size,$corona_mode,$corona_reflection,$corona_flare,$shadow_mult,$flags1,$corona_texture_name,$shadow_texture_name,$shadow_z_distance,$flags2,$look_x,$look_y,$look_z,$padding)=unpack(
"IffffCCCCCZ24Z24CCcccS",substr($data,$pos+20,80));
print "$filename: ".("  " x ($level+2))." \x1b[38;5;152m".sprintf("Color:%06x, size:%03.2f, shadow size:%03.2f, mode:%d, refl:%d, flare:%d, shadow_mult:%d, flags1:%d, textures:\"%s\"/\"%s\", z_dist:%f, look:%dx%dx%dx)",
$color,$corona_size,$shadow_size,$corona_mode,$corona_reflection,$corona_flare,$shadow_mult,$flags1,$corona_texture_name,$shadow_texture_name,$shadow_z_distance,$look_x,$look_y,$look_z
)."\x1b[0m\n";
}


}

if($type==7){# street sign
my($size_x,$size_y,$rot_x,$rot_y,$rot_z,$flags)=unpack("fffffS",substr($data,$pos+20,22));
my $text_x=$chars_in_line[($flags>>2)&3];
my $text_y=$flags&3;
print "$filename: ".("  " x ($level+2))." \x1b[38;5;156m".sprintf("Size:%03fx%03f, chars:%dx%d (%s), rotation:%01.1fx%01.1fx%01.1f, flags:%d (0x%08x)",$size_x,$size_y,$text_x,$text_y,$colors[($flags>>4)&3],$rot_x,$rot_y,$rot_z,$flags,$flags)."\x1b[0m\n";
for($w=0;$w<$text_y;$w++){
print "$filename: ".("  " x ($level+3))." \x1b[38;5;152mStreet sign text: \"".substr($data,$pos+42+$w*16,$text_x)."\"\x1b[0m\n";
}
}

$pos+=$size+20;
}

die;
}





