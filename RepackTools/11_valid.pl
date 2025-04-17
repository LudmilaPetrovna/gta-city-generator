use utf8;
use JSON;
use Data::Dumper;
use File::Path qw(make_path remove_tree);
use File::Basename;
use File::Slurp;
use Digest::CRC qw(crc64 crc32 crc16);
use Digest::MD5 "md5_hex";


foreach $filename(`find`){
chomp $filename;

$type="UNKNOWN";
$file=read_file($filename);
$is_good=0;

if(substr($file,0,3) eq "\xFF\xD8\xFF" && substr($file,-2,2) eq "\xFF\xD9"){
$type="jpg";
$is_good=1;
}

if(substr($file,0,8) eq "\x89PNG\x0D\x0A\x1A\x0A" && substr($file,-8,8) eq "IEND\xAE\x42\x60\x82"){
$type="png";
$is_good=1;
}


if(substr($file,0,4) eq "GIF8" && substr($file,-1,1) eq ';'){
$type="gif";
$is_good=1;
}

if(substr($file,4,4) eq "ftyp"){ #mp4
$type="mp4";
$pos=0;
%used=();
$len=length($file);
while($pos<$len){
($size,$ctype)=unpack("NA4",substr($file,$pos,8));
if($size<8){
($unused,$ctype,$size)=unpack("NA4Q>",substr($file,$pos,16));
}
$is_full=$size+$pos>$len?0:1;
#print "$filename: $ctype,$size ($is_full)\n";
if(!$is_full){last;}
$used{$ctype}++;
$pos+=$size;
}
if(exists $used{mdat} && $used{moov} && $used{ftyp}){
$is_good=1;
}

}



if(substr($file,0,4) eq "\x1A\x45\xDF\xA3"){
$type="mkv";
$segment_pos=index($file,"\x18\x53\x80\x67");
$len=length($file);
if($segment_pos>0){
#read int
$varint_pos=$segment_pos+4;
$varint=unpack("C",substr($file,$varint_pos,1));
for($q=0;$q<8;$q++){
if(($varint<<$q)&0x80){
$bits=$q;last;
}
}
$mask=0xFF>>($bits+1);
$varbuf="\x00\x00\x00\x00".pack("C",$varint&$mask).substr($file,$varint_pos+1,$bits);
$varbuf=substr($varbuf,-4);
$varint=unpack("N",$varbuf);
$filesize=$varint+$varint_pos+$bits+1;
print "$filename: bits:$bits, int:$varint, len:$len/$filesize\n";
if($filesize<=$len){$is_good=1;}
}
}

print "$filename: type:$type, good:$is_good\n";

}

