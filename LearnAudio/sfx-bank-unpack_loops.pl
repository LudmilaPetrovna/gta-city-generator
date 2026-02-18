use File::Slurp;
use File::Path qw(make_path remove_tree);
use File::Basename;
use Data::Dumper;

my $audio_root='/dev/shm/t/gta/Grand Theft Auto - San Andreas/audio';

# read package list
$pak=read_file($audio_root.'/CONFIG/PakFiles.dat');
$pak_count=length($pak)/52;
for($q=0;$q<$pak_count;$q++){
$name=substr($pak,$q*52,52);
$name=~s/\0.*//s;
push(@package_names,$name);
print "Package $q: $name\n";
}

# reading lookup tables
$look=read_file($audio_root.'/CONFIG/BankLkup.dat');

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



foreach $bank(@banks){
($bank_id,$package_name,$bank_offset,$bank_size)=@{$bank};

close(dd);
open(dd,$audio_root.'/SFX/'.$package_name) or die $!;
binmode(dd);

$sound_id=0;
$total_bank_len=0;
seek(dd,$bank_offset,0);
read(dd,$buf,4);
($num_sounds,$padding)=unpack("SS",$buf);
if($num_sounds>400){die "Num sounds is $num_sounds, must not be more than 400!";}
if($padding!=0){die "Padding not 0! This is not error, but very strange!";}
read(dd,$buf,12*400);

@sounds=();
for($q=0;$q<$num_sounds;$q++){
($buffer_offset,$loop_offset,$sample_rate,$headroom)=unpack("IiSs",substr($buf,$q*12,12));
$sounds[$q]=[$sample_rate,$loop_offset,$buffer_offset];
}

# calc len of sound
for($q=0;$q<$num_sounds;$q++){
$sounds[$q]->[3]=($q==($num_sounds-1)?$bank_size:$sounds[$q+1]->[2])-$sounds[$q]->[2]; # in samples
$sounds[$q]->[4]=$sounds[$q]->[3]/2/$sounds[$q]->[0]; # in seconds
}

for($q=0;$q<$num_sounds;$q++){
($samplerate,$loop,$buf_offset,$buf_len,$time_len)=@{$sounds[$q]};
if($loop<0){next;} #non loop
$out_filename=sprintf("sound_sfx/%s/bank%d/sound_%04d.wav",$package_name,$bank_id,$q);
$buf_offset+=$bank_offset+4+400*12;

print STDERR "Extracting $out_filename (at $buf_offset, size: $buf_len, samplerate: $samplerate, loop: $sounds[$q]->[1])\n";

####if($buf_len&1){die "Buffer size must be aligned to 16 bits! We have $buf_len bytes";}
if($buf_len<0){print STDERR "Buffer size must not be negative!";next;}

seek(dd,$buf_offset,0);read(dd,$buf,$buf_len);

# simple output as wav
make_path(dirname($out_filename));
open(oo,"|ffmpeg -v 0 -f s16le -ar $samplerate -ac 1 -i - -ar 48000 -ac 1 -y $out_filename");
binmode(oo);
print oo $buf;
close(oo);

}
}


sub s2time{
my $s=shift;
#     0    1    2     3     4    5     6     7     8
my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = gmtime($s);
if($hour==0 && $min==0){return sprintf("%ds",$sec);}
if($hour==0){return sprintf("%02d:%02d",$min,$sec);}
return sprintf("%02d:%02d:%02d:%02d",$mday-1,$hour,$min,$sec);
}

sub s2srt{
my $s=shift;
#     0    1    2     3     4    5     6     7     8
my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = gmtime($s);
my $ii=$sec+$min*60+$hour*3600;
return sprintf("%02d:%02d:%02d,%03d",$hour,$min,$sec,int(($s-$ii)*1000));
}

