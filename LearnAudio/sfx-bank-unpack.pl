# read package list
open(dd,"PakFiles.dat");
read(dd,$pak,-s(dd));
close(dd);

$pak_count=length($pak)/52;
for($q=0;$q<$pak_count;$q++){
$name=substr($pak,$q*52,52);
$name=~s/\0.*//s;
push(@package_names,$name);
print "Package $q: $name\n";
}

# reading lookup tables
open(dd,"BankLkup.dat");
read(dd,$look,-s(dd));
close(dd);

#PackageIndex uint8
#Padding      [3]uint8
#// Bank header location in package file.
#BankHeaderOffset uint32
#// Total size of sounds in bank.
#BankSize uint32

$bank_count=length($look)/12;
for($q=0;$q<$bank_count;$q++){
($package_id,$null,$bank_offset,$bank_size)=unpack("CA3II",substr($look,$q*12,12));
if($null ne "\xCC\xCC\xCC"){
die "Paddings usually 0xCCCCCC! You have very strange file!";
}
print "Bank $q: ".$package_names[$package_id]." offset:$bank_offset, size:$bank_size\n";
push(@banks,[$q,$package_names[$package_id],$bank_offset,$bank_size]);
}

#header:
#    NumSounds uint16
#    Padding   uint16
#    Sounds [400]SoundMeta

$want_package=$ARGV[0];

open(dd,$want_package) or die $!;
binmode(dd);


foreach $bank(@banks){
($bank_id,$package_name,$bank_offset,$bank_size)=@{$bank};
if($package_name ne $want_package){next;}

$sound_id=0;
seek(dd,$bank_offset,0);
read(dd,$buf,4);
($num_sounds,$padding)=unpack("SS",$buf);
if($num_sounds>400){
die "Num sounds is $num_sounds, must not be more than 400!";
}

if($padding!=0){
die "Padding not 0! This is not error, but very strange!";
}

read(dd,$buf,12*400);
$filesize=-s($src_file);

@sounds=();
for($q=0;$q<$num_sounds;$q++){
($buffer_offset,$loop_offset,$sample_rate,$headroom)=unpack("IiSs",substr($buf,$q*12,12));
$sounds[$q]=[$sample_rate,$buffer_offset];
}

for($q=0;$q<$num_sounds;$q++){
$sounds[$q]->[2]=($q==($num_sounds-1)?$bank_size:$sounds[$q+1]->[1])-$sounds[$q]->[1];
}

for($q=0;$q<$num_sounds;$q++){
$out_filename="extracted_".$package_name."-".$bank_id."-".(++$sound_id).".wav";
$buf_offset=$sounds[$q]->[1]+$bank_offset+4+400*12;
$buf_len=$sounds[$q]->[2];
$samplerate=$sounds[$q]->[0];

print STDERR "Extracting $out_filename (at $buf_offset/$filesize, size: $buf_len, samplerate: $samplerate)\n";

if($buf_len&1){
die "Buffer size must be aligned to 16 bits!";
}

if($buf_len<0){
die "Buffer size must not be negative!";
}


seek(dd,$buf_offset,0);
read(dd,$buf,$buf_len);

open(oo,"|ffmpeg -v 0 -f s16le -ar $samplerate -ac 1 -i - -y $out_filename");
binmode(oo);
print oo $buf;
close(oo);


#if($uniq>=10){last;}

}
}






