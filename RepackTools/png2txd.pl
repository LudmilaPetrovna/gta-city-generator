use File::Path qw(make_path remove_tree);
use File::Basename;

$max_size=256;


$dst_file=shift(@ARGV);
@src_files=@ARGV;

if(!$dst_file || @src_files==0 || $dst_file!~/\.txd$/i){
die "Usage: png2txd.pl [output.txd] [source1.png] [source2.png] [source...]";
}

$build_id=0x1803FFFF; # GTA:SA
$device_id=2; # GTA:SA PC version for D3D9 (1 for D3D8), https://gtamods.com/wiki/Texture_Dictionary_(RW_Section)
$platform_id=9; # 9 for GTA SA on the PC, https://gtamods.com/wiki/Raster_(RW_Section)


%images=();
# step 1: read all images in global hash

foreach $png_file(@src_files){

$texture_name=lc(basename($png_file));
#$texture_name=lc(basename($dst_file));


$texture_name=~s/\.(png|jpe?g|bmp|txd)//s;


$png_size=-s($png_file);
if($png_size<30){
die "$png_file: source file too small!";
}

$temp_file="tmp-".time()."-".rand().".dds";

unlink($temp_file);
#-resize "${max_size}x${max_size}\!"
`convert "$png_file" -define dds:mipmaps=0 -flip -define dds:compression=TXD5 "$temp_file"`;
if(!-s($temp_file)){
die "Conversion $png_file to DDS failed!";
}

open(rr,$temp_file) or die "$temp_file: $!";
binmode(rr);
read(rr,$dds_data,-s(rr));
close(rr);
unlink($temp_file);

$codec_name=substr($dds_data,0x54,4);
if($codec_name ne "DXT1" && $codec_name ne "DXT5"){
die "Resized codec must be DXT1/DXT5, but we have $codec_name!";
}

($height,$width,$stride,$depth)=unpack("IIII",substr($dds_data,12,16));
$compressed_data=substr($dds_data,0x80);
if(!$depth){$depth=16;}

if($codec_name eq "DXT1"){
$isAlpha=0;
$format_id=0x100;
} else {
$isAlpha=1;
$format_id=0x300;
}


$newheader=pack("IIZ32Z32IA4SSCCCC",
$platform_id, # version
0x1101, # flags FILTER_NEAREST + WRAP_WRAP|WRAP_WRAP
$texture_name,"",
$format_id,  # rasterFormatId
$codec_name, # rasterCodecId (directX 0x16=XRGB, 0x15 for ARGB)
$width,$height,$depth,1, # $width,$height,$depth,$mipmap_count
4, # rasterType = ????
$isAlpha|8 # is compressed
);

$img_data=$newheader.pack("I",length($compressed_data)).$compressed_data;
$img_data=pack("III",1,length($img_data),$build_id).$img_data.pack("III",3,0,$build_id);
$img_data=pack("III",0x15,length($img_data),$build_id).$img_data;

$images{$texture_name}=$img_data;
print STDERR "Prepared image \"$texture_name\" (${width}x${height}\@${depth}, codec:$codec_name)\n";

}


# step 2: write txd
@names=sort keys %images;
$new_count=@names;

# calc whole file size
$sum=0;
foreach(@names){
$sum+=length($images{$_});
}

make_path(dirname($dst_file));
open(oo,">".$dst_file) or die "Can't write \"$dst_file\": $!";
binmode(oo);
print oo pack("IIIIIISS",0x16,$sum+28,$build_id,0x01,0x04,$build_id,$new_count,$device_id);

foreach(@names){
print oo $images{$_};
}
print oo pack("III",3,0,$build_id);
close(oo);



