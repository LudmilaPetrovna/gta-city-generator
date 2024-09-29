use strict;

sub guessFileSize{
my $filename=shift;
my $file=shift;
my $size=0;

if($filename=~/\.ifp$/i && substr($file,0,4) eq "ANP3"){ # this is IFP file 4 (-8)
$size=unpack("I",substr($file,4,4))+8;
return $size;
}

if($filename=~/\.txd$/i && substr($file,0,4) eq "\x16\x00\x00\x00"){ # this is TXD file 4 (-12)
$size=unpack("I",substr($file,4,4))+12;
return $size;
}

if($filename=~/\.dff$/i){ # this is DFF file 4 (-12)
while(substr($file,$size,4) eq "\x10\x00\x00\x00"){
$size+=unpack("I",substr($file,$size+4,4))+12;
}
return $size;
}

if($filename=~/\.ipl$/i && substr($file,0,4) eq "bnry"){ # this is binary IPL file

if(substr($file,28,4) ne "\x4c\x00\x00\x00"){die "strange file!";}
if(substr($file,32,4) ne "\x00\x00\x00\x00"){die "strange file!";}

my @sl=(40,0,0,0,48,0);
my @sc=();
my $q;

for($q=0;$q<6;$q++){
$sc[$q]=unpack("I",substr($file,4+$q*4,4));
}
for($q=0;$q<6;$q++){
my($soffset,$ssize)=unpack("II",substr($file,28+$q*8,8));
if($ssize!=0){die "Strange file!";}
$soffset+=$sl[$q]*$sc[$q];
if($soffset>$size){
$size=$soffset;
}
}
return($size);
}


if(substr($file,0,4) eq "COLL" || substr($file,0,4) eq "COL2" || substr($file,0,4) eq "COL3" || substr($file,0,4) eq "COL4"){
while(substr($file,$size,3) eq "COL"){
my $seglen=unpack("I",substr($file,$size+4,4));
$size+=$seglen+8;
}
return($size);
}

}

1
