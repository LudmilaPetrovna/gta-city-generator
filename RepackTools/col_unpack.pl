use File::Find;
use File::Path qw(make_path remove_tree);
use File::Basename;

$src_dir="img_unpacked/models/";
$dst_dir="col_unpacked/";

remove_tree($dst_dir);
make_path($dst_dir);

open(rr,">cols_remove.txt");

find({no_chdir=>1,follow=>1,wanted=>sub{
if(-d($File::Find::name)){return;}
if($File::Find::name=~/\.col$/i){
extract_colls($File::Find::name);
#print rr "".join("\t",basename($File::Find::name),"!REMOVE!")."\n";
}
}},$src_dir);



sub extract_colls{
my $path=shift;
my $basefile=lc(basename($path));
$basefile=~s/\.col$//is;
my $basedir=substr(lc(dirname($path)),length($src_dir));


print STDERR "Extracting collisions from \"$path\"...\n";
open(dd,$path) or dir $!;
binmode(dd);

$filesize=-s(dd);
$offset=0;

while($offset<$filesize){

read(dd,$header,32);
($sign,$size,$model,$obj_id)=unpack("A4IZ22S",$header);
if($sign ne "COLL" && $sign ne "COL2" && $sign ne "COL3"){
die "Wrong signature!";
}

if($offset+$size>$filesize){
die "Chunk data too large, it's more than file size!";
}

if($obj_id>=20000){
die "We got obj_id $obj_id, but expect 0..19999! May be a mod?";
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
