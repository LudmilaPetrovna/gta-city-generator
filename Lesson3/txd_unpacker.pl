


($src_file,$dst_dir)=@ARGV;

if(!$src_file || !$dst_dir){
die "Usage: txd_unpacker.pl [source.txd] [output_dir/]";
}

mkdir $dst_dir,0777;
mkdir $dst_dir."/dds",0777;
mkdir $dst_dir."/png",0777;

open(dd,$src_file);
binmode(dd);

read(dd,$buf,12);
($type,$len,$build)=unpack("III",$buf);

if($type!=0x16){ #txd_file_s
die "This is not TXD file or root node is broken!";
}

read(dd,$buf,12);
($type,$len,$build)=unpack("III",$buf);
if($type==1 && $len==4){ # txd_info_s
read(dd,$buf,$len);
($images_count,$platform_id)=unpack("SS",$buf);
}

if($images_count<1){ 
if(-s($src_file)==2048){exit;}
if(-s($src_file)==40){exit;}
die "$src_file: empty file?";
}

if($images_count<1){ 
die "$src_file: wrong platform?";
}

while($images_count--){

read(dd,$buf,12);
($type,$len,$build)=unpack("III",$buf);
if($type!=0x15){# txd_texture_s
die "$src_file: This is not TXD file or root node is broken!";
}


read(dd,$buf,12);
($type,$len,$build)=unpack("III",$buf);
if($type!=0x1 || $len<0x10){# txd_texture_data_s
die "$src_file: This is not TXD file or root node is broken!";
}

read(dd,$buf,88);
($version,
$filter_mode,$wrap_mode,$zero_padding,
$tex_name,$alpha_name,
$rasterFormatId,
$d3dFormatAlpha, # or alpha for GTA3/VC
$width,$height,$depth,$mipmap_count,
$rasterType,$flags)=unpack("ICCSZ32Z32Ia4SSCCCC",$buf);
=pod
Depth
4, 8, 16 or 32; 4 and 8 usually come with palette

Flags:
unsigned char alpha : 1;
unsigned char cubeTexture : 1;
unsigned char autoMipMaps : 1;
unsigned char compressed : 1; // if true, raster may not be defined in original RW (compressed?)

Raster Format
FORMAT_DEFAULT         0x0000
FORMAT_1555            0x0100 (1 bit alpha, RGB 5 bits each; also used for DXT1 with alpha)
FORMAT_565             0x0200 (5 bits red, 6 bits green, 5 bits blue; also used for DXT1 without alpha)
FORMAT_4444            0x0300 (RGBA 4 bits each; also used for DXT3)
FORMAT_LUM8            0x0400 (gray scale, D3DFMT_L8)
FORMAT_8888            0x0500 (RGBA 8 bits each)
FORMAT_888             0x0600 (RGB 8 bits each, D3DFMT_X8R8G8B8)
FORMAT_555             0x0A00 (RGB 5 bits each - rare, use 565 instead, D3DFMT_X1R5G5B5)

FORMAT_EXT_AUTO_MIPMAP 0x1000 (RW generates mipmaps, see special section below)
FORMAT_EXT_PAL8        0x2000 (2^8 = 256 palette colors)
FORMAT_EXT_PAL4        0x4000 (2^4 = 16 palette colors)
FORMAT_EXT_MIPMAP      0x8000 (mipmaps included)
=cut


$d3dFormatAlphaNum=unpack("I",$d3dFormatAlpha);

if($rasterFormatId&0x2000){
$paletteColors=256; # 256 colors
$paletteBits=8;
}
if($rasterFormatId&0x4000){
$paletteSize=16;  # 16 colors
$paletteBits=4;
}

$paletteSize=$paletteColors*4;


$format_bits=-1;
$format_alpha=0;
if($rasterFormatId==0x100){
$format_bits=16;
$format_alpha=1;
$format_codec="DXT1";
}

if($rasterFormatId==0x200){
$format_bits=16;
$format_alpha=0;
$format_codec="DXT1";
}

if($rasterFormatId==0x300){
$format_bits=16;
$format_alpha=0;
$format_codec="DXT3";
}

if($rasterFormatId==0x400){
$format_bits=8;
$format_alpha=0;
$format_codec="";
}

if($rasterFormatId==0x500){
$format_bits=32;
$format_alpha=1;
$format_codec="";
}

if($rasterFormatId==0x600){
$format_bits=32;
$format_alpha=0;
$format_codec="";
}

if($rasterFormatId==0xA00){
$format_bits=16;
$format_alpha=0;
$format_codec="";
}


if($version!=9 && $version!=8){
die "$src_file: We supports only GTASA PC/GTAVC PC version, but here $version!";
}

if($version==8){ # GTA III / VC
$isCompressed=$flags;
$isAlpha=$d3dFormatAlphaNum;
} else { # GTA SA
$isCompressed=($flags&8?1:0);
$isAlpha=($flags&1?1:0);
}

if(!$isAlpha){
$alpha_name="[no alpha]";
}

if(!$isCompressed && !($d3dFormatAlphaNum==0x15 || $d3dFormatAlphaNum==0x16)){
die "$src_file: Only 0x15, but have ".sprintf("%x",$d3dFormatAlphaNum)."($d3dFormatAlpha) type supported D3DFMT_A8R8G8B8=21, see https://learn.microsoft.com/ru-ru/windows/win32/direct3d9/d3dformat";
}


if($paletteSize){
read(dd,$palette,$paletteSize);
die "Palette!!!";
print "Skipped $paletteSize colors\n";
}


$pixelFormatFlags=0;
if($isCompressed){
$pixelFormatFlags|=0x4;
} else {
$pixelFormatFlags|=0x40;
}

if($depth==32 && $isAlpha){
$pixelFormatFlags|=0x1|0x2; # used alpha in uncompressed images
}

if($version==8 && $format_codec){
$d3dFormatAlpha=$format_codec;
}

print "Found texture ${width}x${height}\@$depth \"$tex_name\", codec:$d3dFormatAlphaNum/$d3dFormatAlpha, $mipmap_count mipmap, format:$rasterFormatId, type:$rasterType, flags:$flags\n";


for($mm=0;$mm<$mipmap_count;$mm++){
read(dd,$buf,4);
$data_size=unpack("I",$buf);
read(dd,$data,$data_size);

$img_name=$tex_name;
$img_name=~s/[^a-z0-9\-\.]/_/gsi;

$dds_name=$dst_dir."/dds/".$img_name."_mipmap".$mm.".dds";
$png_name=$dst_dir."/png/".$img_name.".png";
$ffpng_name=$dst_dir."/png/".$img_name."-ffmpeg.png";
$iopng_name=$dst_dir."/png/".$img_name."-io.png";

open(oo,">".$dds_name);
binmode(oo);
print oo "DDS ".pack(
"IIIIIIIa44",
0x7c, #heade size,
0x0A1007, #flags
$height,
$width,
$width*$depth/8, #stride for uncompressed textures
$depth,
$mipmap_count*0+1,
0 # 11 uints
);

# start of pixel format
print oo pack(
"IIA4IIIII",
0x20, # size
$pixelFormatFlags, # flags
$d3dFormatAlpha, #fourCC
$depth, # RGB bit count
0xFF,0xFF0000,0xFF000000,0xFF000000 # RGB masks for R G B A
);

print oo pack("IIIII",0x401008,0,0,0,0);


print oo $data;
close(oo);

if($mm==0){
#`convert "$dds_name" "$png_name"`;
#`convert "$dds_name" -resize 128x128\\\> "$png_name"`;
`convert "$dds_name" -resize 16384\\\@\\\> -colorspace srgb "$png_name"`;
`ffmpeg -v 0 -i "$dds_name" -y "$ffpng_name"`;
#`oiiotool "$dds_name" -o "$iopng_name"`; # actually same as imagemagick, but very slow
}

#unlink($dds_name);

#die;
$width>>=1;
$height>>=1;

}
#printf("We at %x\n",tell(dd));

read(dd,$buf,12);
($type,$len,$build)=unpack("III",$buf);
if($type!=0x3 || $len!=0){# txd_extra_info_s
die "$src_file: This is not TXD file or root node is broken!";
}

}






