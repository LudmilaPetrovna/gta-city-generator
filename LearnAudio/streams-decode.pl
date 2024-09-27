


$src_file=$ARGV[0];

require "./xor.pl";
@key=getXorKeyArray();

open(dd,$src_file) or die $!;
open(oo,">".$src_file.".dexored") or die $!;
binmode(dd);
binmode(oo);

while(1){
$size=read(dd,$buf,4096);
if($size<=0){last;}
$out="";
for($q=0;$q<$size;$q++){
$out.=chr(ord(substr($buf,$q,1))^$key[$q&0xF]);
}
print oo $out;


}
close(dd);