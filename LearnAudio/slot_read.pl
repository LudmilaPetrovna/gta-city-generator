use File::Slurp;
use Data::Dumper;
use JSON;

my $audio_root='/dev/shm/t/gta/Grand Theft Auto - San Andreas/audio';

open(ll,">list.txt");

$slots=read_file($audio_root.'/CONFIG/BankSlot.dat');
$slots_count_mustbe=45;
$slots_count_actual=unpack("S",substr($slots,0,2));
$slot_size=(length($slots)-2)/$slots_count_actual;
$slot_size_mustbe=4820;

$first_slot_offset_magic=20496;
$first_slot_size_magic=724416;

$payload_mustbe="\xFF\xFF\00\00".("\xFF\xFF\xFF\xFF\0\0\0\0\0\0\0\0" x 400);
#################^^^^^^^^ - signed int used sounds???
###################################^^^^^^^^^^^^^^^^ - descriptors for sounds in bank

print "Slots info:\n";
print "We have ".length($slots)." bytes in file\n";
print "Slots in file: $slots_count_actual, must be $slots_count_mustbe\n";
print "Slot size: $slot_size, must be $slot_size_mustbe bytes per slot\n";

for($q=0;$q<$slots_count_actual;$q++){
($buf_offset,$buf_size,$feet1,$feet2)=unpack("IIii",substr($slots,$slot_size*$q+2,16));
$payload=substr($slots,$slot_size*$q+2+16,$slot_size-16);
print "Raw slot $q: offset:$buf_offset, size:$buf_size, feets:$feet1,$feet2\n";
if($feet1!=-1 || $feet2!=-1){die "Feets must be -1\n";}
if($payload ne $payload_mustbe){die "wrong payload";}
push(@infos,[$buf_offset,$buf_size,$feet1,$feet2]);
}


$buf_offset_prev=$first_slot_offset_magic;
for($q=0;$q<$slots_count_actual;$q++){
($buf_offset,$buf_size,$feet1,$feet2)=@{$infos[$q]};
$next_offset=$infos[$q+1]->[0];
$diff_offset=$buf_offset-$buf_offset_prev;
$end_offset=$buf_offset+$buf_size;
print "Slot $q: offset: (+$diff_offset) $buf_offset .. $end_offset, size:$buf_size\n";

#if($diff_offset!=$buf_size){
#print "WARN: offsets and size mismatch!\n";
#}


$buf_offset_prev=$buf_offset;
}


# stage 2: read lookup table

$paks=read_file($audio_root.'/CONFIG/PakFiles.dat');
$lk=read_file($audio_root.'/CONFIG/BankLkup.dat');
@banks=();
$bank_count=length($lk)/12;
for($q=0;$q<$bank_count;$q++){
($package_id,$pad,$bank_offset,$bank_size)=unpack("CA3II",substr($lk,$q*12,12));
if($pad ne "\xCC\xCC\xCC"){die "Paddings usually 0xCCCCCC! You have very strange file!";}
push(@banks,[$q,$package_id,$bank_offset,$bank_size]);
}

# stage 3: find max sound length
$cur_package_id=-1;
foreach $bank(@banks){
($bank_id,$package_id,$bank_offset,$bank_size)=@{$bank};
$package_name=unpack("Z52",substr($paks,$package_id*52,52));


#print "Scanning package $package_name, bank $bank_id\n";

if($package_id!=$cur_package_id){
close(dd);
open(dd,$audio_root.'/SFX/'.$package_name) or die $!;
binmode(dd);
$bank_id_in_package=1;
$cur_package_id=$package_id;
}


$sound_id=0;
seek(dd,$bank_offset,0);
read(dd,$buf,4);
($num_sounds,$padding)=unpack("SS",$buf);
if($num_sounds>400){die "Num sounds is $num_sounds, must not be more than 400!";}
if($padding!=0){die "Padding not 0! This is not error, but very strange!";}

read(dd,$buf,12*400);

$maxsize=0;
@sounds=();
for($q=0;$q<$num_sounds;$q++){
($buffer_offset,$loop_offset,$sample_rate,$headroom)=unpack("IiSs",substr($buf,$q*12,12));
$modloader="audio/sfx/".uc($package_name)."/Bank_".$bank_id_in_package.'/Sound_'.$q.".wav";
print ll "$modloader\n";
$sounds[$q]=[$buffer_offset];
}
for($q=0;$q<$num_sounds;$q++){
$sounds[$q]->[1]=($q==($num_sounds-1)?$bank_size:$sounds[$q+1]->[0])-$sounds[$q]->[0]; # in bytes???
if($maxsize < $sounds[$q]->[1]){$maxsize=$sounds[$q]->[1];}
}
$bank->[4]=$maxsize;
$bank->[5]=$num_sounds;

print "bank:$bank_id, bank_size:$bank_size bytes, max sound: $maxsize bytes of $num_sounds sounds\n";
$bank_id_in_package++;
}

# calc possible id to fit in slots

$ref=[];
for($slot_id=0;$slot_id<$slots_count_actual;$slot_id++){
$slot=$infos[$slot_id];
($buf_offset,$buf_size)=@{$slot};
@fit_banks=();
@fit_sounds=();
$max_bank=0;
$max_sound=0;
foreach $bank(@banks){
if($buf_size>=$bank->[3]){push(@fit_banks,$bank->[0]);if($max_bank< $bank->[3]){$max_bank=$bank->[3];}}
if($buf_size==$bank->[3]){print "bank $bank->[0] perfect fit!\n";}
if($buf_size>=$bank->[4]){push(@fit_sounds,$bank->[0]);if($max_sound< $bank->[4]){$max_sound=$bank->[4];}}
if($buf_size==$bank->[4]){print "max sound of bank $bank->[0] perfect fit!\n";}

if($slot_id>=34 && $slot_id<=36){
if($buf_size+10000>=$bank->[3]){
print "$slot_id...fit bank $bank->[0] size $bank->[3] (diff ".($buf_size-$bank->[3]).") bytes\n";
}
if($buf_size+10000>=$bank->[4]){
print "$slot_id...fit sound of bank $bank->[0] size $bank->[4] (diff ".($buf_size-$bank->[4]).") bytes\n";
}
}

}

$banks_num=@fit_banks;
$sounds_num=@fit_sounds;

$ref->[$slot_id]->{banks}=[@fit_banks];
$ref->[$slot_id]->{sounds}=[@fit_sounds];
print "slot $slot_id: $buf_offset,$buf_size, fits $banks_num banks (max $max_bank), or $sounds_num sounds (max $max_sound)\n";
}
# create reference mapping
write_file("sfx_slots_map.json",encode_json($ref));

# find devider
for($dev=834560;$dev>=1;$dev--){
$ok=0;
for($slot_id=0;$slot_id<$slots_count_actual;$slot_id++){
($buf_offset,$buf_size)=@{$infos[$slot_id]};
#if(($buf_size%$dev)>0){$ok=0;last;}
if((($buf_size-2816)%$dev)==0){$ok++;}
}
if($ok>5){
print "Buffer sizes is multiple of $dev ($ok)\n";

}

}


