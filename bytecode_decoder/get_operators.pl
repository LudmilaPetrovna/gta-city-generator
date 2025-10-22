use JSON;
use File::Slurp;
use Data::Dumper;
#0038:   $452 == 4

@operators=map{0}(0..2010);
@negative=map{0}(0..2700);


%fixes=map{($nn,$op,$name)=split(/_/,$_,3);$name,$op}split(/\n/,<<AAA);
_>=_IS_FLOAT_LVAR_GREATER_OR_EQUAL_TO_FLOAT_VAR
_==_IS_FLOAT_VAR_EQUAL_TO_FLOAT_LVAR
_*=_MULT_INT_VAR_BY_INT_LVAR
_/=_DIV_INT_VAR_BY_INT_VAR
_/=_DIV_INT_LVAR_BY_INT_VAR
_+=\@_ADD_TIMED_FLOAT_VAR_TO_FLOAT_LVAR
_>_IS_INT_VAR_GREATER_THAN_CONSTANT
_>_IS_INT_LVAR_GREATER_THAN_CONSTANT
_>_IS_CONSTANT_GREATER_THAN_INT_VAR
_>_IS_CONSTANT_GREATER_THAN_INT_LVAR
_>=_IS_INT_VAR_GREATER_OR_EQUAL_TO_CONSTANT
_>=_IS_CONSTANT_GREATER_OR_EQUAL_TO_INT_VAR
_>=_IS_CONSTANT_GREATER_OR_EQUAL_TO_INT_LVAR
_=_SET_LVAR_TEXT_LABEL
_==_IS_VAR_TEXT_LABEL_EQUAL_TO_TEXT_LABEL
_==_IS_LVAR_TEXT_LABEL_EQUAL_TO_TEXT_LABEL
_=_SET_LVAR_TEXT_LABEL16
_==_IS_FLOAT_LVAR_EQUAL_TO_FLOAT_VAR
_=_SET_VAR_TEXT_LABEL
_=_SET_VAR_TEXT_LABEL16
_==_IS_VAR_TEXT_LABEL16_EQUAL_TO_TEXT_LABEL
_==_IS_LVAR_TEXT_LABEL16_EQUAL_TO_TEXT_LABEL
AAA

@sc_cmds=split(/<Command/s,read_file("opcode_db_gta3sc.xml"));
foreach(@sc_cmds){
$id=-1;
if(/ID=\"0x([\da-f]+)/i){
$id=hex($1);
}
if(/Name=\"([^\"]+)\"/){
$names[$id]=$1;
}

if($id>0 && $fixes{uc($names[$id])}){
print "name:$names[$id]\n";
$operators[$id]=[$fixes{$names[$id]}];
}

$count=0;
while(/<Arg /g){
$count++;
}
if($id>=0){
$sc[$id]=$count;
}
}



$my_len=decode_json(read_file("opcode_db_my_operands.json"));
for($q=0;$q<3000;$q++){
$ops=$my_len->[$q];
$count=0;
while($ops=~/([a-z])(\d*)/g){
($type,$num)=($1,$2*1);
if($type eq "s"){$num=1;}
if($type eq "v"){$num=1000;}
$count+=$num;
}

$myl[$q]=$count;

}






open(dd,$ARGV[0]||"allglued.txt");
while(<dd>){
s/[\r\n]//gs;
s/\s+/ /gs;
if(/^([\da-fA-F]{4}:.+)/){
$id=hex($1)&0x7fff;
if(hex($1)&0x8000){
$negative[$id]=1;
}
if(!$operators[$id]){$operators[$id]=[];}
#$operators[$id]->[1]=$1;
}
if(/^([\da-fA-F]{4}):\s+(([a-z_]+\s+)*)([\$\@\#\d\.]+) ([\!<>\+\-\=\*\/\%\#\@]{1,3}) ([\.\$\@\#\d+])/){
$operators[hex($1)&0x7fff]->[0]=$5;
#$names[hex($1)&0x7fff]=$2;
}

}




@final=();
for($q=0;$q<2700;$q++){
$final[$q]=0;
if($operators[$q] && $operators[$q]->[0]){
$final[$q]=$operators[$q]->[0];
}
}

write_file("opcode_db_my_operators.json",encode_json(\@final));

$fix="";
for($q=0;$q<2700;$q++){
if(!$names[$q]){next;}
$name=$names[$q];
if($name=~/_INT|_LVAR|_GREATER|_EQUAL|MULT_|DIV_|_INT|_CONSTANT|_LVAR|_FLOAT/ && $myl[$q]==2){
printf("%04X: %s \x1b[0m\x1b[38;5;10m%s=%d\x1b[0m \x1b[0m\x1b[38;5;14m%s\x1b[0m \x1b[38;5;8m%s\x1b[0m\n",$q,$names[$q],$my_len->[$q],$myl[$q],$operators[$q]->[0],$operators[$q]->[1]);

if(!$operators[$q]->[0]){
$fix.='$operators[$q]->[0]=\'\';'." # $names[$q]\n";
}

}


}


for($q=0;$q<2700;$q++){

if($my_len->[$q] ne "u" && ($negative[$q] || $names[$q]=~/_EXIST$|IS_|HAS_|DOES_|HAS_|LOCATE_|_FINISHED|_LOADED/)){
$negative[$q]|=2;
printf("! %04X: %s \x1b[0m\x1b[38;5;10m%s\x1b[0m %s\n",$q,$names[$q],$negative[$q],$my_len->[$q]);
}
$negative[$q]*=1;
}

write_file("opcode_db_my_negative.json",encode_json(\@negative));

$opnames=[];
for($q=0;$q<3000;$q++){
if($operators[$q]->[0]){
push(@{$opnames},$names[$q]);
}
}

print Dumper($operators[2297]);
print join("|",sort{length($b) <=> length($a)}@{$opnames});


#print $fix;

