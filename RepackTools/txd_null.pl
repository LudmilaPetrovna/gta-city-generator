use File::Slurp;

%bitmaps=();
$src_file=shift(@ARGV);

$dummy_file="dummy_texture.png";
$dummy_texture="dummy_texture.txd";

if(!-s($dummy_file)){
`echo -n "0101101001011010" | ffmpeg -f rawvideo -pix_fmt gray -s 4x4 -i - -vf normalize -y $dummy_file`;
`perl /dev/shm/gta-city-generator/RepackTools/png2txd.pl $dummy_texture $dummy_file`;
}

$dummy_file=read_file($dummy_texture);
$dummy_file=substr($dummy_file,0x1c,0x7c);

if($src_file!~/\.txd/){
die "Usage: txd_null.pl [nulled.txd] (file will be overwritten!)";
}


# read bitmap names
open(dd,$src_file) or die $!;
read(dd,$header,28);
($sign_16,$wholesize,$build1,$sign_01,$size_04,$build2,$count,$platform_id)=unpack("IIIIIISS",$header);
$filesize=-s(dd);

if($sign_16!=0x16 || $sign_01!=0x01 || $size_04!=0x04 || $build1!=$build2 || $wholesize>$filesize){
die "$src_file: Something wrong in header of your TXD file!";
}

for($q=0;$q<$count;$q++){


if(read(dd,$buf,12)==0){last;}
($type,$size,$build)=unpack("III",$buf);
if($type==0x15){
read(dd,$buf2,$size);
$name=substr($buf2,20,32);
$name=~s/\0.*//s;
$name=lc($name);
$bitmaps{$name}=1;
}

if($type==0x3){

}


}

close(dd);
# write file

@names=sort keys %bitmaps;
$new_count=@names;

# calc whole file size
$sum=0;
foreach(@names){
$sum+=length($dummy_file);
}

open(oo,">".$src_file);
print oo pack("IIIIIISS",0x16,$sum+28,$build1,0x01,0x04,$build1,$new_count,$platform_id);

foreach(@names){
substr($dummy_file,32,32)=pack("Z32",$_);
print oo $dummy_file;
}
print oo pack("III",3,0,$build1);



