use JSON;
use File::Slurp;
use Data::Dumper;
use File::Path qw(make_path remove_tree);
use File::Basename;

my $audio_root='/dev/shm/t/gta/Grand Theft Auto - San Andreas/audio';

# load package and sound info data

@snddb=();

$paks=read_file($audio_root.'/CONFIG/PakFiles.dat');
$lk=read_file($audio_root.'/CONFIG/BankLkup.dat');
@banks=();
$bank_count=length($lk)/12;
for($q=0;$q<$bank_count;$q++){
($package_id,$pad,$bank_offset,$bank_size)=unpack("CA3II",substr($lk,$q*12,12));
if($pad ne "\xCC\xCC\xCC"){die "Paddings usually 0xCCCCCC! You have very strange file!";}
push(@banks,[$q,$package_id,$bank_offset,$bank_size]);
}

$cur_package_id=-1;
foreach $bank(@banks){
($bank_id,$package_id,$bank_offset,$bank_size)=@{$bank};
$package_name=unpack("Z52",substr($paks,$package_id*52,52));

if($package_id!=$cur_package_id){
close(dd);
open(dd,$audio_root.'/SFX/'.$package_name) or die $!;
binmode(dd);
$bank_id_in_package=1;
$cur_package_id=$package_id;
}

$sound_id=0;
seek(dd,$bank_offset,0);
read(dd,$buf,4);
($num_sounds,$padding)=unpack("SS",$buf);
if($num_sounds>400){die "Num sounds is $num_sounds, must not be more than 400!";}
if($padding!=0){die "Padding not 0! This is not error, but very strange!";}

read(dd,$buf,12*400);

$maxsize=0;
@sounds=();
for($q=0;$q<$num_sounds;$q++){
($buffer_offset,$loop_offset,$sample_rate,$headroom)=unpack("IiSs",substr($buf,$q*12,12));
print ll "$modloader\n";
$sounds[$q]=[$buffer_offset,$loop_offset,$sample_rate,$headroom];
}
for($q=0;$q<$num_sounds;$q++){
($buffer_offset,$loop_offset,$sample_rate,$headroom)=@{$sounds[$q]};
$buffer_size=($q==($num_sounds-1)?$bank_size:$sounds[$q+1]->[0])-$sounds[$q]->[0]; # in bytes???
$buffer_offset+=$bank_offset+4+400*12;
$modloader="audio/sfx/".uc($package_name)."/Bank_".$bank_id_in_package.'/Sound_'.($q+1).".wav";
$snddb[$bank_id]->[$sound_id]=[$bank_id,$package_id,$package_name,$bank_offset,$bank_size,$buffer_offset,$buffer_size,$loop_offset,$sample_rate,$headroom,$modloader];
$sound_id++;
}
$bank_id_in_package++;
}

# now we have all info for extraction original sounds

# loading atlas data

#print Dumper(\@snddb);

