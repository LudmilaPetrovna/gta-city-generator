use utf8;
use Encode;
use JSON;
use File::Slurp;
use Data::Dumper;
use File::Path qw(make_path remove_tree);
use File::Basename;

my $srt_root='/dev/shm/t/gta/trans/streams/joined_v3';
my $audio_root='/dev/shm/t/gta/Grand Theft Auto - San Andreas/audio';
my $raw_root='/dev/shm/t/gta/trans/streams/raw';
my $out_root='/dev/shm/t/gta/trans/streams/edits';

$out_root='.';

@streams=map{$srt_root.'/'.$_}grep{/^streams.+mp4$/}read_dir($srt_root);

foreach $ss(@streams){
$fileid=basename($ss);
$fileid=~s/-ru-live.mp3$//si;
$fileid=~s/\.mp4$//si;

$srt_file=$srt_root.'/translated/'.$fileid.'-ru.srt';
$translated_file=$srt_root.'/translated/'.$fileid.'-ru-live.mp3';

@srt=read_srt($srt_root.'/'.$fileid.'.srt');
@rusrt=read_srt($srt_file);

print "Opening $ss...\n";
open(pcm,"ffmpeg -nostdin -i \"$translated_file\" -ar 48000 -ac 1 -f s16le - |");
$sample_pos=0;

foreach $ent(@srt){
$orig="";
$fileid="";
($st,$en,$text)=@{$ent};
if($text=~/([^\/]+)$/s){
$orig=$1;
$fileid=$1;
$orig=~s/\.mp4/.ogg/is;
$fileid=~s/\.mp4//is;
}
$en+=6;
$dur=$en-$st;

$text="";
$text=join("|||",map{$_->[2]}grep{($_->[0]>=$st&&$_->[0]<$en) || ($_->[1]>=$st&&$_->[1]<$en)}@rusrt);
if(index(lc($text),"шарик")<0){next;}

$st_text=s2srt($st);
$en_text=s2srt($en);

$editfile="$out_root/$fileid.wav";
if(-e($editfile)){next;} # this file may be already edited!

print "Processing $editfile (($st_text,$en_text,$text)\n";

$sample_st=$st*48000;
$sample_en=$en*48000;
$sample_skip=$sample_st-$sample_pos;
if($sample_skip<0){die "negative timecode! we need skip $sample_skip, current pos: $sample_pos, target pos: $sample_st";}
while($sample_skip>0){
$buf_size=$sample_skip;
if($buf_size>100000){$buf_size=100000;}
read(pcm,$buf,$buf_size*2);
$sample_skip-=$buf_size;
$sample_pos+=$buf_size;
}

open(oo,"|ffmpeg -v 0 -f s16le -ar 48000 -ac 1 -i - -y $editfile");

$sample_len=$sample_en-$sample_st;
while($sample_len>0){
$buf_size=$sample_len;
if($buf_size>100000){$buf_size=100000;}
read(pcm,$buf,$buf_size*2);
print oo $buf;
$sample_len-=$buf_size;
$sample_pos+=$buf_size;
}
close(oo);



}

}




sub read_srt{
my $filename=shift;
my $file=decode_utf8(read_file($filename));
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


sub s2srt{
my $s=shift;
#     0    1    2     3     4    5     6     7     8
my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = gmtime($s);
my $ii=$sec+$min*60+$hour*3600;
return sprintf("%02d:%02d:%02d,%03d",$hour,$min,$sec,int(($s-$ii)*1000));
}
