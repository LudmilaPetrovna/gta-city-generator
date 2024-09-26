

$dummy_width=1;
$dummy_height=1;
$dummy_depth=32;

$bitmap_size=$dummy_width*$dummy_height*$dummy_depth/8;
$frame_size=88+$bitmap_size+4;

($src_file,$dst_file)=@ARGV;

if(!$src_file || !$dst_file){
die "Usage: txd_emptyer.pl [source.txd] [output.txd]";
}

open(dd,$src_file);
binmode(dd);
open(oo,">".$dst_file);
binmode(oo);

read(dd,$buf,12);
print oo $buf;
($type,$len,$build)=unpack("III",$buf);

if($type!=0x16){ #txd_file_s
die "This is not TXD file or root node is broken!";
}

read(dd,$buf,12);
print oo $buf;
($type,$len,$build)=unpack("III",$buf);
if($type==1 && $len==4){ # txd_info_s
read(dd,$buf,$len);
print oo $buf;
($images_count,$platform_id)=unpack("SS",$buf);
}

$len_in_header=$images_count*($frame_size+36)+28;
printf("Len in header: %x (%d)\n",$len_in_header,$len_in_header);

while($images_count--){

read(dd,$buf,12);
print oo pack("III",0x15,$frame_size+24,402915327);
($type,$len,$build)=unpack("III",$buf);
if($type!=0x15){# txd_texture_s
die "$src_file: This is not TXD file or root node is broken!";
}


read(dd,$buf,12);
print oo pack("III",0x1,$frame_size,402915327);
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

print oo pack("IIZ32Z32IISSCCCC",
9, # version
0x1101, # flags
$tex_name,"",
0x0500, # rasterFormatId
0x15, # rasterCodecId (directX 0x16=XRGB, 0x15 for ARGB)
$dummy_width,$dummy_height,$dummy_depth,1, # $width,$height,$depth,$mipmap_count
4, # rasterType = ????
1 #we have alpha
);

print "$tex_name\n";

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

#skip images
for($mm=0;$mm<$mipmap_count;$mm++){
read(dd,$buf,4);
$image_len=unpack("I",$buf);
read(dd,$buf,$image_len);
#print "we have image 88 + 4 + $image_len bytes\n";
}

# write mipmap
$color_r=int(rand()*256);
$color_g=int(rand()*256);
$color_b=int(rand()*256);
$color=pack("CCCC",$color_r,$color_g,$color_b,0xFF);

print oo pack("I",$dummy_width*$dummy_height*$dummy_depth/8);
print oo $color x ($dummy_width*$dummy_height);

# write extension per bitmap
read(dd,$buf,12);
print oo $buf;
($type,$len,$build)=unpack("III",$buf);
if($type!=0x3 || $len!=0){# txd_extra_info_s
die "$src_file: This is not TXD file or root node is broken!";
}

}

print oo pack("III",3,0,0x1803FFFF);

seek(oo,4,0);
print oo pack("I",$len_in_header);




