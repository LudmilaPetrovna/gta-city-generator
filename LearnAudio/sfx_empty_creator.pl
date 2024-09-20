
# creating empty package index
@package_offsets=();
@package_files=();
open(dd,">PakFiles.dat");
binmode(dd);
for($q=0;$q<9;$q++){
$filename="nullpac$q";
$package_files[$q]=$filename;
$package_offsets[$q]=0;
$filename.=("\x00" x (52-length($filename)));
print dd $filename;
}
close(dd);

# creating empty lookup tables
$backup_file="BankLkup-orig.dat";
if(!-e($backup_file)){
rename("BankLkup.dat",$backup_file);
}
open(oo,">BankLkup.dat");
open(dd,$backup_file);
binmode(dd);
binmode(oo);
read(dd,$look,-s(dd));
close(dd);

$bank_count=length($look)/12;
for($q=0;$q<$bank_count;$q++){
($package_id,$null,$bank_offset,$bank_size)=unpack("CA3II",substr($look,$q*12,12));
if($null ne "\xCC\xCC\xCC"){
die "Paddings usually 0xCCCCCC! You have very strange file!";
}
print "Bank $q: ".$package_names[$package_id]." offset:$bank_offset, size:$bank_size\n";
$bank_offset=$package_offsets[$q];
$bank_size=400*12+4;
$package_offsets[$q]+=$bank_size;
push(@banks,[$package_id,$bank_offset]);
print oo pack("CA3II",$package_id,$null,0,0);
}

# generating empty packages
$current_id=-1;
foreach $bank(@banks){
($package_id,$bank_offset)=@{$bank};
if($current_id!=$package_id){
close(oo);
$current_id=$package_id;
open(oo,">".$package_files[$current_id]);
binmode(oo);
print STDERR "Writing empty package file $package_files[$current_id]...\n";
}
$sounds_count=400;
print oo pack("SS",$sounds_count,0);
for($q=0;$q<400;$q++){
print oo pack("IiSS",0,-1,8000,0xff83);
}

}

close(oo);

