use File::Slurp;
use File::Path qw(make_path remove_tree);
use File::Basename;
use Data::Dumper;

my $audio_root='/dev/shm/t/gta/Grand Theft Auto - San Andreas/audio';
my $want_package=$ARGV[0];

my $total_sfx_len=0;
my %total_package_len=();
my @total_bank_len=();

my $gap_data=read_file('gap.bin');
my $gap_size=length($gap_data)/2;

my $atlas_id=0;
my $cur_atlas_id=-1;


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
if($num_sounds>400){
die "Num sounds is $num_sounds, must not be more than 400!";
}

if($padding!=0){
die "Padding not 0! This is not error, but very strange!";
}

read(dd,$buf,12*400);

@sounds=();
for($q=0;$q<$num_sounds;$q++){
($buffer_offset,$loop_offset,$sample_rate,$headroom)=unpack("IiSs",substr($buf,$q*12,12));
$sounds[$q]=[$sample_rate,$buffer_offset];
}

# calc len of sound
for($q=0;$q<$num_sounds;$q++){
$sounds[$q]->[2]=($q==($num_sounds-1)?$bank_size:$sounds[$q+1]->[1])-$sounds[$q]->[1]; # in samples
$sounds[$q]->[3]=$sounds[$q]->[2]/2/$sounds[$q]->[0]; # in seconds
$total_bank_len[$bank_id]+=$sounds[$q]->[3];
}

# extract or not extract?
if($package_name eq $want_package){

for($q=0;$q<$num_sounds;$q++){
$out_filename=sprintf("sound_sfx/%s/bank%d/sound_%04d.wav",$package_name,$bank_id,$q);
$buf_offset=$sounds[$q]->[1]+$bank_offset+4+400*12;
$buf_len=$sounds[$q]->[2];
$samplerate=$sounds[$q]->[0];

print STDERR "Extracting $out_filename (at $buf_offset, size: $buf_len, samplerate: $samplerate) to atlas:$atlas_id, time:".s2time($outsamlpos/48000)."\n";

if($buf_len&1){die "Buffer size must be aligned to 16 bits!";}
if($buf_len<0){die "Buffer size must not be negative!";}

seek(dd,$buf_offset,0);read(dd,$buf,$buf_len);

# simple output as wav
#make_path(dirname($out_filename));
#open(oo,"|ffmpeg -v 0 -f s16le -ar $samplerate -ac 1 -i - -ar 48000 -ac 1 -y $out_filename");
#binmode(oo);
#print oo $buf;
#close(oo);


# resample
$tmpfile="tmp-resample.wav";
open(oo,"|ffmpeg -v 0 -f s16le -ar $samplerate -ac 1 -i - -ar 48000 -ac 1 -y $tmpfile");
binmode(oo);
print oo $buf;
close(oo);

$resampled=read_file($tmpfile);
unlink($tmpfile);
$samples_count=length($resampled)/2;
if($samples_count==0){die "We found empty sound!!!";}


if($cur_atlas_id!=$atlas_id){
$outsamlpos=0;
$srtnum=0;
close(srt);
close(atlas);

print "OPENING NEW FILE atlas-$atlas_id.srt\n";

open(srt,">atlas-$atlas_id.srt");
open(atlas,"|ffmpeg -v 0 -f s16le -ar 48000 -ac 1 -i - -acodec libopus -b:a 65k -y atlas-$atlas_id.mp4");
$cur_atlas_id=$atlas_id;
}


++$srtnum;
$timestart=s2srt($outsamlpos/48000);
$timeend=s2srt(($outsamlpos+$samples_count)/48000);
$text="$out_filename ($package_name:$buf_offset:$buf_len)";

print srt "$srtnum\n$timestart --> $timeend\n$text\n\n";
print atlas $resampled;
print atlas $gap_data;

$outsamlpos+=$samples_count;
$outsamlpos+=$gap_size;

if($outsamlpos/48000>3600){
$atlas_id++;
}


#if($uniq>=10){last;}

}
}



#now all sounds is extracted

$bank_dur=int($total_bank_len[$bank_id]);
$bank_dur_t=s2time($bank_dur);

$bank_dur_gap=int($total_bank_len[$bank_id])+($num_sounds-1)*3.5;
$bank_dur_gap_t=s2time($bank_dur_gap);

$total_package_len{$package_name}+=$bank_dur;
$total_package_len_gap{$package_name}+=$bank_dur_gap;

print "pack:$package_name,bank:$bank_id,banksize:$bank_size,sounds:$num_sounds,dur:$bank_dur ($bank_dur_t),durgap:$bank_dur_gap ($bank_dur_gap_t)\n";

}

close(srt);
close(atlas);


foreach(@package_names){
$total=s2time($total_package_len{$_});
$total_gap=s2time($total_package_len_gap{$_});
print "Package: $_, total duration: $total, with gap: $total_gap\n";
$total_sfx_len+=$total_package_len{$_};
$total_sfx_len_gap+=$total_package_len_gap{$_};
}

print "Total game sfx len: ".s2time($total_sfx_len).", with gap: ".s2time($total_sfx_len_gap)."\n";



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

