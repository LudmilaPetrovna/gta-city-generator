use File::Find;
use File::Slurp;
use File::Path qw(make_path remove_tree);
use File::Basename;
use Data::Dumper;

require './libdub.pl';

$trans_sounds={};
find({no_chdir=>1,follow=>1,wanted=>sub{
if($File::Find::name=~/bank_(\d+)\/b(\d+)_s(\d+)_.+?flac/s){
my($bank_id,$bank_id2,$sound_id)=($1|0,$2|0,$3|0);
if($bank_id!=$bank_id2){die "Wrong repo layout";}
$trans_sounds->{"$bank_id-$sound_id"}=$File::Find::name;
}

}},$flac_repo.'/raw_trans_voice/');


my $use_gap=0;
my $use_intro=0;
my $use_shuffle=1;
my $use_copy=10;
my $use_downspeed=1;
my $out_bitrate='256k';

my $lang='spa';
my %is_spanish=();
map{$is_spanish{$_}++}split(/\s+/i,$banks_spanish);

my $audio_root='/dev/shm/t/gta/Grand Theft Auto - San Andreas/audio';
my $atlas_len=4800;
my $samplerate=48000;
my $atlas_prefix='atlas_spa_';

my $silence="\x00" x ($samplerate*3*2); # 3 seconds in s16le

my $gap_file='../gap3v2spa.wav';
my $gap_speed=1.5;
unlink('gap.bin');
print STDERR "Generating gap file using $gap_file and speed $gap_speed...\n";
`ffmpeg -nostdin -i $gap_file -af atempo=$gap_speed -ar 48000 -ac 1 -f s16le -y gap.bin`;

my $gap_data=read_file('gap.bin');
my $gap_samples=length($gap_data)/2;
print STDERR "Using gap with $gap_samples samples (".($gap_samples/$samplerate)." seconds)\n";
if($gap_samples<500){die "Wrong gap!";}

my $intro_file='../spanish1.mp3';
my $intro_speed=1.1;
my $intro_data='';
my $intro_size=0;
if($use_intro){
unlink('intro.bin');
print STDERR "Generating intro file using $intro_file and speed $intro_speed...\n";
$ss=int(55+rand()*60);
`ffmpeg -nostdin -v 0 -ss $ss -i $intro_file -af atempo=$intro_speed -ar 48000 -ac 1 -f s16le -t 300 -y intro.bin`;
$intro_data=read_file('intro.bin');
$intro_data.="\x00" x ($samplerate*5*2);
$intro_size=length($intro_data)/2;
}



@newlist=();
print STDERR "Parsing sounds list...\n";
open(sd,"sounds.txt");
while(<sd>){
chomp;
($bank_id,$package_name,$bank_offset,$bank_size,$buffer_offset,$buffer_len,$loop_offset,$sound_sample_rate,$headroom,$ourfilename,$modloader)=split(/\t\|/);
if($lang eq 'spa'){
if(!exists $is_spanish{$bank_id}){next;}
print "IS_SPANISH\n";
}
if($ourfilename=~/sound_sfx\/[^\/]+\/bank(\d+)\/sound_(\d+).wav/){
($fname_bank,$fname_sound)=($1|0,$2|0);
if($fname_bank!=$bank_id){die "Error in sounds database!";}
}
if(exists $trans_sounds->{"${fname_bank}-${fname_sound}"}){
print "SOUND $ourfilename already translated!\n";
next;
}
if($use_shuffle && $use_copy>1){
for($q=0;$q<$use_copy;$q++){
push(@newlist,[$bank_id,$package_name,$bank_offset,$bank_size,$buffer_offset,$buffer_len,$sound_sample_rate,$ourfilename.'_tryout'.$q]);
}
} else {
push(@newlist,[$bank_id,$package_name,$bank_offset,$bank_size,$buffer_offset,$buffer_len,$sound_sample_rate,$ourfilename]);
}
}


