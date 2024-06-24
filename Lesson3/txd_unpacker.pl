


($src_file,$dst_dir)=@ARGV;

if(!$src_file || !$dst_dir){
die "Usage: txd_unpacker.pl [source.txd] [output_dir/]";
}

mkdir $dst_dir,0777;

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
($version,$fflags,$tex_name,$alpha_name,$alflags,$texformat,$width,$height,$depth,$mipmap_count,
$texcode_type,$flags)=unpack("IIA32A32IISSCCCC",$buf);
print "Found texture \"$tex_name\" (alpha \"$alpha_name\"), size $width x $height, $mipmap_count mipmap\n";
if($depth==8){
read(dd,$palette,256*4);
}
for($mm=0;$mm<$mipmap_count;$mm++){
print "Reading mipmap $mm...\n";
read(dd,$buf,4);
$data_size=unpack("I",$buf);
read(dd,$data,$data_size);

open(oo,">".$dst_dir."/".$tex_name."_mipmap".$mm.".dds");
binmode(oo);
print oo "DDS ".pack(
"IIIIIIIa44",
0x7c, #heade size,
0x0A1007, #flags
$width,
$height,
0x200, #stride
$depth,
$mipmap_count*0,
0 # 11 uints
);

# start of pixel format
print oo pack(
"IIA4IIIII",
0x20, # size
0x04, # flags
"DXT1", #fourCC
0,0,0,0,0 # RGB bit count and masks
);

print oo pack("IIIII",0x401008,0,0,0,0);


print oo $data;
close(oo);

$width>>=1;
$height>>=1;

}
printf("We at %x\n",tell(dd));

read(dd,$buf,12);
($type,$len,$build)=unpack("III",$buf);
if($type!=0x3 || $len!=0){# txd_extra_info_s
die "This is not TXD file or root node is broken!";
}

}






