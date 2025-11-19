use File::Find;
use File::Slurp;
use File::Path qw(make_path remove_tree);
use File::Basename;

$src_dir="img_unpacked/models/";
$src_dir="/dev/shm/t/gta/unpacked/models";
$dst_dir="col_unpacked/";

remove_tree($dst_dir);
make_path($dst_dir);

#open(rr,">cols_remove.txt");

find({no_chdir=>1,follow=>1,wanted=>sub{
if(-d($File::Find::name)){return;}
if($File::Find::name=~/\.col$/i){
extract_colls($File::Find::name);
#print rr "".join("\t",basename($File::Find::name),"!REMOVE!")."\n";
}
}},$src_dir);

die "Collision files now in \"$dst_dir\"";

sub extract_colls{
my $path=shift;
my $basefile=lc(basename($path));
my $basedir=substr(lc(dirname($path)),length($src_dir));
$basefile=~s/\.col$//is;

print STDERR "Extracting collisions from \"$path\", basefile:$basefile, basedir:$basedir...\n";
open(dd,$path) or die $!;
binmode(dd);

$filesize=-s(dd);
$offset=0;

while($offset<$filesize){

read(dd,$header,32);
($sign,$size,$model,$obj_id)=unpack("A4IZ22S",$header);
if($sign ne "COLL" && $sign ne "COL2" && $sign ne "COL3"){
die "$path: wrong signature!";
}

if($offset+$size>$filesize){
die "$path: chunk data too large, it's more than file size!";
}

if($obj_id>=20000){
die "$path: we got obj_id $obj_id, but expect 0..19999! May be a mod?";
}

if($size<54){
die "$path: size too small!";
}

read(dd,$data,$size-22-2);

$outfile=$dst_dir.'/'.$basedir.'/'.$basefile.'/'.lc($model).'.col';
print STDERR "... $outfile ($obj_id)\n";
if(-s($outfile)){
die "File $outfile already exists!!!";
}
make_path(dirname($outfile));
open(oo,">".$outfile) or die $!;
binmode(oo);
print oo $header;
print oo $data;
close(oo);

$offset+=8+$size;

}
close(dd);
}