for($aa=0;$aa<10000;$aa++){
$srtfile=$srt_root."/atlas-$aa.srt";
$mp3file=$trans_root."/atlas-$aa-ru-live.mp3";
if(!-e($mp3file)){last;}

open(srt,$srtfile) or die $!;
open(mp3,"ffmpeg -nostdin -hide_banner -loglevel error -i '$mp3file' -ar 48000 -ac 1 -f s16le - |") or die $!;
binmode(mp3);
$cursample=0;

while(<srt>){
if(/(\d{2}):(\d{2}):(\d{2}),(\d{3}) --> (\d{2}):(\d{2}):(\d{2}),(\d{3})/){
$st=$1*3600+$2*60+$3+('0.'.$4);
$et=$5*3600+$6*60+$7+('0.'.$8);
$origdur=$et-$st;
}

if(/bank(\d+)\/sound_(\d+)\.wav/){
$sound=$snddb[$1]->[$2];
if(!defined $sound){die "Can't find sound in bank $1, sound $2\n";}
print "Processing $_";
#print Dumper($sound);

($bank_id,$package_id,$package_name,$bank_offset,$bank_size,$buffer_offset,$buffer_size,$loop_offset,$sample_rate,$headroom,$modloader)=@{$sound};


$gamesoundfile="tmp-sound-ingame-$package_name-$bank_id-$buffer_offset.wav";
$transsoundfile_fast="tmp-sound-transfast-$package_name-$bank_id-$buffer_offset.wav";
$transsoundfile_norm="tmp-sound-transnorm-$package_name-$bank_id-$buffer_offset.wav";

$ressoundfile=$modloader;

$ressoundfile="tmp-sound-res-$package_name-$bank_id-$buffer_offset.wav";
$finalsoundfile="tmp-sound-final-$package_name-$bank_id-$buffer_offset.wav";


#extract game sound
close(dd);
open(dd,$audio_root.'/SFX/'.$package_name) or die $!;
seek(dd,$buffer_offset,0);read(dd,$buf,$buffer_size);

# simple output as wav
open(oo,"|ffmpeg -hide_banner -loglevel quiet -f s16le -ar $sample_rate -ac 1 -i - -ar 48000 -ac 1 -y $gamesoundfile");
binmode(oo);
print oo $buf;
close(oo);

#extract translated sound
$st-=.25;
if($st<0){$st=0;}
$stsample=int($st*48000);
if($cursample>$stsample){die "can't rewwind!";}
$skip=$stsample-$cursample;
read(mp3,$buf,$skip*2);
$cursample+=$skip;

$et+=4.5;
$etsample=int($et*48000);
$len=$etsample-$stsample;
read(mp3,$buf,$len*2);
$cursample+=$len;

# simple output as wav
open(oo,"|ffmpeg -hide_banner -loglevel error -f s16le -ar 48000 -ac 1 -i - -ar 48000 -ac 1 -af 'silenceremove=start_periods=1:start_threshold=-30dB:stop_periods=-1:stop_threshold=-40dB:stop_duration=0.02:window=0.1,atempo=1.5' -y $transsoundfile_fast");
binmode(oo);
print oo $buf;
close(oo);

open(oo,"|ffmpeg -hide_banner -loglevel error -f s16le -ar 48000 -ac 1 -i - -ar 48000 -ac 1 -af 'silenceremove=start_periods=1:start_threshold=-30dB:stop_periods=-1:stop_threshold=-40dB:stop_duration=0.02:window=0.1' -y $transsoundfile_norm");
binmode(oo);
print oo $buf;
close(oo);

#ffmpeg -i  -filter_complex "[0:a][1:a]sidechaincompress=threshold=0.05:ratio=3:attack=1:release=50[ducked];[1:a]dynaudnorm,speechnorm,speechnorm,speechnorm,volume=1.2[speech],[ducked][speech]amix=inputs=2:duration=longest:dropout_transition=2:normalize=0:weights='1 0.8'[dub]" -map "[dub]" -y dub.mp3

$filter_opts="[1:a]asplit[vo][vo_side];";
$filter_opts.="[0:a]dynaudnorm[orig];";
$filter_opts.="[vo]dynaudnorm[vo_norm];";
$filter_opts.="[orig][vo_side]sidechaincompress=threshold=0.1:ratio=2:attack=10:release=100,volume=0.3[ducked];";
$filter_opts.="[vo_norm][ducked]amix=inputs=2:duration=first:dropout_transition=2,dynaudnorm,volume=2[dub]";


$filter_opts="";
$filter_opts.="[0:a]volume=2[orig];";
$filter_opts.="[1:a]volume=10[vo_norm];";
$filter_opts.="[vo_norm][orig]amix=inputs=2:duration=longest:dropout_transition=0.2,dynaudnorm,aresample=$sample_rate,volume=4[dub]";


$len_norm=get_file_len($transsoundfile_norm);
$len_fast=get_file_len($transsoundfile_fast);

$transsoundfile=$len_fast<$origdur?$transsoundfile_norm:$transsoundfile_fast;

print "$len_norm\t$len_fast\t$origdur\t$transsoundfile\n";

make_path(dirname($modloader));
#print "writing  to  $modloader with $sample_rate\n";
`ffmpeg -nostdin -hide_banner -loglevel error -i $gamesoundfile -i $transsoundfile -filter_complex '$filter_opts' -map [dub] -y $ressoundfile`;
`ffmpeg -nostdin -hide_banner -loglevel error -i $ressoundfile -af silenceremove=stop_periods=-1:stop_threshold=-30dB:stop_duration=0.02:window=0 -ar $sample_rate -y $modloader`;


#print join("\t",$origdur,map{$info=`ffprobe $_ 2>&1`;if($info=~/Duration: (\d{2}:\d{2}:\d{2}\S+)/){$1}}($gamesoundfile,$transsoundfile_norm,$transsoundfile,$ressoundfile,$finalsoundfile))."\n";


unlink($gamesoundfile);
unlink($transsoundfile_norm);
unlink($transsoundfile_fast);
unlink($transsoundfile);
unlink($ressoundfile);

#if($qqqq++>20){die;}

}


}
close(srt);
close(mp3);
}



sub get_file_len{
my $filename=shift;
my $info=`ffprobe $filename 2>&1`;
my $ret=0;
if($info=~/Duration: (\d{2}):(\d{2}):(\d{2})\.(\d{2})/){
$ret=$1*3600+$2*60+$3+("0.".$4);
}
return($ret);
}

