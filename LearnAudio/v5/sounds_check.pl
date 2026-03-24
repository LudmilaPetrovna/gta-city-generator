use File::Find;
use File::Slurp;
use File::Path qw(make_path remove_tree);
use File::Basename;
use Data::Dumper;

require './libdub.pl';

my $out_dir='./';

my $lang='spa';

my $audio_root='/dev/shm/t/gta/Grand Theft Auto - San Andreas/audio';
my $atlas_len=7200;
my $samplerate=48000;
my $atlas_prefix='checker_'.$lang.'_';

$out_bitrate='128k';

my %is_spanish=();
map{$is_spanish{$_}++}split(/\s+/i,$banks_spanish);

my %is_no_speech=();
map{$is_no_speech{$_}++}split(/\s+/i,$banks_no_speech);
map{$is_no_speech{$_}++}split(/\s+/i,$banks_sfx_loops);


print STDERR "Indexing repo...\n";
$trans_sounds={};
find({no_chdir=>1,follow=>1,wanted=>sub{
if($File::Find::name=~/bank_(\d+)\/b(\d+)_s(\d+)_.+?flac/s){
my($bank_id,$bank_id2,$sound_id)=($1|0,$2|0,$3|0);
if($bank_id!=$bank_id2){die "Wrong repo layout";}
$trans_sounds->{"$bank_id-$sound_id"}=$File::Find::name;
}

}},$flac_repo.'/raw_trans_voice/spa_single');

print STDERR "Processing sounds...\n";


@ass_events=();

@newlist=();
print STDERR "Parsing sounds list...\n";
open(sd,"sounds.txt");
while(<sd>){
chomp;
($bank_id,$package_name,$bank_offset,$bank_size,$buffer_offset,$buffer_len,$loop_offset,$sound_sample_rate,$headroom,$ourfilename,$modloader)=split(/\t\|/);
if(exists $is_no_speech{$bank_id}){next;} # here no speech, skip it

if($lang eq 'spa' && !exists $is_spanish{$bank_id}){next;}
if($lang eq 'eng' && exists $is_spanish{$bank_id}){next;}

$transkey='none';
if($ourfilename=~/sound_sfx\/[^\/]+\/bank(\d+)\/sound_(\d+).wav/){
($fname_bank,$fname_sound)=($1|0,$2|0);
$transkey="${fname_bank}-${fname_sound}";
if($fname_bank!=$bank_id){die "Error in sounds database!";}
}
push(@newlist,[$bank_id,$package_name,$bank_offset,$bank_size,$buffer_offset,$buffer_len,$sound_sample_rate,$ourfilename,$modloader,$transkey]);

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
($bank_id,$package_name,$bank_offset,$bank_size,$buffer_offset,$buffer_len,$sound_sample_rate,$ourfilename,$modloader,$transkey)=@{$_};

$dubbedfile="$flac_repo/dubbed_voices_wav/$modloader";
print "Creating checker test for $ourfilename, trans:$trans_sounds->{$transkey}, dub:$dubbedfile...\n";

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
print STDERR "SWINTHING\n";
}
}

if($cur_atlas_id!=$atlas_id){
print "OPENING NEW FILE $out_dir/$atlas_prefix$atlas_id.ass\n";
$outsamlpos=0;
if(@ass_events){
flush_stream();
}
close(ass);close(atlas);
open(ass,">$out_dir/$atlas_prefix$atlas_id.ass");
open(atlas,"|ffmpeg -f s16le -ar 48000 -ac 1 -i - -acodec libopus -b:a $out_bitrate -y $out_dir/$atlas_prefix$atlas_id.mp4");
$cur_atlas_id=$atlas_id;

}

seek(dd,$buffer_offset,0);read(dd,$buf,$buffer_len);

$sound_flags='';
$speedup=0;

# resample
$tmpfile_orig="tmp-checker-orig-$transkey.pcm";
$tmpfile_trans="tmp-checker-trans-$transkey.pcm";
$tmpfile_dub="tmp-checker-dub-$transkey.pcm";

unlink($tmpfile_orig);
unlink($tmpfile_trans);
unlink($tmpfile_dub);

$dub_text="[no dubbed file]";
$dub_dur=0;
$trans_text="[no translated file]";
$trans_dur=0;

open(oo,"|ffmpeg -v 0 -f s16le -ar $sound_sample_rate -ac 1 -i - -af aresample=48000,speechnorm,speechnorm -ar 48000 -ac 1 -f s16le -y \"$tmpfile_orig\"");
binmode(oo);
print oo $buf;
close(oo);

$orig_dur=((-s($tmpfile_orig))/2);


if(-s($dubbedfile)){
`ffmpeg -nostdin -i "$dubbedfile" -af aresample=48000,speechnorm,speechnorm -ar 48000 -ac 1 -f s16le -y "$tmpfile_dub"`;
$dub_text=basename($dubbedfile);
$dub_dur=(-s($tmpfile_dub))/2;
}

if(defined $trans_sounds->{$transkey} && -s($trans_sounds->{$transkey})){
`ffmpeg -nostdin -i "$trans_sounds->{$transkey}" -af aresample=48000,speechnorm,speechnorm -ar 48000 -ac 1 -f s16le -y "$tmpfile_trans"`;
$trans_text=basename($trans_sounds->{$transkey});
$trans_dur=(-s($tmpfile_trans))/2;
}

print "We got durations $orig_dur $trans_dur $dub_dur\n";

$slide_samples=$dub_dur+$trans_dur+$orig_dur;
push_hilited_event($outsamlpos,$outsamlpos+$slide_samples,$outsamlpos,$outsamlpos+$orig_dur,"ORIGFILEOFF","ORIGFILEON",200,$ourfilename);
push_hilited_event($outsamlpos,$outsamlpos+$slide_samples,$outsamlpos+$orig_dur,$outsamlpos+$orig_dur+$trans_dur,"TRANSFILEOFF","TRANSFILEON",150,$trans_text);
push_hilited_event($outsamlpos,$outsamlpos+$slide_samples,$outsamlpos+$orig_dur+$trans_dur,$outsamlpos+$orig_dur+$trans_dur+$dub_dur,"DUBFILEOFF","DUBFILEON",50,$dub_text);

print atlas read_file($tmpfile_orig);
print "ok\n";
if($trans_dur){
print atlas read_file($tmpfile_trans);
}
if($dub_dur){
print atlas read_file($tmpfile_dub);
}


$outsamlpos+=$orig_dur+$trans_dur+$dub_dur;

unlink($tmpfile_orig);
unlink($tmpfile_trans);
unlink($tmpfile_dub);


if($count++>30){last;}

}

flush_stream();

sub push_hilited_event{
my($st,$en,$hst,$hen,$style1,$style2,$offset,$text)=@_;
$st/=48000;
$en/=48000;
$hst/=48000;
$hen/=48000;
my $ev_en;
if($hst-$st>0){
$ev_en=$hst>$en?$en:$hst;
$ev_en-=0.01;
if($ev_en<$st){$ev_en=$st;}
push(@ass_events,[$st,get_ssa_event($st,$ev_en,$style1,$offset,$text)]);
}
push(@ass_events,[$hst,get_ssa_event($hst,$hen,$style2,$offset,$text)]);
if($en>$hen){
push(@ass_events,[$hen,get_ssa_event($hen+.01,$en,$style1,$offset,$text)]);
}
}


sub flush_stream{

print ass get_ssa_header();
@ass_events=sort{$a->[0] <=> $b->[0]}@ass_events;
print ass map{$_->[1]}@ass_events;
@ass_events=();


close(ass);
close(atlas);


}

