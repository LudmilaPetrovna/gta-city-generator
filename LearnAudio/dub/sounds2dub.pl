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
print "Adding $File::Find::name\r";
$trans_sounds->{"$bank_id-$sound_id"}=$File::Find::name;
}

}},$flac_repo.'/raw_trans_voice/'.$ARGV[0]);

print "File search done....\n\n";


my $lang='eng';
my %is_spanish=();
map{$is_spanish{$_}++}split(/\s+/i,$banks_spanish);

my $audio_root='/dev/shm/t/gta/Grand Theft Auto - San Andreas/audio';
my $samplerate=48000;
my $atlas_prefix='atlas_spa_';


@newlist=();
print STDERR "Parsing sounds list...\n";
open(sd,"sounds.txt");
while(<sd>){
chomp;
($bank_id,$package_name,$bank_offset,$bank_size,$buffer_offset,$buffer_len,$loop_offset,$sound_sample_rate,$headroom,$ourfilename,$modloader)=split(/\t\|/);
if($lang eq 'spa'){
if(!exists $is_spanish{$bank_id}){next;}
}
if($ourfilename=~/sound_sfx\/[^\/]+\/bank(\d+)\/sound_(\d+).wav/){
($fname_bank,$fname_sound)=($1|0,$2|0);
if($fname_bank!=$bank_id){die "Error in sounds database!";}
}
$transkey="${fname_bank}-${fname_sound}";
if(!exists $trans_sounds->{$transkey}){ #no translation!
next;
}
push(@newlist,[$bank_id,$package_name,$bank_offset,$bank_size,$buffer_offset,$buffer_len,$loop_offset,$sound_sample_rate,$headroom,$ourfilename,$modloader,$transkey]);
}
close(sd);


$cur_bank_id=-1;
$cur_package='';
foreach(@newlist){
($bank_id,$package_name,$bank_offset,$bank_size,$buffer_offset,$buffer_len,$loop_offset,$sound_sample_rate,$headroom,$ourfilename,$modloader,$transkey)=@{$_};
$trans_file=$trans_sounds->{$transkey};

$outfile="$flac_repo/dubbed_voices_wav/$modloader";
if(-s($outfile)){next;}

print "Generating $outfile...\n";

make_path(dirname($outfile));


if($cur_package ne $package_name){
close(dd);
open(dd,$audio_root.'/SFX/'.$package_name) or die $!;
binmode(dd);
$cur_package=$package_name;
}

seek(dd,$buffer_offset,0);read(dd,$buf,$buffer_len);

# resample
$tmpfile="tmp-resample-bank${bank_id}_offset${buffer_offset}.pcm";
unlink($tmpfile);
open(oo,"|ffmpeg -v 0 -f s16le -ar $sound_sample_rate -ac 1 -i - -ar 48000 -ac 1 -f s16le -y $tmpfile");
binmode(oo);
print oo $buf;
close(oo);

$resampled=read_file($tmpfile);
$resampled_size=-s($tmpfile);
$resampled_samples=$resampled_size/2;
if($resampled_size<500 || ($resampled_size&1)){die "We found broken sound!!! We got $resampled_size, value must be >500 bytes and aligned to 16 bits";}
unlink($tmpfile);

$tmpfile="tmp-translated-bank${bank_id}_offset${buffer_offset}.pcm";
print "$trans_file --> $tmpfile...\n";
`ffmpeg -nostdin -v 0 -i "$trans_file" -af aresample=48000,speechnorm -ar 48000 -ac 1 -f s16le -y "$tmpfile"`;
$translated_data=read_file($tmpfile);
$translated_samples=length($translated_data)/2;

if($resampled_samples<10 || $translated_samples<10){next;} #files may be broken
$speedup=$translated_samples/$resampled_samples;
if($speedup>1.5){$speedup=1.5;}
if($speedup<1){$speedup=1;}
if($speedup>1){ # speedup translation
print "SPEED IT UP $speedup\n";
`ffmpeg -nostdin -v 0 -i "$trans_file" -af aresample=48000,atempo=$speedup,speechnorm -ar 48000 -ac 1 -f s16le -y "$tmpfile"`;
$translated_data=read_file($tmpfile);
$translated_samples=length($translated_data)/2;
}
unlink($tmpfile);

$total_len=$translated_samples>$resampled_samples?$translated_samples:$resampled_samples;
if($resampled_samples<$total_len){
$pre=int(($total_len-$resampled_samples)/2);
$post=$total_len-$pre-$resampled_samples;
$resampled=("\x00" x ($pre*2)).$resampled.("\x00" x ($post*2));
$resampled_size=length($resampled);
$resampled_samples=$resampled_size/2;
}

if($translated_samples<$total_len){
$pre=int(($total_len-$translated_samples)/2);
$post=$total_len-$pre-$translated_samples;
$translated_data=("\x00" x ($pre*2)).$translated_data.("\x00" x ($post*2));
$translated_samples=length($translated_data)/2;
}

#$add=("\x00" x (48000*2*5));
$add='';

write_file("tmp-orig.pcm",$resampled.$add);
write_file("tmp-trans.pcm",$translated_data.$add);

$out_samplerate=22050;
if($sound_sample_rate>$out_samplerate){
$out_samplerate=$sound_sample_rate;
}

# freq overlay
`ffmpeg -nostdin -v 0 -f s16le -ar 48000 -ac 1 -i "tmp-orig.pcm" -f s16le -ar 48000 -ac 1 -i "tmp-trans.pcm" -filter_complex "[0:a]acrossover=200 1200:order=20th[low][r][ducked];[r]anullsink;[1:a]deesser=i=.33,speechnorm[vo];[low][ducked][vo]amix=inputs=3:duration=longest:dropout_transition=2:normalize=0:weights='.6 .7 .8',speechnorm[dub]" -map "[dub]" -ac 1 -ar $out_samplerate -map_metadata -1 -y "$outfile"`;

# classic dubbing
###`ffmpeg -nostdin -v 0 -f s16le -ar 48000 -ac 1 -i "tmp-orig.pcm" -f s16le -ar 48000 -ac 1 -i "tmp-trans.pcm" -filter_complex "[0:a][1:a]sidechaincompress=threshold=0.05:ratio=5:attack=1:release=50[ducked];[ducked][1:a]amix=inputs=2:duration=longest:dropout_transition=2:normalize=0:weights='1 0.8'[dub]" -map "[dub]" -ac 1 -ar $out_samplerate -map_metadata -1 -y "$outfile"`;

#if($count++>10){die;}

}



