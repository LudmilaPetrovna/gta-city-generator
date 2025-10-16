use Data::Dumper;
use File::Slurp;

$file=read_file("main.scm");
$file_size=length($file);
$pos=0;
while($pos<$file_size){
if(substr($file,$pos,3) eq "\x02\x00\x01"){
$next_pos=unpack("I",substr($file,$pos+3,4));
printf("%08x: found chunk, next at %08x\n",$pos,$next_pos);
$pos=$next_pos;
next;
}
last;
}

printf("Main code at offset: 0x%08X (%d)\n",$pos,$pos);
write_file("main_raw.scm",substr($file,$pos));
