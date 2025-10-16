use JSON;
use File::Slurp;
use Data::Dumper;

$source=$ARGV[0]||"Alhambra.cs";

$db=decode_json(read_file("opcode_db_cleo.json"));
$codeparam=decode_json(read_file("opcode_db_my_operands.json"));
$operators=decode_json(read_file("opcode_db_my_operators.json"));
$cmds=$db->{extensions}->[0]->{commands};
$cleo=$db->{extensions}->[1]->{commands};

%params=();
%names=();
%opcode_names=();
%opcode_names_sb=();
%parameters_count=();
%is_nop=();
@labels=();

foreach $opcode(map{@{$_}}($cmds,$cleo)){
$id=hex($opcode->{id});
$opcode_name=$opcode->{id}.'_'.$opcode->{name};
@names=map{lc($_->{name})}@{$opcode->{input}};
@types=map{lc($_->{type})}@{$opcode->{input}};
$params{$id}=[@types];
$names{$id}=[@names];
$parameters_count{$id}=$opcode->{num_params};
$opcode_names{$id}=$opcode_name;
$opcode_names_sb{$id}=lc($opcode->{name});
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
#$file_size=1280;

@ptypes=();
$ptypes[0]=["null",0];
$ptypes[1]=["int32",4,"int"];
$ptypes[2]=["offset",2,"global int/float"];
$ptypes[3]=["index",2,"local int/float"];
$ptypes[4]=["int8",1,"int"];
$ptypes[5]=["int16",2,"int"];
$ptypes[6]=["float",4,"float"];
$ptypes[7]=["offset",6,"global int/float/array"];
$ptypes[8]=["index",6,"local int/float/array"];
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
$last_good=0;
$aborted=0;

for($q=0;$q<$file_size && !$aborted;$q++){
$opcode_raw=unpack("S",substr($file,$q,2));
$opcode=$opcode_raw&0x7FFF;
$opcode_not=$opcode_raw&0x8000;
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

if($pt eq "b"){
# skip block
push(@param_values,"\"debug string\"");
push(@param_types,'block');
$ppos+=$pc;
next;
}


if($pt=~/[piogb]/){

for($p=0;$p<$pc;$p++){
$param_code=unpack("C",substr($file,$ppos,1));
printf("decode operand #%d at %08X (code:%d)\n",$p,$ppos,$param_code);
if($param_code==0){
if($vararg){
$ppos++;
last;
}
$is_bad=1;
last;
}

($adv,$param_code,$value)=decode_operand($ppos,$ppos,$pt,$pc);
print "advanced by $adv bytes with value $value, operand type $param_code\n";
if($adv<=0){
$is_bad=1;
next;
}
$ppos+=$adv;
push(@param_types,$ptypes[$param_code]->[2]);
push(@param_values,$value);
}
}

}

if($is_bad){next;}


# mark labels
if($opcode==2 || $opcode==0x4d || $opcode==0x50 || $opcode==0x707){
$labels[-$param_values[0]]=1;
$param_values[0]='@'.pretty_label(-$param_values[0]);
}
# add switches
if($opcode==0x0871 || $opcode==0x0872){
for($e=($opcode==0x0871?3:1);$e<18;$e+=2){
$labels[-$param_values[$e]]=1;
$param_values[$e]='@'.pretty_label(-$param_values[$e]);
}
}

$params="";
$params_sb="";
for($e=0;$e<@param_values;$e++){
$params.=($e?", ":"")."(".$param_types[$e].")".$param_values[$e];
$params_sb.=($e?" ":"").$param_values[$e];
}

$decoded=sprintf("%s %s",$opcode_names{$opcode},$params);
$opcode_not=$opcode_not?"not ":"";
$decoded_sb=sprintf("%04X: %s%s %s",$opcode_raw,$opcode_not,$opcode_names_sb{$opcode},$params_sb);
if($operators->[$opcode]){
$decoded=sprintf("%s %s%s%s",$opcode_names{$opcode},$param_values[0],$operators->[$opcode],$param_values[1]);
$decoded_sb=sprintf("%04X: $opcode_not %s %s %s",$opcode_raw,$param_values[0],$operators->[$opcode],$param_values[1]);
}




push(@possible,[$q,$ppos,$decoded,"$decoded_sb"]);

print "last good $last_good, now from $q\n";
if($q!=$last_good){
$aborted=1;
printf("Gap at %08x...%08x detected, aborted decompilation\n",$last_good,$q);
exit(1);
}


if($q>0x1E85){
#die;
}

$last_good=$ppos;

$q=$ppos-1;
}

@count_colors=qw/90 92 93 91 95 96 41 41 41 41 41 41 41 41 41 41 41 41 41 41 41 41 41 41 41/;

#die encode_json(\@labels);
#print Dumper(\@possible);

