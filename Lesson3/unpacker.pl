use File::Basename;
use File::Path qw(make_path remove_tree);

require "".dirname(__FILE__)."/size_detect.pl";

($source_img,$dest_dir)=@ARGV;

if(!$source_img || !$dest_dir){
die "Usage: unpacker.pl [source.img] [dest dir]";
}

open(dd,$source_img);
binmode(dd);

read(dd,$buf,8);
($sign,$entries)=unpack("A4I",$buf);

if($sign ne "VER2"){
die "This tool supports only IMG files for GTA:SA! ONLY!!!";
}

print "Unpacking $entries files\n";

@files=();
for($e=0;$e<$entries;$e++){

read(dd,$buf,32);
($offset,$size,$size_arch,$name)=unpack("ISSZ24",$buf);
if($size_arch!=0){
die "Very strange!!! Size_arch must be 0 in GTA:SA!";
}
$offset*=2048;
$size*=2048;
push(@files,[$name,$offset,$size]);
print "$offset: $name ($size, $size_arch)\n";
}

# unpacking real files

make_path($dest_dir);

foreach $fileinfo(@files){
($filename,$offset,$size)=@{$fileinfo};

seek(dd,$offset,0);
read(dd,$buf,$size);

$guessed_size=guessFileSize($filename,$buf);
$padding_size=$size-$guessed_size;
if($padding_size>0 && $padding_size<2048){ #looks like this is a padding!
print "$filename: guessed size: $guessed_size/$size (padding: $padding_size bytes)\n";
if(substr($buf,$guessed_size,$padding_size) eq "\x00" x $padding_size){
$size=$guessed_size;
$buf=substr($buf,0,$size);
}

}

open(oo,">".$dest_dir."/".$filename);
binmode(oo);
print oo $buf;
close(oo);

}