if($use_shuffle){
%tmplist=();
foreach(@newlist){
$tmplist{$_->[1]}{$_->[0]}{rand()}=$_;
}
@newlist=map{$k1=$_;map{values %{$tmplist{$k1}{$_}}}keys %{$tmplist{$k1}}}keys %tmplist;
}



my $atlas_id=0;
my $cur_atlas_id=-1;
my $cur_package='';
my $outsamlpos=-100;
my $srtnum=-100;
my $cur_bank_id=-1;
print STDERR "Creating atlas batch...\n";

$cur_bank_id=-1;
foreach(@newlist){
($bank_id,$package_name,$bank_offset,$bank_size,$buffer_offset,$buffer_len,$sound_sample_rate,$ourfilename)=@{$_};

if($use_downspeed){
$sound_sample_rate=int($sound_sample_rate*(.5+rand()*.6));
}

if($cur_package ne $package_name){
close(dd);
open(dd,$audio_root.'/SFX/'.$package_name) or die $!;
binmode(dd);
$cur_package=$package_name;
}

if($cur_bank_id!=$bank_id){
$cur_bank_id=$bank_id;
if($outsamlpos/$samplerate>=$atlas_len){
$atlas_id++;
}
}

if($cur_atlas_id!=$atlas_id){
$outsamlpos=0;$srtnum=1;
close(srt);close(atlas);
print "OPENING NEW FILE $atlas_prefix$atlas_id.srt\n";
open(srt,">$atlas_prefix$atlas_id.srt");
open(atlas,"|ffmpeg -v 0 -f s16le -ar 48000 -ac 1 -i - -acodec libopus -b:a $out_bitrate -y $atlas_prefix$atlas_id.mp4");
$cur_atlas_id=$atlas_id;

if($use_intro){
print atlas $intro_data;
$outsamlpos+=$intro_size;
}

}

seek(dd,$buffer_offset,0);read(dd,$buf,$buffer_len);

$sound_flags='';
$speedup=0;

# resample
$tmpfile="tmp-resample-bank${bank_id}_offset${buffer_offset}.pcm";
unlink($tmpfile);
open(oo,"|ffmpeg -v 0 -f s16le -ar $sound_sample_rate -ac 1 -i - -ar 48000 -ac 1 -f s16le -y $tmpfile");
binmode(oo);
print oo $buf;
close(oo);

$resampled=read_file($tmpfile);
$resampled_size=-s($tmpfile);
if($resampled_size<500 || ($resampled_size&1)){die "We found broken sound!!! We got $resampled_size, value must be >500 bytes and aligned to 16 bits";}
unlink($tmpfile);
$samples_count=length($resampled)/2;


print srt get_srt_line_samples($outsamlpos,$outsamlpos+$samples_count,"$ourfilename ($package_name:$buffer_offset:$buffer_len)$sound_flags",$srtnum++);
print STDERR "Written $ourfilename ($package_name:$buffer_offset:$buffer_len), atlas $atlas_id position: ".s2time($outsamlpos/48000)."\n";

print atlas $resampled;
$outsamlpos+=$samples_count;

if($use_gap){

print atlas $silence;
$outsamlpos+=length($silence)/2;
$samples_count=$gap_samples;

print srt get_srt_line_samples($outsamlpos,$outsamlpos+$samples_count,"IS_GAP",$srtnum++);

print atlas $gap_data;
$outsamlpos+=$gap_samples;
print atlas $silence;
$outsamlpos+=length($silence)/2;
} else {

# spit out 5 seconds of silence
print atlas "\x00" x (48000 * 2 * 5);
$outsamlpos+=48000*5;;

}

}


close(srt);
close(atlas);


sub get_srt_line_samples{
my($st,$en,$text,$num)=@_;
return(get_str_line($st/48000,$en/48000,$text,$num));
}


sub get_str_line{
my($st,$en,$text,$num)=@_;
my $timestart=s2srt($st);
my $timeend=s2srt($en);
chomp($text);
return("$num\n$timestart --> $timeend\n$text\n\n");
}


