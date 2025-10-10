use JSON;
use File::Slurp;
use Data::Dumper;

$source=$ARGV[0]||"Alhambra.cs";

$db=decode_json(read_file("sa.json"));
$codeparam=decode_json(read_file("codeparam.pl"));
$cmds=$db->{extensions}->[0]->{commands};
$cleo=$db->{extensions}->[1]->{commands};

%params=();
%names=();
%opcode_names=();
%parameters_count=();
%is_nop=();

foreach $opcode(map{@{$_}}($cmds,$cleo)){
$id=hex($opcode->{id});
$opcode_name=$opcode->{id}.'_'.$opcode->{name};
@names=map{lc($_->{name})}@{$opcode->{input}};
@types=map{lc($_->{type})}@{$opcode->{input}};
$params{$id}=[@types];
$names{$id}=[@names];
$parameters_count{$id}=$opcode->{num_params};
$opcode_names{$id}=$opcode_name;
if($opcode->{attrs}->{is_nop}){
$is_nop{$id}=1;
}
}

$file=read_file($source);
$file_size=length($file);


@ptypes=();
$ptypes[0]=["null",0];
$ptypes[1]=["int32",4,"int"];
$ptypes[2]=["offset",2,"int/float"];
$ptypes[3]=["index",2,"int/float"];
$ptypes[4]=["int8",1,"int"];
$ptypes[5]=["int16",2,"int"];
$ptypes[6]=["float",4,"float"];
$ptypes[7]=["offset",6,"int/float/array"];
$ptypes[8]=["index",6,"int/float/array"];
$ptypes[9]=["string8",8,"str"];
$ptypes[0xA]=["offset",2,"str"];
$ptypes[0xB]=["index",2,"str"];
$ptypes[0xC]=["offset",6,"str"];
$ptypes[0xD]=["index",6,"str"];
$ptypes[0xE]=["pstring",-1,"str"];
$ptypes[0xF]=["string16",16,"str"];
$ptypes[0x10]=["offset",2,"str"];
$ptypes[0x11]=["index",2,"str"];
$ptypes[0x12]=["offset",6,"str"];
$ptypes[0x13]=["index",6,"str"];


@possible=();
for($q=0;$q<$file_size;$q++){
$opcode=unpack("S",substr($file,$q,2))&0x7FFF;
$is_bad=0;

#printf("...try %.4x (%.4d): opcode %04X $parameters_count{$opcode}\n",$q,$q,$opcode);

if(!exists $params{$opcode}){$is_bad=1;next;}
if(exists $is_nop{$opcode}){$is_bad=1;next;}

$ppos=$q+2;
# try to decode params
@param_types=();
@param_values=();
$param_count=$parameters_count{$opcode};
#printf("...try %.4x (%.4d): opcode %04X $parameters_count{$opcode} found $param_count\n",$q,$q,$opcode);

if($opcode==0x004F || $opcode==0x0913){$param_count=888;}
if($opcode==0x05B6){$param_count=0;$ppos+=128;} #SAVE_STRING_TO_DEBUG_FILE

while($param_count){
$param_code=unpack("C",substr($file,$ppos++,1));
$param_type=$ptypes[$param_code]->[0];
$param_size=$ptypes[$param_code]->[1];
$param_value="UNKNOWN";
#print "param code: $param_code ($param_type)\n";
if($param_code>0x13){$is_bad=1;last;}
push(@param_types,$param_type);
if($param_code==0){last;}
if($param_size<0){
$param_size=unpack("C",substr($file,$ppos++,1));
}
if($param_type eq "float"){$param_value=unpack("f",substr($file,$ppos,4));$ppos+=4;}
if($param_type eq "int32"){$param_value=unpack("s",substr($file,$ppos,4));$ppos+=4;}
if($param_type eq "int16"){$param_value=unpack("s",substr($file,$ppos,2));$ppos+=2;}
if($param_type eq "int8" ){$param_value=unpack("c",substr($file,$ppos,1));$ppos+=1;}
if($param_type eq "pstring" ){$param_value='"'.substr($file,$ppos,$param_size).'"';$ppos+=$param_size;}
if($param_type eq "string8" ){$param_value='"'.substr($file,$ppos,8).'"';$ppos+=8;}
if($param_type eq "string16"){$param_value='"'.substr($file,$ppos,16).'"';$ppos+=16;}
push(@param_values,$param_value);

if($param_value eq "UNKNOWN"){
$ppos+=$param_size;
}

$param_count--;
}

if($is_bad){next;}

$params="params:";
for($e=0;$e<$parameters_count{$opcode};$e++){
$params.=($e?", ":"").$e."[$names{$opcode}->[$e]]:"."(".$param_types[$e].")".$param_values[$e];
}

$decoded=sprintf("%s %s",$opcode_names{$opcode},$params);
push(@possible,[$q,$ppos,$decoded]);

$q=$ppos-1;
}

@count_colors=qw/90 92 93 91 95 96 41 41 41 41 41 41 41 41 41 41 41 41 41 41 41 41 41 41 41/;

#print Dumper(\@possible);

#show hex
$offset=0;
$pc=0;
for($w=0;$w<18;$w++){
printf("\x1b[1;44;33m%.4x (%.4d)\x1b[0m: ",$offset,$offset);
$txt="";
for($q=0;$q<16;$q++){
$count=0;
$addr=$offset+$q;
for($e=0;$e<@possible;$e++){
if(!($possible[$e]->[0]>$addr || $possible[$e]->[1]-1<$addr)){$count++;}
}
$ch=ord(substr($file,$addr,1));
printf("\x1b[%dm%02X\x1b[0m ",$count_colors[$count],$ch);
$txt.=sprintf("\x1b[%dm%s",$count_colors[$count],$ch>=33&&$ch<0x7f?substr($file,$addr,1):'.');

if((($q+1)%4)==0){print "| ";}

}
print "$txt\x1b[0m\n";
for($q=0;$q<16;$q++){
$addr=$offset+$q;
for($e=0;$e<@possible;$e++){
if($possible[$e]->[0]==$addr){
print "".(" " x 13).("   "x$q).("  "x($q/4)).$possible[$e]->[2]."\n";
}
}
}

$offset+=16;
}




