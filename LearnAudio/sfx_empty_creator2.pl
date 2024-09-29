
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
$sample_count=2200;
$samplerate=22000;
$sound_size=$sample_count*2;
$bank_header=4+400*12;

for($q=0;$q<$bank_count;$q++){
($package_id,$null,$bank_offset,$bank_size)=unpack("CA3II",substr($look,$q*12,12));
if($null ne "\xCC\xCC\xCC"){
die "Paddings usually 0xCCCCCC! You have very strange file!";
}
print "Bank $q: ".$package_names[$package_id]." offset:$bank_offset, size:$bank_size\n";
$bank_offset=$package_offsets[$q];
$package_offsets[$q]+=$bank_size;

$bank_size=$bank_header+$sound_size*400;

push(@banks,[$package_id,$bank_offset]);
print oo pack("CA3II",0,$null,0,$bank_size);
}

# generating empty packages with 1 bank
$current_id=0;
open(oo,">".$package_files[$current_id]);
binmode(oo);
print STDERR "Writing empty package file $package_files[$current_id]...\n";


# writing bank header in package
$sounds_count=400; # max size of bank, since it actually many banks in same offset
print oo pack("SS",$sounds_count,0);
for($q=0;$q<400;$q++){
#($buffer_offset,$loop_offset,$sample_rate,$headroom)
print oo pack("IiSS",$q*$sample_count*2,$q==8?0:-1,$samplerate,0);
}


@freqs=();
@phases=();
@amps=();

$voices=5;

for($q=0;$q<$sounds_count;$q++){
print STDERR "Writing sound id: $q\n";

for($e=0;$e<$voices;$e++){
$freqs[$e]=rand()*10000;
$phases[$e]=rand()*10000;
$amps[$e]=500+rand()*15000;
}

for($qq=0;$qq<$sample_count;$qq++){
$sample=0;
for($e=0;$e<$voices;$e++){
$sample+=sin($phases[$e]+$qq/$samplerate*2*$freqs[$e])*$amps[$e];
}

if($q==8){
$sample=int(rand()*1000);
}


$gph=$qq/$sample_count*3.1415926;
$window=sin($gph)*10;
if($window>1){$window=1;}
$sample=int($sample*$window);


if($sample<-32768){$sample=-32768;}
if($sample>32767){$sample=32767;}
print oo pack("s",$sample);
}
}

close(oo);

