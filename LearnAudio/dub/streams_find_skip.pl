use JSON;
use File::Slurp;
use Data::Dumper;
use File::Path qw(make_path remove_tree);
use File::Basename;

my $raw_root='/dev/shm/t/gta/trans/streams/raw';
my $out_root='/dev/shm/t/gta/trans/streams/dub';
my $out_root2='/dev/shm/t/gta/trans/streams/dub_v3';
$host_root="R:\\downloads\\Glovemansion  Video  SiteRip 2012 - 2024\\Video\\gta-streams-raw\\";

open(oo,">skipped.m3u");
open(pcm,"|ffmpeg -f s16le -ar 48000 -ac 1 -i - -acodec libopus -b:a 65k -y skipped.mp4");
open(oosrt,">skipped.srt");
$pcm_pos=0;
$srt_num=1;

@srcs=read_dir($raw_root);
foreach $s(sort @srcs){
$fileid=$s;
$fileid=~s/\.ogg$//is;

$infile=$raw_root.'/'.$fileid.'.ogg';
$outfile=$out_root.'/'.$fileid.'.OGG';
$outfile2=$out_root2.'/'.$fileid.'.ogg';

$insize=-s($infile);
$outsize=-s($outfile);
if($outsize==0){
$outsize=-s($outfile2);
}

print "$s	$insize	$outsize\n";

if($outsize<100){
print oo "$host_root\\$s\n";

$start_pos=$pcm_pos;
print "Processing $infile ($insize bytes)\n";
open(ipcm,"ffmpeg -v 0 -nostdin -i \"$infile\" -af 'atempo=1.8,atempo=1.7' -ac 1 -ar 48000 -f s16le -|");
while(1){
$inbytes=read(ipcm,$buf,10000);
if($inbytes<=0){last;}
print pcm $buf;
$pcm_pos+=$inbytes/2;
}
close(ipcm);

$end_pos=$pcm_pos;


$start_time=s2srt($start_pos/48000);
$end_time=s2srt($end_pos/48000);
$text="$infile";

print oosrt "$srtnum\n$start_time --> $end_time\n$text\n\n";
$srtnum++;



}


}


sub s2srt{
my $s=shift;
#     0    1    2     3     4    5     6     7     8
my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = gmtime($s);
my $ii=$sec+$min*60+$hour*3600;
return sprintf("%02d:%02d:%02d,%03d",$hour,$min,$sec,int(($s-$ii)*1000));
}


