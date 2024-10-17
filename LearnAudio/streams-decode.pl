


$src_file=$ARGV[0];
$dst_file=$ARGV[1];

require "./xor.pl";
@key=getXorKeyArray("../gta_sa_1.exe");

open(dd,$src_file) or die "Can't read source \"$src_file\" $!";
open(oo,">".$dst_file) or die "Can't write \"$dst_file\" destination: $!";
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