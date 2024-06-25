

($dst_img,$src_dir)=@ARGV;

if(!$dst_img || !$src_dir){
die "Usage: unpacker.pl [dst_img.img] [src_dir]";
}

opendir(dd,$src_dir);
@files=grep{/\.(col|dat|dff|ifp|ipl|txd)$/i}readdir(dd);
closedir(dd);

$entries=@files;

open(oo,">".$dst_img);
binmode(oo);
print oo pack("A4I","VER2",$entries);

print "Packing $entries files\n";

$header_size=bytes2secs($entries*32+8)+1;
$pos=$header_size;

printf("Header (in sectors): %d (in hex: %x)\n",$pos,$pos*2048);

for($e=0;$e<$entries;$e++){

$src_name=$files[$e];
$src_size=bytes2secs(-s($src_dir."/".$src_name));
$src_offset=$pos;
$pos+=$src_size;

print oo pack("ISSa24",$src_offset,$src_size,0,$src_name);

$files[$e]=[$src_name,$src_offset,$src_size];
}


$padding=$header_size*2048-($entries*32+8);
if($padding){
print oo "\x00" x $padding;
}

foreach $fileinfo(@files){
($filename,$offset,$size)=@{$fileinfo};

open(dd,$src_dir."/".$filename);
binmode(dd);
read(dd,$buf,-s(dd));
close(dd);

print oo $buf;
$padding=$size-length($buf);
if($padding){
print oo "\x00" x $padding;
}

}


sub bytes2secs{
my $offset=shift;

if($offset%2048>0){
$offset=int($offset/2048)+1;
} else {
$offset=int($offset/2048);
}
return($offset);
}

