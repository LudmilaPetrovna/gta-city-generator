use File::Slurp;
use Data::Dumper;
use JSON;

$cmds=read_file("commands.txt");
$cmds=~tr/\r//d;
#$cmds=~s/(\n {6,9}case [x\da-fA-F]+u?:)+\s+return 0//sg; # "nop commands" are exists in scripts
$cmds=~s/((\n {6,9}case [x\da-fA-F]+u?:)+)/"\n".strip_lines($1)/esg;
@cmds=split(/(?=\n {6,9}case [x\da-fA-F]+u?:)/,$cmds);

=pod
Search this strings to calc parameters count:
PointerToScriptVariable = CRunningScript::GetPointerToScriptVariable(this, 2); # read 1 integer parameter
CRunningScript::CollectParameters(this, 4u);
CRunningScript::ReadTextLabelFromScript(this, ptr, 8u);
CRunningScript::ReadParametersForNewlyStartedScript(this, started); (0x4Fu and 0x913u only)
=cut

@codes=map{"u"}(0..0x7fff);
@exists=map{0}(0..3000);
@twins=map{0}(0..3000);

=pod
Legend:
i - input values, mostly ints or offsets
o - output values (2, 3, 7, 8)
p - input pointer to var (no immediate value) (2, A, 0x10 / 3, b, 0x11 / 7, C, 0x12 / 8, D, 0x13)
g - input pointer to global variable (2, 7 and "int16")
b - input byte (maybe flag or var)
s - input string values, number=max string length (9..20)
v - vararg (enables 0 type)

Stats:
used_opcode_types (0..20)
min_int
max_int
min_float
max_float
min_str_len
max_str_len
used_chars
last_10_values
=cut

foreach $code(@cmds){
if($code=~s/\n {8}+((case ([x\da-fA-F]+)u?: ?)+)//s){
$idlist=$1;
}
@lines=split(/;/,$code);
@ctwins=();

while($idlist=~/case ([x\da-fA-F]+)u?:/g){
$opcode=hex2dec($1);
$exists[$opcode]=1;
$snippets[$opcode]=$code;
$params="";
push(@ctwins,$opcode);

#print "Decoding opcode $opcode\n";

foreach $line(@lines){
#print "$line\n";
if($line=~/CRunningScript::StoreParameters[^,]+,\s+([x\da-fA-F]+)/){
$params.="o".hex2dec($1); # fixme
}
if($line=~/CRunningScript::GetPointerToScriptVariable/){
$params.="p1"; # fixme int 1 operand
}
if($line=~/CRunningScript::GetIndexOfGlobalVariable/){
$params.="g1"; # fixme int 1 operand
}
if($line=~/CRunningScript::CollectParameters[^,]+,\s+([x\da-fA-F]+)u?\)/){
$params.="i".hex2dec($1);
}
if($line=~/CRunningScript::ReadTextLabelFromScript[^,]+,[^,]+,\s+([x\da-fA-F]+)u?\)/){
$params.="s".hex2dec($1);
}
if($line=~/CRunningScript::ReadParametersForNewlyStartedScript/){
$params.="v";
}

if($line=~/CRunningScript::LocateCharCommand/){
if($opcode<0xFE || $opcode>0x103){$params.="p6";} else {$params.="p8";}
}

if($line=~/CRunningScript::LocateCharCharCommand/){
if($opcode<0x104 || $opcode>0x106){
$params.="i5";
} else {
$params.="i6";
}
}

if($line=~/CRunningScript::CharInAreaCheckCommand/){ # not sure, logic got from compiler
if($opcode>=0x1a6){
$params.="p8";
} else {
$params.="p6";
}
}

if($line=~/CRunningScript::ScriptTaskPickUpObject/){
$params.="i7s24s16i1";
}

if($line=~/CRunningScript::ObjectInAreaCheckCommand/){
if($opcode==1258){
$params.="i8";
} else {
$params.="i6";
}
}



if($line=~/sub_487A20/){
if($opcode<431 || $opcode>432){
$params.="p6";
} else {
$params.="p8";
}
}

if($line=~/sub_487720/){
if($opcode>=0x0474){
$params.="p6";
} else {
$params.="p5";
}
}



if($line=~/sub_488EC0/){
if($opcode==177 || $opcode==428){
$params.="p8";
} else {
$params.="p6";
}
}


if($line=~/CScriptThread::locateCar/){
if($opcode<517 || $opcode>519){
$params.="p5";
} else {
$params.="p6";
}
}

if($line=~/return 0/){last;}




if($line=~/sub_488780/){
if($opcode==0x72E){
$params.="i8";
} else {
$params.="i6";
}
}


if($line=~/sub_487D10/){
if($opcode==1254){
$params.="i8";
} else {
$params.="i6";
}
}


if($line=~/sub_4883F0/){
if($opcode==2276){
$params.="i9";
} else {
$params.="i7";
}
}


if($line=~/sub_487F60/){
if($opcode<1532 || $opcode>1537){
$params.="i7";
} else {
$params.="i9";
}
}


if($line=~/sub_470150/){
$params.="i1s24s16";
if($opcode==0xA1A){$params.="i6";}
if($opcode==0x88A){$params.="i8";}
if($opcode==0x605){$params.="i6";}
if($opcode==0x812){$params.="i6";}
}


}

#if(length($code)<10){$params.="l";}

if($opcode==0x1d || $opcode==0x1e){
$params.="p1"; # GetPointerToScriptVariable
}

if($opcode==0x0180){
$params="b1";
}
if($opcode==0x08DB){
$params.="s8"x10;
}


if($opcode==0x06E6){
$params="i1o1";
}

do "./opcode_db_my_fix.pl";


$codes[$opcode]=$params;
}

}

write_file("opcode_db_my_operands.json",encode_json(\@codes));
write_file("opcode_db_my_exists.json",encode_json(\@exists));
write_file("opcode_db_my_snippets.json",encode_json(\@snippets));

print $codes[0x087]."\n";


sub hex2dec{
my $str=shift;
if($str=~/^0x([\da-f]+)/i){return(hex($1));}
return($str*1);
}



sub strip_lines{
my $str=shift;
$str=~s/\s+/ /gs;
$str=~s/^\s+/        /s;
return($str);
}

