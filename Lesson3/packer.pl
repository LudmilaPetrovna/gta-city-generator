use File::Find;
use File::Path qw(make_path remove_tree);
use File::Basename;
use Data::Dumper;
use Digest::MD5 "md5_hex";

($dst_img,@sources)=@ARGV;

if(!$dst_img || !@sources){
die "Usage: packer.pl [dst_img.img] [src_dir1] [src_dir2] ...";
}

$timestamp_started=time();

# read all sources
@sources=map{readSource($_)}@sources;

# mix
$final={};
foreach $src(@sources){
foreach $k(keys %{$src}){
$final{$k}=$src->{$k};
}
}

%dups=();

@files=sort{$final{$a}->[2] <=> $final{$b}->[2]}grep{$final{$_}->[2]>=0}keys %final;
#@files=grep{/\.(col|dat|dff|ifp|ipl|txd)$/i}@files;

$entries=@files;
make_path(dirname($dst_img));
open(oo,">".$dst_img);
binmode(oo);

# writing "fake" reader
$header_size=$entries*32+8;
$header_sectors=bytes2secs($header_size);
print oo "\x00" x ($header_sectors*2048);

# writing actual data

$header=pack("A4I","VER2",$entries);

$cur_sect=$header_sectors;
foreach $filename(@files){
($filepath,$offset,$size)=@{$final{$filename}};
open(dd,$filepath);
binmode(dd);
read(dd,$buf,$size);
close(dd);

$sectors=bytes2secs($size);
$padding=$sectors*2048-$size;

if($padding){
$buf.="\x00" x $padding;
}

$hash=md5_hex($buf);
if(exists $dups{$hash}){
($sect_start,$sectors)=@{$dups{$hash}}
} else {
$dups{$hash}=[$cur_sect,$sectors];
$sect_start=$cur_sect;
$cur_sect+=$sectors;
print oo $buf;
}

$header.=pack("ISSa24",$sect_start,$sectors,0,$filename);
printf(STDERR "%08x: Written file % 25s, %s, (from %s)...\n",$dups{$hash}->[0]*2048,$filename,$hash,$filepath);

}

# updating header

seek(oo,0,0);
print oo $header;

# final touch


$timestamp_finished=time();
print STDERR "Packed successfully for (".($timestamp_finished-$timestamp_started)." seconds)\n";




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

# okay, this may be "remover" file

return(readSourceRemover($path));


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

sub readSourceRemover{
my $path=shift;
my $tree={};
my $dd;
print STDERR "Reading REMOVER text $path...\n";
open($dd,$path) or die "Can't open source file $path: $!";
while(<$dd>){
chomp;
($filename,$action)=split(/\t/);
if($action eq "!REMOVE!"){
$tree->{lc($filename)}=["",-1,-1];
}
}
close($dd);
return($tree);

}



