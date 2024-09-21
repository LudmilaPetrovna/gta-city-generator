# reading package names for streaming data

open(dd,"StrmPaks.dat");
while(!eof(dd)){
read(dd,$buf,16);
$name=$buf;
$name=~s/\0.*//s;
push(@package_names,$name);
}
close(dd);

# reading pointers (not really need)

open(dd,"TrakLkup.dat");
# 1 байт - BYTE - ID файла
# 3 байта - зарезервированное место
# 4 байта - DWORD - Оффсет метаданных звукового файла
# 4 байта - DWORD - Непосредственно, длина звукового файла
# Обратите внимание на то, что второе значение ссылается именно на метаданные, а не на звуковой файл,
# а третье значение является уже длинной самого звукового файла. Поэтому, если вы хотите прочитать и
# метаданные, и сам звуковой файл, то прибавьте 8068 к длине звукового файла, а если только сам звуковой
# файл, то прибавьте 8068 к оффсету метаданных.

$sound_id=0;
while(!eof(dd)){
read(dd,$buf,12);
($pack_id,$null,$meta_offset,$audio_length)=unpack("CA3II",$buf);
print "Stream $sound_id: ".$package_names[$pack_id].": at $meta_offset $audio_length bytes\n";
$sound_id++;
}
close(dd);

die;

$src_file=$ARGV[0];

open(dd,$src_file) or die $!;
binmode(dd);

$offset=0;
$filesize=-s($src_file);
@offsets=();
while(!eof(dd) && $offset<$filesize){

printf("start at: %x, offset: %x\n",tell(dd),$offset);
seek(dd,$offset,0);


read(dd,$buf,8000); # skip beat info
read(dd,$buf,68);   # read actual header;

if(substr($buf,64,4) ne "\x01\x00\xCD\xCD"){
die "Wrong tail signature, probably broken or encrypted file!";
}

$offset+=8068;
for($q=0;$q<8;$q++){
($len,$samplerate)=unpack("II",substr($buf,$q*8,8));
printf("$q: vals %x %x\n",$len,$samplerate);
if($len==0xCDCDCDCD || $samplerate==0xCDCDCDCD){next;}

$next_chunk=tell(dd)+$len;
#printf("len: %x (next: %x), samplerate %d\n",$len,$next_chunk,$samplerate);
push(@offsets,[$offset,$len,$q]);
$offset+=$len;
#printf("now offset %x\n",$offset);

}

#printf("After we at: %x\n",tell(dd));

}




foreach(@offsets){
($offset,$len,$id)=@{$_};
$output_filename=$src_file."-$offset-$id.ogg";
print "Writing to $output_filename\n";
seek(dd,$offset,0);
read(dd,$buf,$len);
open(oo,">".$output_filename) or die "Can't write to $output_filename: $!";
binmode(oo);
print oo $buf;
close(oo);
}
