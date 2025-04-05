use File::Find;
use Data::Dumper;
use File::Path qw(make_path remove_tree);
use File::Basename;
use Digest::CRC qw(crc64 crc32 crc16);
use Digest::MD5 "md5_hex";



($src_file)=@ARGV;

if(!$src_file){
die "Usage: txd_list.pl [source.txd]";
}

open(dd,$src_file) or die $!;
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

if($images_count<1 || ($platform_id!=1 && $platform_id!=2)){ 
die "This is not TXD file or root node is broken!";
}


while($images_count--){

read(dd,$buf,12);
($type,$len,$build)=unpack("III",$buf);
if($type!=0x15){# txd_texture_s
die "This is not TXD file or root node is broken!";
}


read(dd,$buf,12);
($type,$len,$build)=unpack("III",$buf);
if($type!=0x1 || $len<0x10){# txd_texture_data_s
die "This is not TXD file or root node is broken!";
}

$data="";
read(dd,$buf,88);
######$data.=$buf;
($version,$fflags,$tex_name,$alpha_name,$alflags,
$texformat,$width,$height,$depth,$mipmap_count,
$texcode_type,$flags)=unpack("IIA32A32Ia4SSCCCC",$buf);
if($depth==8){
read(dd,$palette,256*4);
$data.=$palette;
}
for($mm=0;$mm<$mipmap_count;$mm++){
read(dd,$buf,4);
$data.=$buf;
$data_size=unpack("I",$buf);
read(dd,$buf,$data_size);
$data.=$buf;

}

$sum=md5_hex($data);
print "$src_file/$tex_name".(" " x (25-length($tex_name)))." (${width}x${height}\@${depth},\t$texformat,\tsum:$sum)\n";


read(dd,$buf,12);
($type,$len,$build)=unpack("III",$buf);
if($type!=0x3 || $len!=0){# txd_extra_info_s
die "We not expect extra info after image bitmaps!";
}

}







