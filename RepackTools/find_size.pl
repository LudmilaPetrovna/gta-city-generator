open(dd,$ARGV[0]);
read(dd,$file,-s(dd));


#9C702700


if(substr($file,0,4) eq "ANP3"){ # this is IFP file 4 (-8)
$size=unpack("I",substr($file,4,4))+8;
print "filesize: $size\n";
die;
}

if(substr($file,0,4) eq "\x16\x00\x00\x00"){ # this is TXD file 4 (-12)
$size=unpack("I",substr($file,4,4))+12;
print "filesize: $size\n";
die;
}

if(substr($file,0,4) eq "\x10\x00\x00\x00"){ # this is DFF file 4 (-12)
$size=unpack("I",substr($file,4,4))+12;
print "filesize: $size\n";
die;
}

if(substr($file,0,4) eq "bnry"){ # this is binary IPL file

if(substr($file,28,4) ne "\x4c\x00\x00\x00"){die "strange file!";}
if(substr($file,32,4) ne "\x00\x00\x00\x00"){die "strange file!";}

my @sl=(40,0,0,0,48,0);
my @sc=();

for($q=0;$q<6;$q++){
$sc[$q]=unpack("I",substr($file,4+$q*4,4));
}
for($q=0;$q<6;$q++){
($offset,$size)=unpack("II",substr($file,28+$q*8,8));
if($size!=0){die "Strange file!";}
$offset+=$sl[$q]*$sc[$q];
if($offset>$maxsize){
$maxsize=$offset;
}
}
print "File size $maxsize\n";
}


if(substr($file,0,4) eq "COLL" || substr($file,0,4) eq "COL2" || substr($file,0,4) eq "COL3" || substr($file,0,4) eq "COL4"){

$offset=0;
while(substr($file,$offset,3) eq "COL"){
$size=unpack("I",substr($file,$offset+4,4));
$offset+=$size+8;
}
print "filesize: $offset\n";
die;
}


$len=length($file);
for($q=$len-1;$q>=0;$q--){
if(substr($file,$q,1) ne "\x00"){
$size=$q+1;
printf("Possible real size is 0x%x (%d)\n",$size,$size);
last;
}

}

for($w=0;$w<10;$w++){
for($q=0;$q<1000;$q++){
$try=pack("I",$size-$q*4+$w);
$offset=index($file,$try);
if($offset<0){next;}
printf("".($size-$q*4+$w)." Possible size offset is 0x%x (%d) for %s size (-$q*4+$w)\n",$offset,$offset,$size-$q*4+$w,$q+$w);
}
}







=pod

