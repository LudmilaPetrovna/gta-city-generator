use File::Path qw(make_path remove_tree);


$src_root="/dev/shm/gta-micro/Clean";
$dst_root="/dev/shm/LearnAudio/Dst";
$tmp="Tmp";
$configdir="/audio/CONFIG/";



$out_samplerate=32000;
$out_channels=2;
$out_bitrate=64000;

$out_samplerate=8000;
$out_channels=2;
$out_bitrate=12000;


make_path($tmp);
remove_tree($dst_root);
make_path($dst_root);

# getting xor key
require "./xor.pl";
@xor=getXorKeyArray("../gta_sa_1.exe");


# reading package names for streaming data


open(dd,"$src_root/$configdir/StrmPaks.dat") or die $!;
while(!eof(dd)){
read(dd,$buf,16);
$name=$buf;
$name=~s/\0.*//s;
push(@package_names,$name);
}
close(dd);
print "We found ".@package_names." packages (".join(", ",@package_names).")\n";

# reading pointers

open(dd,"$src_root/$configdir/TrakLkup.dat");
# 1 байт - BYTE - ID файла
# 3 байта - зарезервированное место
# 4 байта - DWORD - Оффсет метаданных звукового файла
# 4 байта - DWORD - Непосредственно, длина звукового файла
# Обратите внимание на то, что второе значение ссылается именно на метаданные, а не на звуковой файл,
# а третье значение является уже длинной самого звукового файла. Поэтому, если вы хотите прочитать и
# метаданные, и сам звуковой файл, то прибавьте 8068 к длине звукового файла, а если только сам звуковой
# файл, то прибавьте 8068 к оффсету метаданных.

$sound_id=0;
@tracknum=();
while(!eof(dd)){
read(dd,$buf,12);
($pack_id,$null,$meta_offset,$audio_length)=unpack("CA3II",$buf);
print "Stream $sound_id: ".$package_names[$pack_id]." (track ".(++$tracknum[$pack_id])."): at $meta_offset $audio_length bytes\n";
$sound_id++;
push(@tracks,[$pack_id,$meta_offset,$audio_length]);
}
close(dd);


@outpos=map{0}@package_names;

foreach $track(@tracks){
($pack_id,$offset,$audio_length)=@{$track};
$src_file="$src_root/audio/streams/".$package_names[$pack_id];
#print STDERR "Repacking $src_file, $offset...\n";
open(dd,$src_file) or die $!;
binmode(dd);

seek(dd,$offset,0);

read(dd,$buf,8000); # skip beat info
$beats=dexor($buf,$offset);
read(dd,$buf,68);   # read actual header;
$header=dexor($buf,$offset+8000);
if(substr($header,64,4) ne "\x01\x00\xCD\xCD"){
die "Wrong tail signature, probably broken or encrypted file!";
}

$offset+=8068;
@offsets=();
for($q=0;$q<8;$q++){
($len,$samplerate)=unpack("II",substr($header,$q*8,8));
#printf("$q: vals %x %x\n",$len,$samplerate);
if($len==0xCDCDCDCD || $samplerate==0xCDCDCDCD){next;}

$next_chunk=tell(dd)+$len;
#printf("len: %x (next: %x), samplerate %d\n",$len,$next_chunk,$samplerate);
push(@offsets,[$offset,$len,$q]);
$offset+=$len;
#printf("now offset %x\n",$offset);
}
if(@offsets!=1){
die "Strange!";
}

foreach(@offsets){
($ogg_offset,$len,$id)=@{$_};
$output_filename="outtest-$offset-$id.ogg";
$output_filename="src-tmp.ogg";

$final_name="$tmp/$pack_id.$ogg_offset.$len.ogg";
if(!-e($final_name)){
print "Writing to $final_name...\n";
seek(dd,$ogg_offset,0);
read(dd,$buf,$len);
$buf=dexor($buf,$ogg_offset);
open(oo,">".$output_filename) or die "Can't write to $output_filename: $!";
binmode(oo);
print oo $buf;
close(oo);

# Simple repack
`ffmpeg -v 0 -nostdin -i "src-tmp.ogg" -af volume=3 -ac $out_channels -ar $out_samplerate -ab $out_bitrate -y $final_name`;

# Via codec2
#unlink("src-tmp.c2");
#`ffmpeg -v 0 -nostdin -i src-tmp.ogg -af volume=3 -y src-tmp.c2`;
#`ffmpeg -v 0 -nostdin -i src-tmp.c2 -vn -acodec libvorbis  -ac $out_channels -ar $out_samplerate -ab $out_bitrate -y $final_name`;


}
#ffmpeg -i outtest-43264070-0.ogg -ac 1 -ar 8000 -ab 8000 -y outtest-43264070-1.ogg
#ffmpeg -i outtest-43264070-0.ogg -ac 2 -ar 32000 -ab 32000 -y tmp-final.ogg

open(ii,$final_name) or die $!;
binmode(ii);
read(ii,$buf,-s(ii));
close(ii);

unlink($final_name);

push(@repacked,[$pack_id,$outpos[$pack_id],length($buf)]);

$outdir=$dst_root."/"."audio/streams/";
make_path($outdir);
$out_data=$beats;
#$out_data="\xFF\xFF\xFF\xFF\x00\x00\x00\x00" x 1000; # beats
$out_data.=pack("II",length($buf),$out_samplerate); # filesize and samplerate
$out_data.="\xCD" x 56; # padding?
$out_data.="\x01\x00\xCD\xCD"; # trailer???
$out_data.=$buf;

print STDERR "Writing to $outdir/$package_names[$pack_id] ".length($buf)." repacked bytes\n";

open(oo,">>".$outdir."/".$package_names[$pack_id]) or die $!;
binmode(oo);
print oo dexor($out_data,$outpos[$pack_id]);
#print oo $out_data;
close(oo);
$outpos[$pack_id]+=length($out_data);

}
close(dd);

}

# update lookup tables

make_path("$dst_root/$configdir");
open(oo,">$dst_root/$configdir/TrakLkup.dat");
foreach(@repacked){
($pack_id,$meta_offset,$audio_length)=@{$_};
print oo pack("CA3II",$pack_id,"\xCD\xCD\xCD",$meta_offset,$audio_length);
}
close(oo);


sub dexor{
my $data=shift;
my $koffset=shift;
my $doffset=0;
my $ret="";
my $chunk_in="";
my $chunk_out="";
my $chunk_len=0;
my $len=length($data);
my $q;
while($len>0){
$chunk_len=$len;
if($chunk_len>2048){
$chunk_len=2048;
}
$chunk_in=substr($data,$doffset,$chunk_len);
$chunk_out="";
for($q=0;$q<$chunk_len;$q++){
$chunk_out.=chr(ord(substr($chunk_in,$q,1))^$xor[($q+$koffset+$doffset)&0xF])
}
$ret.=$chunk_out;
$doffset+=$chunk_len;
$len-=$chunk_len;
}
return($ret);
}


