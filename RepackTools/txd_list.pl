


($src_file)=@ARGV;

if(!$src_file){
die "Usage: txd_list.pl [source.txd]";
}

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

read(dd,$buf,88);
($version,$fflags,$tex_name,$alpha_name,$alflags,
$texformat,$width,$height,$depth,$mipmap_count,
$texcode_type,$flags)=unpack("IIA32A32Ia4SSCCCC",$buf);
print "$src_file/$tex_name\n";
if($depth==8){
read(dd,$palette,256*4);
}
for($mm=0;$mm<$mipmap_count;$mm++){
read(dd,$buf,4);
$data_size=unpack("I",$buf);
read(dd,$data,$data_size);

}

read(dd,$buf,12);
($type,$len,$build)=unpack("III",$buf);
if($type!=0x3 || $len!=0){# txd_extra_info_s
die "This is not TXD file or root node is broken!";
}

}







