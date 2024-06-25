use Data::Dumper;
use File::Path qw(make_path);

@ipls=`find src -iname "*.ipl"`;

foreach $filename(@ipls){
chomp($filename);

open(dd,$filename);
read(dd,$file,-s(dd));
close(dd);

$newfile=$filename;
$newfile=~s/^src/dst/s;

$newdir=$newfile;
$newdir=~s/[^\/]+$//s;

make_path($newdir);
open(oo,">$newfile");

@lines=split(/[\r\n]+/,$file);

foreach(@lines){
$is_section=0;
if(/^inst$/){$in_inst=1;}
#if(/^(grge|enex)$/){$is_dead=1;$is_section=1;}
if(/^end$/){$in_inst=0;$is_dead=0;}

if($in_inst && /^\d/){
($id,$model_name,$inter,$ox,$oy,$oz,$rot_x,$rot_y,$rot_z,$rot_w,$lod)=split(/,\s*/);
if($ox<-200 || $oy<-200 || $ox>200 || $oy>200 || $inter){
$ox="2500.0";
$oy="2500.0";
$oz="2500.0";
$rot_x=$rot_y=$rot_z=0;
$rot_w=1;
$_=join(", ",$id,$model_name,$inter,$ox,$oy,$oz,$rot_x,$rot_y,$rot_z,$rot_w,$lod);
}
next;
}

if($is_dead && !$is_section){next;}
print oo "$_\n";
}

close(oo);

}


