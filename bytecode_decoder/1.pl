use JSON;
use File::Slurp;
use Data::Dumper;

$source=$ARGV[0]||"Alhambra.cs";

$db=decode_json(read_file("opcode_db_cleo.json"));
$codeparam=decode_json(read_file("opcode_db_my_operands.json"));
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
next;
}
if($opcode->{attrs}->{is_unsupported}){
next;
}

if($codeparam->[$id] eq 'u'){
$codeparam->[$id]='p'.$opcode->{num_params};
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

$codeparam->[4]="p1p1";
$codeparam->[0x600]="p7";
$codeparam->[0x172]="p1p1";

@possible=();
for($q=0;$q<$file_size;$q++){
$opcode=unpack("S",substr($file,$q,2))&0x7FFF;
$is_bad=0;

#printf("...try %.4x (%.4d): opcode %04X $parameters_count{$opcode}\n",$q,$q,$opcode);

printf("...try %.4x (%.4d): opcode %04X ($opcode_names{$opcode}) $parameters_count{$opcode} found $param_count, cp:$codeparam->[$opcode]\n",$q,$q,$opcode);

#f(!exists $params{$opcode}){$is_bad=1;next;}
#if(exists $is_nop{$opcode}){$is_bad=1;next;}
#if($opcode>3000){$is_bad=1;next;} # not defined
if($codeparam->[$opcode] eq "u"){$is_bad=1;next;} # unknown
#if($codeparam->[$opcode] eq "l"){$is_bad=1;next;} # low propability

$ppos=$q+2;
# try to decode params
@param_types=();
@param_values=();
$param_count=$parameters_count{$opcode};

#if($opcode==0x004F || $opcode==0x0913){$param_count=888;}
if($opcode==0x05B6){$param_count=0;$ppos+=128;} #SAVE_STRING_TO_DEBUG_FILE
$ops=$codeparam->[$opcode];
print "ops $ops\n";
$vararg=0;
while($ops=~/([a-z])(\d*)/g){
($pt,$pc)=($1,$2);
$value="UNKNOWN";
print "decoding operands $pt $pc\n";

if($pt eq "s"){
($adv,$value)=read_string($ppos,$pc);
if($adv==0){$is_bad=1;last;}
$ppos+=$adv;
push(@param_values,$value);
push(@param_types,"string");
next;
}
if($pt eq "v"){
$vararg=1;
$pt="i";
$pc=888;
}


if($pt=~/[piogb]/){

for($p=0;$p<$pc;$p++){
$param_code=unpack("C",substr($file,$ppos,1));
if($param_code==0){
if($vararg){last;}
$is_bad=1;
last;
}

($adv,$param_code,$value)=decode_operand($ppos,$ppos,$pt,$pc);
if($adv<=0){
$is_bad=1;
next;
}
$ppos+=$adv;
push(@param_types,$param_code);
push(@param_values,$value);
}
}
}

if($is_bad){next;}

$params="[$q..$ppos]";
for($e=0;$e<$parameters_count{$opcode};$e++){
$params.=($e?", ":"")."[$names{$opcode}->[$e]]="."(".$param_types[$e].")".$param_values[$e];
}

$decoded=sprintf("%s(%s) %s",$opcode_names{$opcode},$codeparam->[$opcode],$params);
push(@possible,[$q,$ppos,$decoded]);

$q=$ppos-1;
}

@count_colors=qw/90 92 93 91 95 96 41 41 41 41 41 41 41 41 41 41 41 41 41 41 41 41 41 41 41/;

#print Dumper(\@possible);

#show hex
$offset=0;
$pc=0;
for($w=0;$w<$file_size/16+1;$w++){
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






sub decode_operand{
my $offset=shift;
my $vararg=shift;
my $expect_type=shift;
my $expect_count=shift;
my $value="UNKNOWN";
my $is_bad=0;
my $ppos=$offset;
=pod
i - input values, mostly ints or offsets
o - output values (2, 3, 7, 8)
p - input pointer to var (no immediate value) (2, A, 0x10 / 3, b, 0x11 / 7, C, 0x12 / 8, D, 0x13)
g - input pointer to global variable (2, 7 and "int16")
b - input byte (maybe flag or var)
s - input string values, number=max string length (9..20)
=cut

if($expect_type eq "b"){
return $expect_count;
}

my $param_code=unpack("C",substr($file,$ppos++,1));
my $param_type=$ptypes[$param_code]->[0];
my $param_size=$ptypes[$param_code]->[1];
if($param_code>0x13){$is_bad=1;return 0;}
if($expect_type eq "o" && ($param_code!=2 && $param_code!=3 && $param_code!=7 && $param_code!=8)){$is_bad=1;return 0;}
if($expect_type eq "g" && ($param_code!=2 && $param_code!=7)){$is_bad=1;return 0;}

if($param_code==0){
if(!$vararg){$is_bad=1;}
}

if($param_type eq "float"){$value=unpack("f",substr($file,$ppos,4));$ppos+=4;}
if($param_type eq "int32"){$value=unpack("s",substr($file,$ppos,4));$ppos+=4;}
if($param_type eq "int16"){$value=unpack("s",substr($file,$ppos,2));$ppos+=2;}
if($param_type eq "int8" ){$value=unpack("c",substr($file,$ppos,1));$ppos+=1;}
if($ptypes[$param_code]->[2] eq "str"){
($adv,$value)=read_string($ppos-1,888);
if($adv==0){$is_bad=1;}
$ppos+=$adv-1;
}
push(@param_values,$value);

if($value eq "UNKNOWN"){
$ppos+=$param_size;
}

if($is_bad){
return 0;
}
return($ppos-$offset,$param_code,$value);
}





# valid for 9..0x13 parameter codes
sub read_string{
my $offset=shift;
my $want=shift;
my $adv=0;
my $str="";

my $pcode=ord(substr($file,$offset,1));$adv++;
if($pcode<9 || $pcode>0x13){
print STDERR "bad parameter code ($pcode), must be $pcode>=9&&$pcode<=0x13, can't decode string!\n";
return 0;
}
print "reading str at $offset, want:$want, pcode:$pcode\n";

if($pcode==9){$str=substr($file,$offset+$adv,8);$adv+=8;}
if($pcode==10){$str="g8str".unpack("S",substr($file,$offset+$adv,2));$adv+=2;}
if($pcode==11){$str="l8str".unpack("S",substr($file,$offset+$adv,2));$adv+=2;}
if($pcode==12){($gl_var,$arr_ind,$arr_size)=unpack("SSS",substr($file,$offset+$adv,6));$adv+=6;$str="g8strarr".$gl_var;}
if($pcode==13){($gl_var,$arr_ind,$arr_size)=unpack("SSS",substr($file,$offset+$adv,6));$adv+=6;$str="g8strarr".$gl_var;}
if($pcode==14){$str_size=ord(substr($file,$offset+$adv,1));$str=substr($file,$offset+$adv+1,$str_size);$adv+=$str_size+1;}
if($pcode==16){$str=substr($file,$offset+$adv,16);$adv+=16;}
if($pcode==17){$str="g16str".unpack("S",substr($file,$offset+$adv,2));$adv+=2;}
if($pcode==18){$str="l16str".unpack("S",substr($file,$offset+$adv,2));$adv+=2;}
if($pcode==19){($gl_var,$arr_ind,$arr_size)=unpack("SSS",substr($file,$offset+$adv,6));$adv+=6;$str="g16strarr".$gl_var;}
if($pcode==20){($gl_var,$arr_ind,$arr_size)=unpack("SSS",substr($file,$offset+$adv,6));$adv+=6;$str="g16strarr".$gl_var;}

$str=~s/\x00.*//s;

if(!is_string($str)){
$str=~s/[\x-\x1f\x7f-\xff]/./gs;
print STDERR "We got string \"$str\", but this is not text!\n";
return 0;
}

if(length($str)>$want){
print STDERR "We got bigger string than expected!\n";
return 0;
}

return($adv,"\"$str\"");
}



sub is_string{
my $str=shift;
if($str=~/^[\x20-\x7e]+$/s){return 1;}
}

sub is_text_string{
my $str=shift;
if($str=~/^[a-z0-9_]+$/si){return 1;}
}



