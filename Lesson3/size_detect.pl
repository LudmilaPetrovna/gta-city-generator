use strict;

sub guessFileSize{
my $filename=shift;
my $file=shift;
my $img_file=shift;
my $size=0;
my $is_plaintext=0;

if($img_file=~/cuts\.img/i && $filename=~/\.(cut|dat)$/i){
$is_plaintext=1;
}

if($filename=~/\.cut$/i){
$is_plaintext=1;
}

if($is_plaintext){
my $filesize=length($file);
my $tail=substr($file,$filesize-2048,2048);
if($tail=~/(\x00+)/s){
return($filesize-length($1));
}
}

if($filename=~/\.rrr$/i){ # pre-recorded car path
my $q=0;
my $filesize=length($file);
my $empty="\x00" x 32;
while($q<$filesize){
if(substr($file,$q,32) eq $empty){
return($q);
}
$q+=32;
}
return($filesize);
}

if($filename=~/\.scm$/i
## && substr($file,0,3) eq "\xA4\x03\x09"
){ # this is SCM script from script.img
my $offset=index($file,"\x4E\x00\x00\x00");
if($offset>0){
return($offset+2);
}
return length($file);
}


if($filename=~/\.ifp$/i && substr($file,0,4) eq "ANP3"){ # this is IFP file 4 (-8)
$size=unpack("I",substr($file,4,4))+8;
return $size;
}

if($filename=~/\.txd$/i && substr($file,0,4) eq "\x16\x00\x00\x00"){ # this is TXD file 4 (-12)
$size=unpack("I",substr($file,4,4))+12;
return $size;
}

if($filename=~/\.dff$/i){ # this is DFF file 4 (-12)
while(substr($file,$size,4) eq "\x10\x00\x00\x00" || substr($file,$size,4) eq "\x2B\x00\x00\x00"){
$size+=unpack("I",substr($file,$size+4,4))+12;
}
return $size;
}

if($filename=~/nodes\d+\.dat$/i){ # this is nodes*dat files with car and ped routing information
my($count_nodes,$count_vehnodes,$count_pednodes,$count_navinodes,$count_links)=unpack("IIIII",substr($file,0,20));

my $filler1_expect="\xFF\xFF\x00\x00" x 192;
my $filler1_offset=20+$count_nodes*28+$count_navinodes*14+$count_links*4;
my $filler1=substr($file,$filler1_offset,768);

my $filler2_expect="\x00" x 192;
my $filler2_offset=20+$count_nodes*28+$count_navinodes*14+$count_links*4+768+$count_links*2+$count_links;
my $filler2=substr($file,$filler2_offset,0xc0);
my $filler3_offset=20+$count_nodes*28+$count_navinodes*14+$count_links*4+768+$count_links*2+$count_links+192+$count_links;
my $filler3=substr($file,$filler3_offset,0xc0);

if($filler1 ne $filler1_expect || $filler2 ne $filler2_expect || $filler3 ne $filler2_expect){
return 0;
}
return(20+$count_nodes*28+$count_navinodes*14+$count_links*4+768+$count_links*2+($count_links+0xc0)*2);
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
