

$src_file=$ARGV[0] || "/dev/shm/cache/img_unpacked/anim/cuts/prolog1.ifp";
$dst_file=$ARGV[0] || "prolog1.ifp";

open(dd,$src_file);
read(dd,$buf,-s(dd));
$len=length($buf);

walk(0,$len,0);


$out=pack("A4IIZ8","INFO",12,$cutscene_models_count*0,$cutscene_name);
foreach $modelname(keys %rootcpan){
$cpan=$rootcpan{$modelname};
$info=pack("A4III","INFO",length($cpan)+8,1,0).$cpan;
$dgan=pack("A4I","DGAN",length($info)).$info;
$name=pack("A4IZ32","NAME",32,$modelname);
#$out.=$name.$dgan;
}

$anpk=pack("A4I","ANPK",length($out)).$out;



open(oo,">$dst_file");
print oo $anpk;
close(oo);


sub walk{
my $offset=shift;
my $len=shift;
my $level=shift;
my $parent=shift;
my $strpad=sprintf("%02x:",$level).("  " x $level);
my $ldata="";

if($level>10){die;}

while($len>=8){
my($section,$section_len)=unpack("A4I",substr($buf,$offset,8));
if($section_len==0){
print STDERR "End of file?";
return;
}

print "$strpad ".sprintf("%08x",$offset).": Found \"$section\", len $section_len\n";

if($section eq "ANPK"){
walk($offset+8,$section_len,$level+1,$section);
}

if($section eq "INFO" && $parent eq "ANPK"){
$ldata=substr($buf,$offset+8,$section_len);
($cutscene_models_count,$cutscene_name)=unpack("IZ100",$ldata);
print "$strpad  Models: $cutscene_models_count ($cutscene_name)\n";
}

if($section eq "INFO" && $section_len==8 && $parent eq "DGAN"){
$ldata=substr($buf,$offset+8,$section_len);
($obj_count,$huy)=unpack("II",$ldata);
#substr($buf,$offset+8,4)=pack("I",1);
substr($buf,$offset+8+4,4)=pack("I",0);
print "$strpad  $obj_count (huy: $huy)\n";
}


if($section eq "NAME"){
$ldata=substr($buf,$offset+8,$section_len);
($str)=$ldata;
$str=~s/\0.*//s;
print "$strpad  \"$str\"\n";

if($parent eq "ANPK"){
$current_model_name=$str;
}

}

if($section eq "KRT0"){
$structsize=28+4;
$count=$section_len/$structsize;
$data=substr($buf,$offset+8+4,28);
#$data=pack("fffffff",0,0,0,1,0,0,0);

$newsect="";
for($q=0;$q<$count;$q++){
$newsect.=substr($buf,$offset+8+$structsize*$q,4).$data;
}
if($remove_data){
substr($buf,$offset+8,$section_len)=$newsect;
}
print "$strpad  rotation/translation, $count points\n";
}

if($section eq "KR00"){
$structsize=16+4;
$count=$section_len/$structsize;
$data=substr($buf,$offset+8+4,16);
#$data=pack("ffff",0,0,0,1);
$newsect="";
for($q=0;$q<$count;$q++){
$newsect.=substr($buf,$offset+8+$structsize*$q,4).$data;
}
if($remove_data){
substr($buf,$offset+8,$section_len)=$newsect;
}
print "$strpad  rotation, $count points\n";
}

if($section eq "ANIM"){
($obj_name,$frames,$zero,$next,$prev)=unpack("Z28IIII",substr($buf,$offset+8,$section_len));
substr($buf,$offset+8+28+4,12)=pack("Iii",0,-1,-1);
#substr($buf,$offset+8+28,4)=pack("I",2);
=pod
object name : TString           // Also the name of the bone.
// Note: Because of this fact that this string uses 28 bytes by default.
frames      : INT32             // Number of frames
unknown     : INT32             // Usually 0
next        : INT32             // Next sibling
prev        : INT32             // Previous sibling
frame data  : KFRM
=cut


print "$strpad  ANIM \"$obj_name\", $frames frames, $zero, $next, $prev / ".sprintf("%08x %08x %08x",$zero, $next, $prev)."\n";
}


if($section eq "DGAN" || $section eq "SHIT"){
walk($offset+8,$section_len,$level+1,$section);
}


if($section eq "CPAN"){
$bonename=substr($buf,$offset+8+8,28);
$bonename=~s/\0.*//s;
print "$strpad  anim name $bonename\n";
if(!exists $bones{$current_model_name}){
$bones{$current_model_name}=[];
}
push(@{$bones{$current_model_name}},$bonename);
$remove_data=0;
if($bonename!~/Root/i){
$remove_data=1;
#substr($buf,$offset,4)="JUNK";
#substr($buf,$offset+8,4)="JUNK";
}
walk($offset+8,$section_len,$level+1,$section);

if(!$remove_data && !exists $rootcpan{$current_model_name}){
$rootcpan{$current_model_name}=substr($buf,$offset,$section_len+8);
}


}




$padding=$section_len%4;
if($padding){$padding=4-$padding;}
$offset+=$section_len+8+$padding;
$len-=$section_len+8+$padding;

}

}




