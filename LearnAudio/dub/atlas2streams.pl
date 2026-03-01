use JSON;
use File::Slurp;
use Data::Dumper;
use File::Path qw(make_path remove_tree);
use File::Basename;

my $srt_root='/dev/shm/Rdown/Glovemansion  Video  SiteRip 2012 - 2024/Video/gta-streams-joined_v3/';
my $audio_root='/dev/shm/t/gta/Grand Theft Auto - San Andreas/audio';
my $raw_root='/dev/shm/t/gta/trans/streams/raw';
my $edit_root='/dev/shm/t/gta/trans/streams/edited_v3';
my $out_root='/dev/shm/t/gta/trans/streams/dub_v3';

$srt_root="/dev/shm/t/gta/trans/streams/joined_v3";
#$out_root='dub_v3';

make_path($out_root);

@streams=map{$srt_root.'/'.$_}grep{/^streams.+mp4$/}read_dir($srt_root);

foreach $ss(@streams){
$fileid=basename($ss);
$fileid=~s/\.mp4$//si;
@srt=read_srt($srt_root.'/'.$fileid.'.srt');

print "Found $ss\n";

$pcmfile="tmp-pcm-".$fileid.'.wav';
$tfile="$srt_root/translated/$fileid-ru-live.mp3";
if(!-e($tfile)){print "File with translation \"$tfile\" not found!\n";next;}

if(!-e($pcmfile)){
print "Unpacking $tfile ---> $pcmfile\n";
`ffmpeg -hide_banner -v 0 -nostdin -i "$tfile" -ac 1 -y "$pcmfile"`;
}

foreach $en(@srt){
$orig="";
$fileid="";
($st,$en,$text)=@{$en};
if($text=~/([^\/]+)$/s){
$orig=$1;
$fileid=$1;
$orig=~s/\.mp4/.ogg/is;
$fileid=~s/\.(mp4|ogg)//is;
}
$en+=5;
$dur=$en-$st;
if(!-e($raw_root.'/'.$orig)){die "Can't find original file \"$orig\"!";}

$outfile="$out_root/".uc($fileid).".ogg";
print "Writing $outfile...\n";
if(-e($outfile)){next;} # this file already dubbed!
if(!$fileid){die "Can't find file ID!";}


#produce segment with voice
unlink("seg.wav");
unlink("seg2.wav");
$editfile=$edit_root."/".uc($fileid).".ogg.wav";
if(-e($editfile)){
`ffmpeg -hide_banner -nostdin -i "$editfile" -ar 48000 -ac 2 -y seg.wav`;
print "USING EDITED FILE $editfile!\n";
} else {

$afile="$srt_root/translated/atlas-$fileid-ru-live.mp3";
if(!-e($afile)){
$afile="$srt_root/translated/atlas-$fileid-ru.mp3";
}

if(-e($afile)){
print "$afile -->> seg.wav\n";
`ffmpeg -v 0 -nostdin -i "$afile" -ar 48000 -ac 2 -y seg.wav`;
} else {
$afile="";
print "-ss $st -i $pcmfile -->> seg.wav\n";
`ffmpeg -v 0 -nostdin -ss $st -i "$pcmfile" -ar 48000 -ac 2 -t $dur -y seg.wav`;
}

}

if(!-e("seg.wav")){die "Can't extract voice!";}

`ffmpeg -v 0 -nostdin -i seg.wav -af 'areverse,silenceremove=start_periods=1,areverse,dynaudnorm,speechnorm,speechnorm,speechnorm,volume=1.2' -y seg-cut.wav`;
`ffmpeg -v 0 -nostdin -i seg-cut.wav -af 'apad=pad_dur=15s' -y seg-padded.wav`;
print "using segment with $segsize bytes\n";
$segsize=-s("seg-cut.wav");
if($segsize>5000){

`ffmpeg -v 0 -nostdin -i "$raw_root/$orig" -ar 48000 -ac 2 -y "back.wav"`;

`ffmpeg -v 0 -nostdin -i back.wav -i "seg-padded.wav" -filter_complex "[0:a][1:a]sidechaincompress=threshold=0.05:ratio=3:attack=1:release=50[ducked]" -map "[ducked]" -y ducked.wav`;
`ffmpeg -v 0 -nostdin -i ducked.wav -i "seg-cut.wav" -filter_complex "[0:a][1:a]amix=inputs=2:duration=longest:dropout_transition=2:normalize=0:weights='1 0.8'[dub]" -map "[dub]" -y res.wav`;

###`ffmpeg -v 0 -nostdin -i res.wav -acodec libvorbis -ac 2 -ar 32000 -qscale:a 0 -compression_level 10 -application voip -map_metadata -1 -y "$outfile"`;
`ffmpeg -v 0 -nostdin -i res.wav -acodec libvorbis -ac 2 -ar 32000 -aq 10 -compression_level 10 -application voip -map_metadata -1 -y "$outfile"`;

}

unlink("seg.wav");
unlink("seg-cut.wav");
unlink("seg-padded.wav");
unlink("back.wav");
unlink("ducked.wav");
unlink("res.wav");

#if($outfile=~/960/){die;}

if($afile){
#die "afile detected!";
}

}

unlink($pcmfile);

}

=pod
1
00:00:00,000 --> 00:00:10,000
/dev/shm/Rdown/Glovemansion  Video  SiteRip 2012 - 2024/Video/gta-streams/AA_0.mp4

2
00:00:25,000 --> 00:00:35,000
/dev/shm/Rdown/Glovemansion  Video  SiteRip 2012 - 2024/Video/gta-streams/AA_1.mp4
=cut

exit;


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





sub read_srt{
my $filename=shift;
my $file=read_file($filename);
my $srtnum=1;
my $wait=0;
$file=~s/\r//sg;

my $st;
my $en;
my $text;
my @res=();
foreach(split(/\n/,$file)){
if($wait==0 && $_==$srtnum){$srtnum++;$wait++;next;}
if($wait==1 && /(\d{2}):(\d{2}):(\d{2}),(\d{3}) --> (\d{2}):(\d{2}):(\d{2}),(\d{3})/){
$st=$1*3600+$2*60+$3+('0.'.$4);
$en=$5*3600+$6*60+$7+('0.'.$8);
$wait++;
$text="";
next;
}
if($wait==2 && $_ eq ""){push(@res,[$st,$en,$text]);$wait=0;next;}
if($wait==2 && length($_)>0){
$text.=$text ne ""?"\n".$_:$_;
next;
}
die "Wrong srt format";
}
if($wait==2 && $text){
push(@res,[$st,$en,$text]);
}
return(@res);
}

