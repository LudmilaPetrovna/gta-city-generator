

loadAlphabet();

genBank(0);
open(dd,"bank-0.bin");
read(dd,$base_bank,-s(dd));
close(dd);

# creating empty package index
@package_offsets=();
@package_files=();
open(dd,">PakFiles.dat");
binmode(dd);
for($q=0;$q<1;$q++){
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
print oo pack("CA3II",0,$null,0,length($base_bank));
}

# generating empty packages

open(oo,">".$package_files[0]);
binmode(oo);
print STDERR "Writing empty package file $package_files[0]...\n";
print oo $base_bank;
close(oo);



sub loadAlphabet{
my $q;
my $file;
for($q=0;$q<18;$q++){
$soundfile="/dev/shm/alpha/".($q+1).".bin";
open(dd,$soundfile);
read(dd,$file,-s(dd));
close(dd);
$key=$q<2?chr(65+$q):chr(48+$q-2);
if($q>=12){
$key=chr(ord("a")+$q-12);
}
print "loading sound $soundfile for $key\n";
$alphabet{$key}=$file;
}

}


sub genSound{
my $bank_id=shift;
my $sound_id=shift;

my $speak=sprintf("A%xB%x",$bank_id,$sound_id);
my @out=();
my $q;
for($q=0;$q<length($speak);$q++){
push(@out,$alphabet{substr($speak,$q,1)});
}
return(join("",@out));
}



sub genBank{
my $bank_id=shift;
my $sounds_count=400;
my @pcms=map{genSound($bank_id,$_)}(0..399);
open(oo,">bank-$bank_id.bin");
print oo pack("SS",$sounds_count,0);
$offset=0;
for($q=0;$q<400;$q++){
print oo pack("IiSS",$offset,-1,3000,0xff83);
$offset+=length($pcms[$q])/2;
}
print oo join("",@pcms);
close(oo);

}


