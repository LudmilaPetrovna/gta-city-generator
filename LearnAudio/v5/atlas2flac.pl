use utf8;
use JSON;
use Encode;
use File::Slurp;
use Data::Dumper;
use File::Path qw(make_path remove_tree);
use File::Basename;
use Digest::CRC qw(crc64 crc32 crc16 crcccitt crc crc8 crcopenpgparmor);
require './libdub.pl';

binmode(STDOUT,":utf8");

my $src_lang="es";
my $mode='spa_mult';
my $use_debug=1;
my $minimal_len=24000;
$minimal_len=15000;

$dir='/dev/shm/Rdown/Glovemansion  Video  SiteRip 2012 - 2024/Video/gta-spa-11';
if(!-d($dir)){die "$dir is not directory";}

$extracted_count=0;

@rufiles=grep{/-ru.srt$/}read_dir($dir);

foreach $rusrt(@rufiles){
$fileid=$rusrt;
$fileid=~s/-ru.srt$//s;
print "Processing $fileid in $dir...\n";

my($status,$debug,$join)=calc_status($dir.'/'.$fileid,$src_lang);
my $rump3file=$dir.'/'.$fileid.'-ru.mp3';

# cut out wavs and flacs
open(ii,"ffmpeg -v 0 -nostdin -i \"$rump3file\" -ar 48000 -ac 1 -f s16le -|");
my $cursamplepos=0;
my $cuts=[];
my $is_first=1;
foreach(grep{$status->{$_} eq 'ok'}keys %{$join}){
my($st,$en,$eng,$rus)=@{$join->{$_}};
push(@{$cuts},[$_,$st,$en]);
}
my $buf;
my($package_name,$bank_id,$sound_id);
foreach(sort{$a->[1] <=> $b->[1]}@{$cuts}){
my($srcfile,$st,$en)=@{$_};

if($srcfile=~/sound_sfx\/([^\/]+)\/bank(\d+)\/sound_(\d+)\.wav(\S*)/){
($package_name,$bank_id,$sound_id,$tryout)=($1,$2|0,$3|0);

} else {die "wrong format";}



print_join_entry($join,$status,$srcfile);
my $skip=int($st*48000)-$cursamplepos;
if($skip<0){die "Can't rewwind $skip!";}
$cursamplepos+=$skip;
print "we now at $cursamplepos\n";
$skip*=2;
if(read(ii,$buf,$skip)!=$skip){die "Can't skip $skip bytes!";}
my $len=int(($en-$st)*48000);
if($len<0){die "Len $len can't be negative!";}
$cursamplepos+=$len;
print "we now at $cursamplepos\n";
$len*=2;
if(read(ii,$buf,$len)!=$len){die "Can't read $len usable bytes!";}

my $flacname="tmp-cutvoice-${package_name}_${bank_id}_${sound_id}.flac";
my $pcmname="tmp-cutvoice-${package_name}_${bank_id}_${sound_id}.pcm";
my $pcmname2="tmp-cutvoice-${package_name}_${bank_id}_${sound_id}.wav";

write_file($pcmname,$buf);

open(oo,"|ffmpeg -v 0 -f s16le -ar 48000 -ac 1 -i - -y $pcmname2");
print oo $buf;
close(oo);


my($total_samples,$leading_zeros,$trailing_zeros,$first_nonzero,$useful_length,$silence_flag)=split(/\s/s,`./calc_duration "$pcmname"`);
print "anal ($total_samples,$leading_zeros,$trailing_zeros,$first_nonzero,$useful_length,$silence_flag)\n";

unlink($pcmname);


if($useful_length<24){
print STDERR "$pcmname: File may be empty!";
next;
}


if(($leading_zeros<50 && !$is_first) || $trailing_zeros<50){
print STDERR "$pcmname: File may be trimmed!";
if($use_debug){
$debug_filename=sprintf("debug_trimmed/%s/%s/bank_%04d/b%04d_s%04d_t%s.wav",$mode,lc($package_name),$bank_id,$bank_id,$sound_id,$tryout?$tryout:rand());
make_path(dirname($debug_filename));
`mv "$pcmname2" "$debug_filename"`;
}
next;
}

if($silence_flag){
print STDERR "$pcmname: Too much silence inside file!";
if($use_debug){
$debug_filename=sprintf("debug_silence/%s/%s/bank_%04d/b%04d_s%04d_t%s.wav",$mode,lc($package_name),$bank_id,$bank_id,$sound_id,$tryout?$tryout:rand());
make_path(dirname($debug_filename));
`mv "$pcmname2" "$debug_filename"`;
}
next;
}

if($useful_length<$minimal_len){
print STDERR "$pcmname: File too short!";
if($use_debug){
$debug_filename=sprintf("debug_short/%s/%s/bank_%04d/b%04d_s%04d_t%s.wav",$mode,lc($package_name),$bank_id,$bank_id,$sound_id,$tryout?$tryout:rand());
make_path(dirname($debug_filename));
`mv "$pcmname2" "$debug_filename"`;
}
next;
}

unlink($pcmname2);


print "opening out\n";
open(oo,"|ffmpeg -v 0 -f s16le -ar 48000 -ac 1 -i - -y '$flacname'");
print oo substr($buf,$leading_zeros*2,$useful_length*2);
close(oo);

my $flac_encoded=read_file($flacname);
my $outname=sprintf("%s/raw_trans_voice/%s/%s/bank_%04d/b%04d_s%04d_c%08x.flac",$flac_repo,$mode,lc($package_name),$bank_id,$bank_id,$sound_id,crc32($flac_encoded));
make_path(dirname($outname));
`mv "$flacname" "$outname"`;
print "Written $outname\n";

$is_first=0;
$extracted_count++;

}
close(ii);



}


print "Extracted files: $extracted_count\n";


