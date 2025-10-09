use JSON;
use File::Slurp;
use Data::Dumper;

$db=decode_json(read_file("sa.json"));
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

$file=read_file("Alhambra.cs");
$file_size=length($file);


@ptypes=();
$ptypes[0]=["null",0];
$ptypes[1]=["int32",4];
$ptypes[2]=["offset",2];
$ptypes[3]=["index",2];
$ptypes[4]=["int8",1];
$ptypes[5]=["int16",2];
$ptypes[6]=["float",4];
$ptypes[7]=["offset",6];
$ptypes[8]=["index",6];
$ptypes[9]=["string8",8];
$ptypes[0xA]=["offset",2];
$ptypes[0xB]=["index",2];
$ptypes[0xC]=["offset",6];
$ptypes[0xD]=["index",6];
$ptypes[0xE]=["pstring",-1];
$ptypes[0xF]=["string16",16];
$ptypes[0x10]=["offset",2];
$ptypes[0x11]=["index",2];
$ptypes[0x12]=["offset",6];
$ptypes[0x13]=["index",6];



for($q=0;$q<$file_size;$q++){
$opcode=unpack("S",substr($file,$q,2))&0x7FFF;
$is_bad=0;

#printf("...try %.4x (%.4d): opcode %04X $parameters_count{$opcode}\n",$q,$q,$opcode);

if(!exists $params{$opcode}){$is_bad=1;next;}
if(exists $is_nop{$opcode}){$is_bad=1;next;}


# try to decode params
@param_types=();
@param_values=();
$param_count=$parameters_count{$opcode};
#printf("...try %.4x (%.4d): opcode %04X $parameters_count{$opcode} found $param_count\n",$q,$q,$opcode);

if($opcode==0x004F || $opcode==0x0913){$param_count=888;}

$ppos=$q+2;
while($param_count){
$param_code=unpack("C",substr($file,$ppos++,1));
#print "param code: $param_code\n";
if($param_code>0x13){$is_bad=1;last;}
$param_type=$ptypes[$param_code]->[0];
$param_size=$ptypes[$param_code]->[1];
$param_value="UNKNOWN";
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

printf("%.4x (%.4d): %s %s\n",$q,$q,$opcode_names{$opcode},$params);

#$q=$ppos-1;
}
