use File::Find;
use File::Path qw(make_path remove_tree);
use File::Basename;
use Data::Dumper;

($dst_img,@sources)=@ARGV;

if(!$dst_img || !@sources){
die "Usage: packer.pl [dst_img.img] [src_dir1] [src_dir2] ...";
}

# read all sources
@sources=map{readSource($_)}@sources;

# mix
$final={};
foreach $src(@sources){
foreach $k(keys %{$src}){
$final{$k}=$src->{$k};
}
}


@files=sort keys %final;
#@files=grep{/\.(col|dat|dff|ifp|ipl|txd)$/i}@files;

$entries=@files;

open(oo,">".$dst_img);
binmode(oo);
print oo pack("A4I","VER2",$entries);

# writing reader
print "Packing $entries files\n";
$header_size=bytes2secs($entries*32+8);
$pos=$header_size;

printf("Header (in sectors): %d (in hex: %x)\n",$pos,$pos*2048);

for($e=0;$e<$entries;$e++){
$entry_name=$files[$e];
$entry_size=$final{$entry_name}->[2];

$src_size=bytes2secs($entry_size);
$src_offset=$pos;
$pos+=$src_size;

print oo pack("ISSa24",$src_offset,$src_size,0,$entry_name);
}

print STDERR "Header size: $header_size sectors\n";

$padding=$header_size*2048-($entries*32+8);
if($padding){
print oo "\x00" x $padding;
}

print STDERR "Padding to ".tell(oo)."\n";

# writing actual data

foreach $filename(@files){
($filepath,$offset,$size)=@{$final{$filename}};
print STDERR "Packing file $filename (from $filepath)...\n";
open(dd,$filepath);
binmode(dd);
read(dd,$buf,$size);
close(dd);

$sectors=bytes2secs($size);
$padding=$sectors*2048-$size;

if($padding){
$buf.="\x00" x $padding;
}

print oo $buf;

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


sub readSource{
my $path=shift;
# source may be a directory...
if(-d($path)){return(readSourceDir($path));}

# source may be IMG file...
my $dd;
my $buf;
open($dd,$path) or die "Can't open source file $path: $!";
binmode($dd);
read($dd,$buf,100);
close($dd);

my($sign,$filecount)=unpack("A4I",$buf);
if($sign eq "VER2" && $filecount<1000000){
return(readSourceIMG($path));
}

}

sub readSourceDir{
my $path=shift;
my $tree={};
print STDERR "Reading DIRECTORY source $path...\n";

find({no_chdir=>1,follow=>1,wanted=>sub{
if(-d($File::Find::name)){return;}
my($name,$dir)=fileparse($File::Find::name);
my $key=lc($name);
if(exists $tree->{$key}){
print STDERR "WARNING: dir $path contain multiple $key!!!\n";
}
$tree->{$key}=[$File::Find::name,0,-s($File::Find::name)];
}},$path);
return($tree);
}

sub readSourceIMG{
my $path=shift;
my $tree={};
my $dd;
my $buf;
print STDERR "Reading IMG archive $path...\n";
open($dd,$path) or die "Can't open source file $path: $!";
binmode($dd);
read($dd,$buf,8);
my($sign,$filecount)=unpack("A4I",$buf);
if($sign ne "VER2" || $filecount>1000000){die "$path: wrong signature or too many files!";}

my $e;
for($e=0;$e<$filecount;$e++){

read($dd,$buf,32);
my($offset,$size,$size_arch,$name)=unpack("ISSZ24",$buf);
if($size_arch!=0){
die "Very strange!!! Size_arch must be 0 in GTA:SA!";
}
$offset*=2048;
$size*=2048;
$tree->{lc($name)}=[$path,$offset,$size];
}
close($dd);

return($tree);
}



