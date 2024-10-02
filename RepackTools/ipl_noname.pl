`rm -rf Dst`;

$files=`find Src -iname "*.ipl"`;


foreach $filename(split(/\n/,$files)){
$newfile=$filename;
$newfile=~s/^Src/Dst/s;
$newdir=$newfile;
$newdir=~s/\/[^\/]+$//s;

print "Processing $filename --> $newfile\n";

`mkdir -p $newdir`;

open(ii,$filename) or die;
open(oo,">".$newfile) or die;
$is_patched=0;
while(<ii>){

if(/^inst/){
$in_inst=1;
}

if(/^end/){
$in_inst=0;
}


if($in_inst && /^\d+,/){
@fields=split(/\s*,\s*/);
$fields[1]="non_name5";
$is_patched=1;
$_=join(", ",@fields);
}

print oo $_;
}
close(oo);
close(ii);

if(!$is_patched){
#unlink($newfile);
}

}

