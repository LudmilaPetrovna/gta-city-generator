

($dst_img,$src_dir,$overlay_dir)=@ARGV;

if(!$dst_img || !$src_dir){
die "Usage: packer.pl [dst_img.img] [src_dir] [pverlay_dir]";
}

$overlay_dirinfo=readNormalizedDir($overlay_dir);
$src_dirinfo=readNormalizedDir($src_dir);

opendir(dd,$src_dir);
@files=grep{/\.[a-z]/i}readdir(dd);
#@files=grep{/\.(col|dat|dff|ifp|ipl|txd)$/i}readdir(dd);
closedir(dd);

$entries=@files;

open(oo,">".$dst_img);
binmode(oo);
print oo pack("A4I","VER2",$entries);

print "Packing $entries files\n";

$header_size=bytes2secs($entries*32+8);
$pos=$header_size;

printf("Header (in sectors): %d (in hex: %x)\n",$pos,$pos*2048);

for($e=0;$e<$entries;$e++){
$src_name=$files[$e];

$full_name=exists $overlay_dirinfo->{$src_name}?$overlay_dir."/".$src_name:$src_dir."/".$src_name;
print "fn: $full_name\n";
$src_size=bytes2secs(-s($full_name));
$src_offset=$pos;
$pos+=$src_size;

print oo pack("ISSa24",$src_offset,$src_size,0,$src_name);

$files[$e]=[$full_name,$src_name,$src_offset,$src_size*2048];
}

print STDERR "Header size: $header_size sectors\n";

$padding=$header_size*2048-($entries*32+8);
if($padding){
print oo "\x00" x $padding;
}

print STDERR "Padding to ".tell(oo)."\n";

foreach $fileinfo(@files){
($full_name,$filename,$offset,$size)=@{$fileinfo};
print STDERR "Packing file $full_name...\n";
open(dd,$full_name);
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

if(($offset%2048)>0){
$offset=int($offset/2048)+1;
} else {
$offset=int($offset/2048);
}
return($offset);
}


sub readNormalizedDir{
my $path=shift;
my $dirinfo={};
my $dd;
opendir($dd,$path);
foreach(readdir($dd)){
$dirinfo->{$_}=lc($_);
}
closedir($dd);
return($dirinfo);
}




