


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
($version,$fflags,$tex_name,$alpha_name,
$rasterFormatId,
$rasterCodecId,
$width,$height,$depth,$mipmap_count,
$rasterType,$flags)=unpack("IIZ32Z32Ia4SSCCCC",$buf);
=pod
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

Depth
4, 8, 16 or 32; 4 and 8 usually come with palette

Flags:
unsigned char alpha : 1;
unsigned char cubeTexture : 1;
unsigned char autoMipMaps : 1;
unsigned char compressed : 1; // if true, raster may not be defined in original RW (compressed?)
=cut

$isCompressed=($flags&8?1:0);
$isAlpha=($flags&1?1:0);



if(!$isAlpha){
$alpha_name="[no alpha]";
}
if($version!=9){
die "$src_file: We supports only GTASA PC version, but here $version!";
}

if(!$isCompressed){
$rasterCodecNum=unpack("I",$rasterCodecId);
}

if(!$isCompressed && !($rasterCodecNum==0x15 || $rasterCodecNum==0x16)){
die "$src_file: Only 0x15, but have ".sprintf("%x",$rasterCodecNum)."($rasterCodecNum) type supported D3DFMT_A8R8G8B8=21, see https://learn.microsoft.com/ru-ru/windows/win32/direct3d9/d3dformat";
}

print "Found texture ${width}x${height}\@$depth \"$tex_name\" (alpha \"$alpha_name\"), codec:$rasterCodecId, $mipmap_count mipmap, format:$rasterFormatId, type:$rasterType, flags:$flags\n";
if($depth==8 || $depth==4){
$paletteSize=0;
if($rasterFormatId&0x2000){
$paletteSize=256;
}
if($rasterFormatId&0x4000){
$paletteSize=16;
}

read(dd,$palette,$paletteSize*4);
print "Skipped $paletteSize colors\n";
}

for($mm=0;$mm<$mipmap_count;$mm++){
read(dd,$buf,4);
$data_size=unpack("I",$buf);
read(dd,$data,$data_size);

$img_name=$tex_name;
$img_name=~s/[^a-z0-9\-\.]/_/gsi;

$dds_name=$dst_dir."/dds/".$img_name."_mipmap".$mm.".dds";
$png_name=$dst_dir."/png/".$img_name.".png";

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

$pixelFormatFlags=0;
if($isCompressed){
$pixelFormatFlags|=0x4;
} else {
$pixelFormatFlags|=0x40;
}

if($depth==32 && $isAlpha){
$pixelFormatFlags|=0x1|0x2; # used alpha in uncompressed images
}


# start of pixel format
print oo pack(
"IIA4IIIII",
0x20, # size
$pixelFormatFlags, # flags
$rasterCodecId, #fourCC
$depth, # RGB bit count
0xFF,0xFF0000,0xFF000000,0xFF000000 # RGB masks for R G B A
);

print oo pack("IIIII",0x401008,0,0,0,0);


print oo $data;
close(oo);

if($mm==0){
#`convert "$dds_name" "$png_name"`;
#`convert "$dds_name" -resize 128x128\\\> "$png_name"`;
`convert "$dds_name" -resize 16384\\\@\\\> -colorspace rgb "$png_name"`;
}

unlink($dds_name);

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






