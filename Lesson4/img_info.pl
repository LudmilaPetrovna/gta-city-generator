use utf8;
use Digest::MD5 qw(md5_hex);

=pod

gta3.img/file1.dff
gta3.img/file1.txd/texturename_1.dxt1
gta3.img/file1.txd/texturename_1a_alpha.dxt1

=cut


$source_img=$ARGV[0];

$out_file=$source_img.".txt";


if(!$source_img){
die "Usage: img_info.pl [source.img]";
}

open(dd,$source_img);
binmode(dd);

read(dd,$buf,8);
($sign,$entries)=unpack("A4I",$buf);

if($sign ne "VER2"){
die "This tool supports only IMG files for GTA:SA! ONLY!!!";
}

print "Reading $entries files\n";

@files=();
for($e=0;$e<$entries;$e++){

read(dd,$buf,32);
($offset,$size,$size_arch,$name)=unpack("ISSa24",$buf);
if($size_arch!=0){
die "Very strange!!! Size_arch must be 0 in GTA:SA!";
}
$offset*=2048;
$size*=2048;
$name=~s/\x00.*//s;
push(@files,[lc($name),$offset,$size]);
#print "$offset: $name ($size, $size_arch)\n";
}

foreach $file(@files){
($name,$offset,$size)=@{$file};
$hash="";

if($size<2048){
$hash="00000";
} else {
seek(dd,$offset,0);
read(dd,$buf,$size-2048);
$hash=md5_hex($buf);
}

$file->[3]=$hash;
}

@files=sort{$a->[0] cmp $b->[0]}@files;

# sprintf("at 0x%08x (%d)",$_->[1],$_->[1]),

open(oo,">".$out_file);
print oo map{lc(join("; ",$source_img.'/'.$_->[0],$_->[2],$_->[3]))."\n"}@files;
close(oo);
print "Completed to $out_file\n";

