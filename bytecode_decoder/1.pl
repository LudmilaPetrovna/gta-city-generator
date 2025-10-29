use JSON;
use File::Slurp;
use Data::Dumper;

%opstat=();

@ref_files=map{"scripts.img/decoded/$_"}grep{/\.scm\.cs$/}read_dir("scripts.img/decoded/");
push(@ref_files,'main_raw.cs');



$source=$ARGV[0]||"Alhambra.cs";
$out_opcodes=$source.".ops.txt";

$sb_enums=load_sb_enums();
$sb_enums_key=join("|",sort{length($b) <=> length($a)}keys %{$sb_enums});

$source_sb=$source;
$source_sb=~s/\.cs$/.txt/s;
$sb=read_file($source_sb);
$sb=unpretty_sb($sb);
@sbcode=split(/\n/,$sb);

open(out_op,'>'.$out_opcodes);

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

foreach $source(@ref_files){

@possible=();
$last_good=0;
$aborted=0;

$file=read_file($source);
$file_size=length($file);


for($q=0;$q<$file_size && !$aborted;$q++){
$opcode_raw=unpack("S",substr($file,$q,2));
$opcode=$opcode_raw&0x7FFF;
$opcode_not=$opcode_raw&0x8000;
$is_bad=0;

#printf("...try %.4x (%.4d): opcode %04X $parameters_count{$opcode}\n",$q,$q,$opcode);
printf("...try %.4x (%.4d), scm %.4x (scm dec:%d): opcode %04X ($opcode_names{$opcode}) $parameters_count{$opcode} found $param_count, cp:$codeparam->[$opcode]\n",$q,$q,$q+55976,$q+55976,$opcode);

#f(!exists $params{$opcode}){$is_bad=1;next;}
#if(exists $is_nop{$opcode}){$is_bad=1;next;}
#if($opcode>3000){$is_bad=1;next;} # not defined
if($codeparam->[$opcode] eq "u"){$is_bad=1;next;} # unknown
#if($codeparam->[$opcode] eq "l"){$is_bad=1;next;} # low propability

$ppos=$q+2;
# try to decode params
@param_types=();
@param_codes=();
@param_values=();
$param_count=$parameters_count{$opcode};

$ops=$codeparam->[$opcode];
#print "ops $ops\n";
$vararg=0;
while($ops=~/([a-z])(\d*)/g){
($pt,$pc)=($1,$2);
$value="UNKNOWN";
#print "decoding operands $pt $pc\n";
$param_code=unpack("C",substr($file,$ppos,1));

if($pt eq "s"){
($adv,$value)=read_string($ppos,$pc);
if($adv==0){$is_bad=1;last;}
$ppos+=$adv;
push(@param_values,$value);
push(@param_codes,$param_code);
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
push(@param_values,'"'.unpack("Z128",substr($file,$ppos,128)).'"');
push(@param_codes,$param_code);
push(@param_types,'block');
print Dumper(\@param_values);
$ppos+=$pc;
next;
}


if($pt=~/[piogb]/){

for($p=0;$p<$pc;$p++){
$param_code=unpack("C",substr($file,$ppos,1));
#printf("decode operand #%d at %08X (code:%d)\n",$p,$ppos,$param_code);
if($param_code==0){
if($vararg){
$ppos++;
last;
}
$is_bad=1;
last;
}

($adv,$param_code,$value)=decode_operand($ppos,$ppos,$pt,$pc);
#print "advanced by $adv bytes with value $value, operand type $param_code\n";
if($adv<=0){
$is_bad=1;
next;
}
$ppos+=$adv;
push(@param_types,$ptypes[$param_code]->[2]);
push(@param_codes,$param_code);
push(@param_values,$value);
}
}

}

if($is_bad){next;}


# mark labels
if($opcode==2 || $opcode==0x4d || $opcode==0x50 || $opcode==0x707){
$addr=abs($param_values[0]);
$labels[$addr]=1;
$param_values[0]='@'.pretty_label($addr);
}
# add switches
if($opcode==0x0871 || $opcode==0x0872){
for($e=($opcode==0x0871?3:1);$e<18;$e+=2){
$addr=abs($param_values[$e]);
$labels[$addr]=1;
$param_values[$e]='@'.pretty_label($addr);
}
}

$params="";
$params_sb="";
for($e=0;$e<@param_values;$e++){
$opstat{$opcode}{$e}{$param_codes[$e]}{$param_values[$e]}=$param_values[$e];
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

$decoded_sb=~s/^([\da-fA-F]{4}:) +/$1 /gs;
$decoded_sb=~s/^([\da-fA-F]{4}: not) +/$1 /gs;

$last_el=@possible;

push(@possible,[$q,$ppos,$decoded,"$decoded_sb"]);


#print "last good $last_good, now from $q\n";
if($q!=$last_good){
$aborted=1;
printf("Gap at %08x...%08x detected, aborted decompilation\n",$last_good,$q);
#exit(1);
}

$cmp1=$decoded_sb;
$cmp2=$sbcode[$last_el];
$cmp1=~s/(\d+\.\d+)/111.111/gs;
$cmp2=~s/(\d+\.\d+)/111.111/gs;

$cmp1=~s/(skip_cutscene_start_internal|goto|gosub|goto_if_false|switch_start|switch_continued [\-\d]+).+/$1/s;
$cmp2=~s/(skip_cutscene_start_internal|goto|gosub|goto_if_false|switch_start|switch_continued [\-\d]+).+/$1/s;

$cmp_pass=0;
if($decoded_sb=~/0007: 237/){$cmp_pass=1;}
if($decoded_sb=~/\de\+\d+\.\d/){$cmp_pass=1;}
if($decoded_sb=~/\d\.\d+e\-\d/){$cmp_pass=1;}
if($decoded_sb=~/10117 = 999.0/){$cmp_pass=1;}
if($decoded_sb=~/is_area_occupied 2333.48 2439.58/){$cmp_pass=1;}
if($decoded_sb=~/create_car_generator 1175.0 1366.48 10.1203 282.226/){$cmp_pass=1;}
if($decoded_sb=~/add_stunt_jump 2770.21 -1177.48 70.7527 2.344 1.99/){$cmp_pass=1;}

if($cmp1 ne $cmp2 && !$cmp_pass && 0){
print "our: |$decoded_sb|\n";
print "sb : |$sbcode[$last_el]|\n======";
for($q=0;$q<80;$q++){
$ch1=substr($decoded_sb,$q,1);
$ch2=substr($sbcode[$last_el],$q,1);
print "".($ch1 eq $ch2?" ":"+");
}
print "\n";
exit;
}



#printf(out_op "%04X\n",$opcode_raw);

if($q>0x1E85){
#die;
}

$last_good=$ppos;

$q=$ppos-1;
}

close(out_op);
}

#print Dumper(\%opstat);
write_file("opcode_db_my_opstat.json",encode_json(\%opstat));

@count_colors=qw/90 92 93 91 95 96 41 41 41 41 41 41 41 41 41 41 41 41 41 41 41 41 41 41 41/;

#die encode_json(\@labels);
#print Dumper(\@possible);

#show hex
$offset=0;
$pc=0;
$posp=0;
for($w=0;$w<$file_size/16+1;$w++){
printf("\x1b[1;44;33m%.4x (%.4d)\x1b[0m: ",$offset,$offset);
$txt="";
$addr_end=$offset+$w;
for($q=0;$q<16;$q++){
$count=0;
$addr=$offset+$q;
for($e=$posp;$e<@possible;$e++){
if($possible[$e]->[0]>$addr_end){last;}
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
for($e=$posp;$e<@possible;$e++){
if($possible[$e]->[1]<$addr || $possible[$e]->[0]>$addr){last;}
if($possible[$e]->[0]==$addr){
print "".(" " x 13).("   "x$q).("  "x($q/4)).$possible[$e]->[2]."\n";
$posp=$e;
last;
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
my $value_raw="_____";
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
printf("%08X: param code: %02x (%d)\n",$ppos-1,$param_code,$param_code);

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

if($arr_type>3){die "Wrong array type!";}
$arr_type_s="";
$arr_global=$arr_type_global&0x80;
if($arr_type==1){$arr_type_s="f";}
if($arr_type==0){$arr_type_s="i";}
if($arr_type==2){$arr_type_s="s";}
if($arr_type==3){$arr_type_s="v";}

if($arr_global){
$idx='$'.($arr_ind/4);
} else {
$idx=$arr_ind.'@';
}

$gl_var/=4;

$value_raw="p7($gl_var,$arr_ind,$arr_size,$arr_type_global),$arr_type,$arr_global";
$value_pretty="\$".($gl_var)."\(".$idx.",${arr_size}$arr_type_s\)";
$ppos+=6;
}

if($param_code==8){
($gl_var,$arr_ind,$arr_size,$arr_type_global)=unpack("SSCC",substr($file,$ppos,6));
$arr_type=$arr_type_global&0x7f;
if($arr_type>3){die "Wrong array type!";}
$arr_type_s="";
$arr_global=$arr_type_global&0x80;
if($arr_type==1){$arr_type_s="f";}
if($arr_type==0){$arr_type_s="i";}
if($arr_type==2){$arr_type_s="s";}
if($arr_type==3){$arr_type_s="v";}

if($arr_global){
$idx='$'.($arr_ind/4);
} else {
$idx=$arr_ind.'@';
}

$value_raw="p8($gl_var,$arr_ind,$arr_size,$arr_type_global),$arr_type,$arr_global";
$value_pretty="$gl_var\@\($idx,${arr_size}$arr_type_s\)";
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
print "Decoded value for $param_code: $value_raw (raw) = $value_pretty (pretty)\n";

return($ppos-$offset,$param_code,$value_pretty);
}





# valid for 9..0x13 parameter codes
sub read_string{
my $offset=shift;
my $want=shift;
my $adv=0;
my $sq=0;
my $is_ptr=0;
my $value='';
my $value_raw='';
my $value_pretty='';

my $pcode=ord(substr($file,$offset,1));$adv++;
if($pcode<9 || $pcode>0x13){
print STDERR "bad parameter code ($pcode), must be $pcode>=9&&$pcode<=0x13, can't decode string!\n";
return 0;
}
print "reading str at $offset, want:$want, pcode:$pcode\n";

if($pcode==9){$value_raw=substr($file,$offset+$adv,8);$adv+=8;$sq=1;}
if($pcode==10){
$value_raw=unpack("S",substr($file,$offset+$adv,2));
$value_pretty="s\$".($value_raw/4);
$adv+=2;$is_ptr=1;
}

if($pcode==11){
$value_raw=unpack("S",substr($file,$offset+$adv,2));
$value_pretty=$value_raw.'@s';

$adv+=2;$is_ptr=1;

}
if($pcode==12){
($gl_var,$arr_ind,$arr_size,$arr_type_global)=unpack("SSCC",substr($file,$offset+$adv,6));
$arr_type=$arr_type_global&0x7f;
if($arr_type>3){die "Wrong array type!";}
$arr_type_s="";
$arr_global=$arr_type_global&0x80;

if($arr_type==2){$arr_type_s="s";}
if($arr_type==3){$arr_type_s="v";}


if($arr_global){
$idx='$'.($arr_ind/4);
} else {
$idx=$arr_ind.'@';
}

$adv+=6;
$value_raw="g8strarr(($gl_var,$arr_ind,$arr_size,$arr_type_global)$arr_type,$arr_global)";$is_ptr=1;
$value_pretty="\$".($gl_var/4)."($idx".','.$arr_size.$arr_type_s.')';$is_ptr=1;


}
if($pcode==13){
($gl_var,$arr_ind,$arr_size,$arr_type_global)=unpack("SSCC",substr($file,$offset+$adv,6));

$arr_type=$arr_type_global&0x7f;
if($arr_type>3){die "Wrong array type!";}
$arr_type_s="";
$arr_global=$arr_type_global&0x80;


if($arr_type==2){$arr_type_s="s";}
if($arr_type==3){$arr_type_s="v";}


if($arr_global){
$idx='$'.($arr_ind/4);
} else {
$idx=$arr_ind.'@';
}

$value_raw="g8strarr(($gl_var,$arr_ind,$arr_size,$arr_type_global)$arr_type,$arr_global)";
$value_pretty=($gl_var).'@('.$idx.','.$arr_size.$arr_type_s.')';

$adv+=6;$is_ptr=1;


}
if($pcode==14){$str_size=ord(substr($file,$offset+$adv,1));$value_raw=substr($file,$offset+$adv+1,$str_size);$adv+=$str_size+1;}
if($pcode==15){$value_raw=substr($file,$offset+$adv,16);$adv+=16;$sq=1;}
if($pcode==16){$value_raw=unpack("S",substr($file,$offset+$adv,2));$value_pretty='v$'.($value_raw/4);$adv+=2;$is_ptr=1;}
if($pcode==17){$value_raw="l16str".unpack("S",substr($file,$offset+$adv,2));$adv+=2;$is_ptr=1;}
if($pcode==18){
($gl_var,$arr_ind,$arr_size,$arr_type_global)=unpack("SSCC",substr($file,$offset+$adv,6));
$arr_type=$arr_type_global&0x7f;
$arr_type_s="";
$arr_global=$arr_type_global>>7;
if($arr_type==2){$arr_type_s="s";}
if($arr_type==3){$arr_type_s="v";}

if($arr_global){
$idx='$'.($arr_ind/4);
} else {
$idx=$arr_ind.'@';
}


$adv+=6;
$value_raw="g8strarr(($gl_var,$arr_ind,$arr_size,$arr_type_global)$arr_type,$arr_global)";$is_ptr=1;
$value_pretty="\$".($gl_var/4)."(".$idx.','.$arr_size.$arr_type_s.')';$is_ptr=1;
}
if($pcode==19){($gl_var,$arr_ind,$arr_size)=unpack("SSS",substr($file,$offset+$adv,6));$adv+=6;$value_raw="g16strarr($gl_var,$arr_ind,$arr_size)";$is_ptr=1;}

if(!$is_ptr){
$value_pretty=$value_raw;
$value_pretty=~s/\x00.*//s;



if(!is_string($value_pretty)){
$value_pretty=~s/[\x-\x1f\x7f-\xff]/./gs;
print STDERR "We got string \"$value_pretty\", but this is not text!\n";
return 0;
}

if(length($value_raw)>$want){
print STDERR "We got bigger string than expected!\n";
return 0;
}

if($sq){ # single quote
$value_pretty="'$value_pretty'";
} else {
$value_pretty="\"$value_pretty\"";
}

$value_raw=$value_raw;
$value_raw=~s/([^ -\x7e])/sprintf("[%02X]",ord($1))/egs;

}

if($value_pretty eq ""){
$value_pretty="notform";
}

print "Decoded string type $pcode: $value_raw (raw) = $value_pretty (pretty)\n";

return($adv,$value_pretty);
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
my $o=sprintf("%g",$f);;
if(abs($f)<0.00001){return "0.0";}
if($o=~/\.\d{6}/){
$o=sprintf("%.4f",$f);
}
if(index($o,'.')<0){
$o.='.0';
}
return($o);
}

sub pretty_label{
my $addr=shift;
return(sprintf("Label%06X",$addr));
return(sprintf("LABEL_%04X",$addr));
}


sub unpretty_sb{
my $file=shift;
$file=~s/\r//gs; # remove windows newlines
$file=~s/\{\$CLEO \.[a-z]+\}\s+//sg; # remove CLEO header
$file=~s/^(\:Label)([\da-fA-F]+)/uc($1).sprintf("_%04X \/\/ %d",hex($2),-hex($2))/egm; # format Labels
$file=~s/(goto|goto_if_false)\s+\@Label([\da-fA-F]+)/$1." ".-hex($2)/egm; # format goto
$file=~s/ \{[a-z_\d]+\}//gsi; # remove named arguments
$file=~s/ True/ 1/gs;
$file=~s/ False/ 0/gs;
$file=~s/^(00D6: if)\s*$/$1 0/gm;
$file=~s/^([\da-fA-F]{4}:)\s+(not )?/$1 $2/gm; # fix indent
$file=~s/(IS_FLOAT_LVAR_GREATER_OR_EQUAL_TO_FLOAT_LVAR|IS_FLOAT_VAR_GREATER_OR_EQUAL_TO_FLOAT_LVAR|IS_FLOAT_LVAR_GREATER_OR_EQUAL_TO_FLOAT_VAR|IS_FLOAT_VAR_GREATER_OR_EQUAL_TO_FLOAT_VAR|IS_INT_LVAR_GREATER_OR_EQUAL_TO_INT_LVAR|IS_FLOAT_LVAR_GREATER_OR_EQUAL_TO_NUMBER|IS_NUMBER_GREATER_OR_EQUAL_TO_FLOAT_LVAR|IS_INT_LVAR_GREATER_OR_EQUAL_TO_CONSTANT|IS_CONSTANT_GREATER_OR_EQUAL_TO_INT_LVAR|IS_LVAR_TEXT_LABEL16_EQUAL_TO_TEXT_LABEL|IS_INT_VAR_GREATER_OR_EQUAL_TO_INT_LVAR|IS_INT_LVAR_GREATER_OR_EQUAL_TO_INT_VAR|IS_FLOAT_VAR_GREATER_OR_EQUAL_TO_NUMBER|IS_NUMBER_GREATER_OR_EQUAL_TO_FLOAT_VAR|IS_INT_VAR_GREATER_OR_EQUAL_TO_CONSTANT|IS_CONSTANT_GREATER_OR_EQUAL_TO_INT_VAR|IS_VAR_TEXT_LABEL16_EQUAL_TO_TEXT_LABEL|IS_INT_LVAR_GREATER_OR_EQUAL_TO_NUMBER|IS_NUMBER_GREATER_OR_EQUAL_TO_INT_LVAR|IS_INT_VAR_GREATER_OR_EQUAL_TO_INT_VAR|IS_LVAR_TEXT_LABEL_EQUAL_TO_TEXT_LABEL|IS_FLOAT_LVAR_GREATER_THAN_FLOAT_LVAR|IS_INT_VAR_GREATER_OR_EQUAL_TO_NUMBER|IS_NUMBER_GREATER_OR_EQUAL_TO_INT_VAR|IS_VAR_TEXT_LABEL_EQUAL_TO_TEXT_LABEL|IS_FLOAT_VAR_GREATER_THAN_FLOAT_LVAR|IS_FLOAT_LVAR_GREATER_THAN_FLOAT_VAR|SUB_TIMED_FLOAT_LVAR_FROM_FLOAT_LVAR|IS_FLOAT_VAR_GREATER_THAN_FLOAT_VAR|SUB_TIMED_FLOAT_VAR_FROM_FLOAT_LVAR|SUB_TIMED_FLOAT_LVAR_FROM_FLOAT_VAR|ADD_TIMED_FLOAT_LVAR_TO_FLOAT_LVAR|SUB_TIMED_FLOAT_VAR_FROM_FLOAT_VAR|IS_INT_LVAR_GREATER_THAN_INT_LVAR|IS_FLOAT_LVAR_GREATER_THAN_NUMBER|IS_NUMBER_GREATER_THAN_FLOAT_LVAR|IS_FLOAT_LVAR_EQUAL_TO_FLOAT_LVAR|ADD_TIMED_FLOAT_VAR_TO_FLOAT_LVAR|ADD_TIMED_FLOAT_LVAR_TO_FLOAT_VAR|IS_INT_LVAR_GREATER_THAN_CONSTANT|IS_CONSTANT_GREATER_THAN_INT_LVAR|IS_INT_VAR_GREATER_THAN_INT_LVAR|IS_INT_LVAR_GREATER_THAN_INT_VAR|IS_FLOAT_VAR_GREATER_THAN_NUMBER|IS_NUMBER_GREATER_THAN_FLOAT_VAR|IS_FLOAT_VAR_EQUAL_TO_FLOAT_LVAR|ADD_TIMED_FLOAT_VAR_TO_FLOAT_VAR|IS_INT_VAR_GREATER_THAN_CONSTANT|IS_CONSTANT_GREATER_THAN_INT_VAR|IS_FLOAT_LVAR_EQUAL_TO_FLOAT_VAR|IS_INT_LVAR_GREATER_THAN_NUMBER|IS_NUMBER_GREATER_THAN_INT_LVAR|IS_INT_VAR_GREATER_THAN_INT_VAR|IS_FLOAT_VAR_EQUAL_TO_FLOAT_VAR|IS_INT_VAR_GREATER_THAN_NUMBER|IS_NUMBER_GREATER_THAN_INT_VAR|SUB_FLOAT_LVAR_FROM_FLOAT_LVAR|IS_INT_LVAR_EQUAL_TO_INT_LVAR|IS_FLOAT_LVAR_EQUAL_TO_NUMBER|SUB_FLOAT_VAR_FROM_FLOAT_LVAR|SUB_FLOAT_LVAR_FROM_FLOAT_VAR|MULT_FLOAT_LVAR_BY_FLOAT_LVAR|SUB_TIMED_VAL_FROM_FLOAT_LVAR|IS_INT_LVAR_EQUAL_TO_CONSTANT|IS_INT_VAR_EQUAL_TO_INT_LVAR|IS_FLOAT_VAR_EQUAL_TO_NUMBER|ADD_FLOAT_LVAR_TO_FLOAT_LVAR|SUB_FLOAT_VAR_FROM_FLOAT_VAR|MULT_FLOAT_VAR_BY_FLOAT_LVAR|MULT_FLOAT_LVAR_BY_FLOAT_VAR|DIV_FLOAT_LVAR_BY_FLOAT_LVAR|SUB_TIMED_VAL_FROM_FLOAT_VAR|SET_LVAR_FLOAT_TO_LVAR_FLOAT|IS_INT_VAR_EQUAL_TO_CONSTANT|IS_INT_LVAR_EQUAL_TO_INT_VAR|IS_INT_LVAR_EQUAL_TO_NUMBER|IS_INT_VAR_EQUAL_TO_INT_VAR|ADD_FLOAT_VAR_TO_FLOAT_LVAR|ADD_FLOAT_LVAR_TO_FLOAT_VAR|MULT_FLOAT_VAR_BY_FLOAT_VAR|DIV_FLOAT_VAR_BY_FLOAT_LVAR|DIV_FLOAT_LVAR_BY_FLOAT_VAR|ADD_TIMED_VAL_TO_FLOAT_LVAR|SET_VAR_FLOAT_TO_LVAR_FLOAT|SET_LVAR_FLOAT_TO_VAR_FLOAT|CSET_LVAR_INT_TO_LVAR_FLOAT|CSET_LVAR_FLOAT_TO_LVAR_INT|IS_INT_VAR_EQUAL_TO_NUMBER|ADD_FLOAT_VAR_TO_FLOAT_VAR|SUB_INT_LVAR_FROM_INT_LVAR|DIV_FLOAT_VAR_BY_FLOAT_VAR|ADD_TIMED_VAL_TO_FLOAT_VAR|SET_VAR_FLOAT_TO_VAR_FLOAT|CSET_LVAR_INT_TO_VAR_FLOAT|CSET_LVAR_FLOAT_TO_VAR_INT|CSET_VAR_INT_TO_LVAR_FLOAT|CSET_VAR_FLOAT_TO_LVAR_INT|SUB_INT_VAR_FROM_INT_LVAR|SUB_INT_LVAR_FROM_INT_VAR|MULT_INT_LVAR_BY_INT_LVAR|CSET_VAR_INT_TO_VAR_FLOAT|CSET_VAR_FLOAT_TO_VAR_INT|ADD_INT_LVAR_TO_INT_LVAR|SUB_INT_VAR_FROM_INT_VAR|MULT_INT_VAR_BY_INT_LVAR|MULT_INT_LVAR_BY_INT_VAR|DIV_INT_LVAR_BY_INT_LVAR|SET_LVAR_INT_TO_LVAR_INT|SET_LVAR_INT_TO_CONSTANT|SUB_VAL_FROM_FLOAT_LVAR|ADD_INT_VAR_TO_INT_LVAR|ADD_INT_LVAR_TO_INT_VAR|MULT_INT_VAR_BY_INT_VAR|DIV_INT_VAR_BY_INT_LVAR|DIV_INT_LVAR_BY_INT_VAR|SET_VAR_INT_TO_LVAR_INT|SET_LVAR_INT_TO_VAR_INT|SET_VAR_INT_TO_CONSTANT|SUB_VAL_FROM_FLOAT_VAR|MULT_FLOAT_LVAR_BY_VAL|ADD_INT_VAR_TO_INT_VAR|DIV_INT_VAR_BY_INT_VAR|SET_VAR_INT_TO_VAR_INT|ADD_VAL_TO_FLOAT_LVAR|SUB_VAL_FROM_INT_LVAR|MULT_FLOAT_VAR_BY_VAL|DIV_FLOAT_LVAR_BY_VAL|SET_LVAR_TEXT_LABEL16|ADD_VAL_TO_FLOAT_VAR|SUB_VAL_FROM_INT_VAR|MULT_INT_LVAR_BY_VAL|DIV_FLOAT_VAR_BY_VAL|SET_VAR_TEXT_LABEL16|ADD_VAL_TO_INT_LVAR|MULT_INT_VAR_BY_VAL|DIV_INT_LVAR_BY_VAL|SET_LVAR_TEXT_LABEL|ADD_VAL_TO_INT_VAR|DIV_INT_VAR_BY_VAL|SET_VAR_TEXT_LABEL|SET_LVAR_FLOAT|SET_VAR_FLOAT|SET_LVAR_INT|SET_VAR_INT) +//gsi; # remove operators prefixes
$file=~s/ TIMERA/ 32\@/gm;
$file=~s/ TIMERB/ 33\@/gm;
$file=~s/^:LABEL.+$//gm;
$file=~s/\n\s+/\n/gs;
$file=~s/s\$(\d+)\[(\d+)\]/'s$'.($1+$2*2)/egs;
$file=~s/\$(\d+)\[(\d+)\]/'$'.($1+$2)/egs;
$file=~s/($sb_enums_key)/$sb_enums->{$1}/gs;
$file=~s/((start_new_script|start_new_streamed_script)[^\n]+) +\n/$1\n/gs;
#print $file;die;
return($file);
}

sub load_sb_enums{
my $ret={};
my $current='';
my $last_num=0;
open(dd,"sb_enums.txt");
while(<dd>){
chomp;
if(/^enum (\S+)/){
$current=$1;
$last_num=-1;
next;
}
if(/^end$/){
$current='';
next;
}
if($current && /^\t(.+?)=([\-\d]+)/){
$ret->{$current.'.'.$1}=$2;
$last_num=$2;
next;
}
if($current && /^\t([^=]+)/){
$ret->{$current.'.'.$1}=++$last_num;
}
}
return($ret);
}