#show hex
$offset=0;
$pc=0;
for($w=0;$w<$file_size/1600+1;$w++){
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


open(oo,">Fly_decoded.txt");
print oo "{\$CLEO}\n\n";

for($e=0;$e<@possible;$e++){
$addr=$possible[$e]->[0];
if($labels[$addr]==1){
printf(oo "\n:%s // %d\n",pretty_label($addr),-$addr);
}
print oo "".$possible[$e]->[3]."\n";
}




sub decode_operand{
my $offset=shift;
my $vararg=shift;
my $expect_type=shift;
my $expect_count=shift;
my $value="_____";
my $value_pretty="_____";
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


if($param_code==1){$value=unpack("i",substr($file,$ppos,4));$ppos+=4;} # int
if($param_code==2){$value=unpack("S",substr($file,$ppos,2));$value_pretty='$'.pretty_gvars($value/4);$ppos+=2;} # gvar offset, so div by 4
if($param_code==3){$value=unpack("s",substr($file,$ppos,2));$value_pretty=$value.'@';$ppos+=2;} # lvar index
if($param_code==4){$value=unpack("c",substr($file,$ppos,1));$ppos+=1;} # byte
if($param_code==5){$value=unpack("s",substr($file,$ppos,2));$ppos+=2;} # short
if($param_code==6){$value=unpack("f",substr($file,$ppos,4));$value_pretty=pretty_float($value);$ppos+=4;} # float
if($param_code==7){
($gl_var,$arr_ind,$arr_size,$arr_type_global)=unpack("SSCC",substr($file,$ppos,6));
$arr_type=$arr_type_global&0x7f;
$arr_type_s="";
$arr_global=$arr_type_global>>7;
if($arr_type==1){$arr_type_s="f";}
if($arr_type==0){$arr_type_s="i";}
if($gl_var>=0x8000){
$gl_var/=4;
}
if($arr_ind>=0x8000){
$arr_ind/=4;
}

$value="\$".($gl_var)."\(".($arr_global?"\$".($arr_ind):$arr_ind.'@').",${arr_size}$arr_type_s\)";
$ppos+=6;
}
if($param_code==8){
($gl_var,$arr_ind,$arr_size,$arr_type_global)=unpack("SSCC",substr($file,$ppos,6));
$arr_type=$arr_type_global&7;
$arr_type_s="";
$arr_global=$arr_type_global&8;
$value="$gl_var\@";
if($arr_type==1){$arr_type_s="f";}
if($arr_type==0){$arr_type_s="i";}
#if($arr_global){
#$value="\$".($gl_var/4)."\(\$$arr_ind, ${arr_size}$arr_type_s\)";
#} else {
$value="$gl_var\@\($arr_ind\@, ${arr_size}$arr_type_s\)";
#}
$ppos+=6;
}

if($value_pretty eq "_____"){
$value_pretty=$value;
}

if($param_code>8){ # strings
($adv,$value)=read_string($ppos-1,888);
print "adv by string by $adv with $value\n";
$value_pretty=$value;
if($adv==0){$is_bad=1;}
$ppos+=$adv-1;
}

if($is_bad){
return 0;
}
return($ppos-$offset,$param_code,$value_pretty);
}





# valid for 9..0x13 parameter codes
sub read_string{
my $offset=shift;
my $want=shift;
my $adv=0;
my $str="";
my $sq=0;

my $pcode=ord(substr($file,$offset,1));$adv++;
if($pcode<9 || $pcode>0x13){
print STDERR "bad parameter code ($pcode), must be $pcode>=9&&$pcode<=0x13, can't decode string!\n";
return 0;
}
print "reading str at $offset, want:$want, pcode:$pcode\n";

if($pcode==9){$str=substr($file,$offset+$adv,8);$adv+=8;$sq=1;}
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

if($sq){ # single quote
$str="'$str'";
} else {
$str="\"$str\"";
}

return($adv,$str);
}



sub is_string{
my $str=shift;
if($str=~/^[\x20-\x7e]+$/s){return 1;}
}

sub is_text_string{
my $str=shift;
if($str=~/^[a-z0-9_]+$/si){return 1;}
}



sub pretty_gvars{
my $num=shift;
return $num;
if($num==2){return "player1";}
if($num==3){return "scplayer";}
if($num==10){return "gf_game_timer";}
if($num==11){return "Players_Group";}
if($num==16){return "game_timer";}
if($num==21){return "been_in_a_bmx";}
if($num==34){return "hours";}
if($num==35){return "minutes";}
if($num==40){return "weekday";}
if($num==43){return "main_visible_area";}
if($num==44){return "trigger_final_synd_mission";}
if($num==68){return "distance";}
if($num==69){return "player_x";}
if($num==70){return "player_y";}
if($num==71){return "player_z";}
if($num==72){return "heading";}
if($num==119){return "wasted_help";}
if($num==120){return "wanted_star_help";}
}

sub pretty_float{
my $f=shift;
my $o="".$f;
if($o=~/\.\d{6}/){
$o=sprintf("%.5g",$f);
}
if(index($o,'.')<0){
$o.='.0';
}
return($o);
}

sub pretty_label{
my $addr=shift;
return(sprintf("LABEL_%04X",$addr));
}
