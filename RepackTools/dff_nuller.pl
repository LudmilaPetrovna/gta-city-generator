use Data::Dumper;
use File::Slurp;
#compmedhos4_lae-chunkdump-10(10)-1A(30)-0F(20)-08(20)-07(90)-06(20)-01(10).bin

$filename="compmedhos4";
$key="10-1A-0F-08-07-06-01";

$key_re=$key;
$key_re=~s/([\da-f]+)/$1(.+?)/sgi;

$re=qr/$filename.+?chunkdump-$key_re/i;

print $key_re;


opendir(dd,".");
@files=grep{$_=~$re}readdir(dd);
closedir(dd);

foreach(@files){
print "Writing to $_\n";
write_file($_,"\x00\x00\x00\x00");
}

