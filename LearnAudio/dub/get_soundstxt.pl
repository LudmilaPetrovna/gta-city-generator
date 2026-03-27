use File::Slurp;
use File::Path qw(make_path remove_tree);
use File::Basename;
use Data::Dumper;

# Утилита, которая создает файл sounds.txt, который является индексом для всех звуков игры, чтобы каждый раз не парсить BankLkup.dat

# CONFIG

my $audio_root='/dev/shm/t/gta/Grand Theft Auto - San Andreas/audio';

# CODE

my $paks=read_file($audio_root.'/CONFIG/PakFiles.dat');
my $look=read_file($audio_root.'/CONFIG/BankLkup.dat');
my $bank_count=length($look)/12;
my $q;
for($q=0;$q<$bank_count;$q++){
my($package_id,$null,$bank_offset,$bank_size)=unpack("CA3II",substr($look,$q*12,12));
if($null ne "\xCC\xCC\xCC"){die "Paddings usually 0xCCCCCC! You have very strange file!";}
push(@banks,[$q,$package_id,$bank_offset,$bank_size]);
}

my $cur_package="";
foreach $bank(@banks){
($bank_id,$package_id,$bank_offset,$bank_size)=@{$bank};
$package_name=unpack("Z52",substr($paks,$package_id*52,52));

if($cur_package ne $package_name){
$cur_package=$package_name;
$modloader_bank_start=$bank_id;
#print "switching to package $cur_package\n";
close(dd);
open(dd,$audio_root.'/SFX/'.$package_name) or die $!;
binmode(dd);
}

seek(dd,$bank_offset,0);
if(read(dd,$buf,4)!=4){
die "Can't read bank $bank_id in $package_name!";
}

($num_sounds,$padding)=unpack("SS",$buf);
#print "Found $num_sounds sounds\n";
if($num_sounds>400){die "Num sounds is $num_sounds, must not be more than 400!";}
if($num_sounds <1 ){die "Num sounds is $num_sounds, must not be less than 1!";}
if($padding!=0){die "Padding not 0! This is not error, but very strange!";}
read(dd,$buf,12*$num_sounds);

@sounds=();
#print "[$bank_id,$package_name,$bank_offset,$bank_size,$buffer_offset,0,$loop_offset,$sample_rate,$headroom,$ourfilename,$modloader]\n";
for($q=0;$q<$num_sounds;$q++){
($buffer_offset,$loop_offset,$sample_rate,$headroom)=unpack("IiSs",substr($buf,$q*12,12));
$ourfilename=sprintf("sound_sfx/%s/bank%d/sound_%04d.wav",$package_name,$bank_id,$q);
$modloader=sprintf("audio/%s/Bank_%d/Sound_%04d.wav",$package_name,$bank_id-$modloader_bank_start+1,$q+1);
$sounds[$q]=[$bank_id,$package_name,$bank_offset,$bank_size,$buffer_offset,0,$loop_offset,$sample_rate,$headroom,$ourfilename,$modloader,$q];
}

# calc len of sound
for($q=0;$q<$num_sounds;$q++){
$buffer_offset=$sounds[$q]->[4];
$next_offset=($q==($num_sounds-1)?$bank_size:$sounds[$q+1]->[4]);
$buf_len=$next_offset-$buffer_offset; # in bytes
$buffer_offset+=$bank_offset+4+400*12;
if($buf_len&1){die "Buffer size must be aligned to 16 bits!";}
if($buf_len<0){die "Buffer size must not be negative!";}
$sounds[$q]->[4]=$buffer_offset;
$sounds[$q]->[5]=$buf_len;
}

push(@res,@sounds);
}

write_file("sounds.txt",join("",map{join("\t|",@{$_})."\n"}@res));
