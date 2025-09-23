($src_file,$dst_file,$memes_file)=@ARGV;

if(!$src_file || !$dst_file){
die "Usage: txd_randomizer.pl [source.txd] [output.txd] [memes.txt]";
}


open(dd,$memes_file);
@memes=<dd>;
chomp(@memes);
close(dd);

srand(time()+int(rand()*10000));

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
$images_count2=$images_count;

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


$no_resize=0;
if($tex_name=~/carplate|carpback|plateback1|plateback2|plateback3|font/i){
$no_resize=1;
}


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


if(!$isCompressed && $version==9 && !($d3dFormatAlphaNum==0x15 || $d3dFormatAlphaNum==0x16)){
die "$src_file: Only 0x15, but have ".sprintf("%x",$d3dFormatAlphaNum)."($d3dFormatAlpha) type supported D3DFMT_A8R8G8B8=21, see https://learn.microsoft.com/ru-ru/windows/win32/direct3d9/d3dformat";
}

if($no_resize){
print "Copy $tex_name, no resize!\n";
read(dd,$resized_data,$len-88);

$resized_data=$buf.$resized_data;
$resized_data=pack("III",1,length($resized_data),0x1803FFFF).$resized_data;
$resized_data.=pack("III",3,0,0x1803FFFF);
$resized_data=pack("III",0x15,length($resized_data),0x1803FFFF).$resized_data;
push(@to_out,$resized_data);

} else {

if($paletteSize){
read(dd,$palette,$paletteSize);
die "Palette!!!";
print "Skipped $paletteSize colors\n";
}


print "$src_file: Found texture ${width}x${height}\@$depth \"$tex_name\", codec:$d3dFormatAlphaNum/$d3dFormatAlpha, $mipmap_count mipmap, format:$rasterFormatId, type:$rasterType, flags:$flags\n";


for($mm=0;$mm<$mipmap_count;$mm++){
read(dd,$buf,4);
$data_size=unpack("I",$buf);
read(dd,$data,$data_size);

if($mm==0){

$dds_name="tmp-src".rand().".dds";
$resized_name="tmp-dst".rand().".dds";
$png_name="tmp-dst".rand().".png";
$raw_name="tmp-dst".rand().".bin";

unlink($dds_name); # if any
unlink($resized_name); # if any
unlink($png_name); # if any
unlink($raw_name); # if any


# reconstruct DDS image file
while(1){
$new_image=$memes[int(rand()*@memes)];

# convert image

$alpha_on="-alpha off ";
if($isAlpha){
$alpha_on="-alpha on ";
}

if($isCompressed){
$new_codec=$isAlpha?"dxt5":"DXT1";

$newheader=pack("IIZ32Z32IA4SSCCCC",
9, # version
0x1101, # flags
$tex_name,"",
$isAlpha?0x0300:0x200, # rasterFormatId
$isAlpha?"DXT5":"DXT1", # rasterCodecId (directX 0x16=XRGB, 0x15 for ARGB)
$width,$height,16,1, # $width,$height,$depth,$mipmap_count
4, # rasterType = ????
$isAlpha| 0x8  #we have alpha  + compressed
);

`convert "$new_image"[0] $alpha_on $conv_options -resize  ${width}x${height}^ -gravity center -crop ${width}x${height}+0+0 -define dds:mipmaps=0 -define dds:compression=$codec "$resized_name"`;

} else {

$newheader=pack("IIZ32Z32IISSCCCC",
9, # version
0x1101, # flags
$tex_name,"",
$isAlpha?0x0500:0x600, # rasterFormatId
$isAlpha?0x15:0x16, # rasterCodecId (directX 0x16=XRGB, 0x15 for ARGB)
$width,$height,32,1, # $width,$height,$depth,$mipmap_count
4, # rasterType = ????
$isAlpha
);

`convert "$new_image"[0] $alpha_on $conv_options -resize ${width}x${height}^ -gravity center -crop ${width}x${height}+0+0  bgra:"$raw_name"`;

}

$processed_file=-s($resized_name)?$resized_name:$raw_name;

if(-s($processed_file)){
last;
#die "Can't resize image!!! Imagemagick not created file!";
}

}

open(rr,$processed_file) or die "$resized_name: $!";
binmode(rr);
read(rr,$processed_data,-s(rr));
close(rr);

$codec_name=substr($processed_data,0x54,4);
if($isCompressed && $codec_name ne "DXT1" && $codec_name ne "DXT5"){
die "Resized codec must be DXT1/DXT5, but we have $codec_name!";
}

if($isAlpha && $isCompressed && $codec_name ne "DXT5"){
die "Image with alpha channel must be in DXT5, we have $codec_name";
}

if((!$isAlpha) && $isCompressed && $codec_name ne "DXT1"){
die "Image with no alpha channel must be in DXT1, we have $codec_name";
}


if($isCompressed){
$resized_data=substr($processed_data,0x80);
print "Resized to codec $codec_name, got ".length($resized_data)."\n";
} else {
$resized_data=$processed_data;
}


$resized_data=$newheader.pack("I",length($resized_data)).$resized_data;
$resized_data=pack("III",1,length($resized_data),0x1803FFFF).$resized_data;
$resized_data.=pack("III",3,0,0x1803FFFF);
$resized_data=pack("III",0x15,length($resized_data),0x1803FFFF).$resized_data;
push(@to_out,$resized_data);

unlink($dds_name);
unlink($resized_name);
unlink($png_name);
unlink($raw_name);


}

#die;
$width>>=1;
$height>>=1;

}
#printf("We at %x\n",tell(dd));
}


read(dd,$buf,12);
($type,$len,$build)=unpack("III",$buf);
if($type!=0x3 || $len!=0){# txd_extra_info_s
die "$src_file: This is not TXD file or root node is broken!";
}

}


$resized_data=join("",@to_out);
$struct=pack("III",1,4,0x1803FFFF).pack("SS",$images_count2,2).$resized_data.pack("III",3,0,0x1803FFFF);
$resized_data=pack("III",0x16,length($struct),0x1803FFFF).$struct;

open(oo,">".$dst_file);
binmode(oo);
print oo $resized_data;


