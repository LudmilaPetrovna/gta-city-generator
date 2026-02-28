use JSON;
use File::Slurp;
use Data::Dumper;
use File::Path qw(make_path remove_tree);
use File::Basename;



$source_dir='/dev/shm/t/gta/trans/streams/raw';
$output_dir='/dev/shm/t/gta/trans/streams/joined_v3';
$max_time=3600*3;

$gap=read_wav("gap2.wav");
$intro=read_wav("intro.mp4");
$silence_time=5;
$silence="\0" x (48000*$silence_time*2);

$skip="HC_1006";

make_path($output_dir);

%chapters=();
@clips=map{
if(/^([^_]+)_(\d+)\.ogg$/i){
$chapters{$1}{$2}++;
}
}read_dir($source_dir);


print Dumper(\%chapters);


foreach $chapter_id(grep{/^HC/}keys %chapters){
$chapter=$chapters{$chapter_id};
@clips_id=keys %{$chapter};
@clips_id=sort{$a <=> $b}@clips_id;
print "Processing chapter $chapter_id, joining clips ".join(", ",@clips_id)."...\n";

$cur_id=-1;
$out_id=0;
foreach $clip_id(@clips_id){

if($cur_id!=$out_id){
$outfile=$output_dir.'/streams_'.lc($chapter_id).'_'.$out_id.'.mp4';
$outfilesrt=$output_dir.'/streams_'.lc($chapter_id).'_'.$out_id.'.srt';
close(oo);
close(oosrt);
open(oo,"|ffmpeg -f s16le -ar 48000 -ac 1 -i - -acodec libopus -b:a 65k -y \"$outfile\"") or die "Can't open output file!";
open(oosrt,">".$outfilesrt) or die "Can't open output file!";
$cur_id=$out_id;
$out_samples=0;
$srtnum=1;
print oo $intro;
$out_samples+=length($intro)/2;
print oo $silence;
$out_samples+=length($silence)/2;
$is_first=1;
}


$inclip=$source_dir.'/'.$chapter_id.'_'.$clip_id.'.ogg';
$inclipsize=-s($inclip);

if($inclip=~/$skip/){next;}

if($inclipsize<100){die "$inclip: Too short clip: $inclipsize!";}

if(!$is_first){
#pad with silence and gap sounds
print oo $silence;
$out_samples+=length($silence)/2;
print oo $gap;
$out_samples+=length($gap)/2;
print oo $silence;
$out_samples+=length($silence)/2;
#pad to 1 second
$pad=$out_samples%48000;
if($pad>0){
$pad=48000-$pad;
$pad_silence="\0" x ($pad*2);
print oo $pad_silence;
$out_samples+=length($pad_silence)/2;
}
}

$start_pos=$out_samples;

print "Processing $inclip ($inclipsize bytes)\n";
open(ii,"ffmpeg -v 0 -nostdin -i \"$inclip\" -ar 48000 -ac 1 -f s16le - |") or die "Can't open source clip using ffmpeg!";
while(!eof(ii)){
$bufsize=read(ii,$buf,81920);
if($bufsize<=0){last;}
if($bufsize&1){die "buf size must be aligned to 16 bits!";}
print oo $buf;
$out_samples+=$bufsize/2;
}
close(ii);


#pad to 1 second
$pad=$out_samples%48000;
if($pad>0){
$pad=48000-$pad;
$pad_silence="\0" x ($pad*2);
print oo $pad_silence;
$out_samples+=length($pad_silence)/2;
}

$end_pos=$out_samples;
$is_first=0;

#write srt

$start_time=s2srt($start_pos/48000);
$end_time=s2srt($end_pos/48000);
$text="$inclip";

print oosrt "$srtnum\n$start_time --> $end_time\n$text\n\n";
$srtnum++;

if($out_samples/48000>=$max_time){
$out_id++;
}
}
close(oo);
close(oosrt);

}




sub s2srt{
my $s=shift;
#     0    1    2     3     4    5     6     7     8
my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = gmtime($s);
my $ii=$sec+$min*60+$hour*3600;
return sprintf("%02d:%02d:%02d,%03d",$hour,$min,$sec,int(($s-$ii)*1000));
}

sub read_wav{
my $filename=shift;
my $binfile=$filename;
$binfile=~s/\.(wav|mp3|mp4)$/.bin/si;
if(!-e($binfile)){
`ffmpeg -nostdin -v 0 -i "$filename" -ac 1 -ar 48000 -f s16le -y "$binfile"`;
}
my $ret=read_file($binfile);
if(length($ret)==0){die "Can't open file \"$filename\" (as binary $binfile)";}
if(length($ret)&1){die "PCM must be aligned to 16 bits";}
return($ret);
}


