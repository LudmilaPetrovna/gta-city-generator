

%bitmaps=();

$dst_file=shift(@ARGV);

if($dst_file!~/\.txd/){
die "Usage: [joined_result.txd] [src1.txd] [src1.txd] [src....txd]";
}

foreach $src_file(@ARGV){

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
substr($buf2,20,32)=pack("Z32",$name);
#print "$q: $name\n";
$bitmaps{$name}=$buf.$buf2
}

if($type==0x3){

}


}
}

# write file

@names=sort keys %bitmaps;
$new_count=@names;

# calc whole file size
$sum=0;
foreach(@names){
$sum+=length($bitmaps{$_});
}

open(oo,">".$dst_file);
print oo pack("IIIIIISS",0x16,$sum+28,$build1,0x01,0x04,$build1,$new_count,$platform_id);

foreach(@names){
print oo $bitmaps{$_};
}
print oo pack("III",3,0,$build1);





