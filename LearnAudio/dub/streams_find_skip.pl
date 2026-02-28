use JSON;
use File::Slurp;
use Data::Dumper;
use File::Path qw(make_path remove_tree);
use File::Basename;

my $raw_root='/dev/shm/t/gta/trans/streams/raw';
my $out_root='/dev/shm/t/gta/trans/streams/dub';
my $out_root2='/dev/shm/t/gta/trans/streams/dub_v3';
$host_root="R:\\downloads\\//////////////////gta-streams-raw\\";

open(oo,">skipped.m3u");


@srcs=read_dir($raw_root);
foreach $s(@srcs){
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
$atlas_file="atlas-".$s;
$atlas_file=~s/\.ogg/.mp4/si;

`ffmpeg -i "$infile" -ac 1 -ar 48000 -ab 65k -acodec libopus -y "streams2/$atlas_file"`;

}


}

