use File::Slurp;
use Data::Dumper;
use JSON;

$cmds=read_file("commands.txt");
$cmds=~tr/\r//d;
$cmds=~s/(\n {6,9}case [x\da-fA-F]+u?:)+\s+return 0//sg;
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

foreach $code(@cmds){
$name="";
$params="";
if($code=~s/\n {8}+((case ([x\da-fA-F]+)u?: ?)+)//s){
$idlist=$1;
}
@lines=split(/;/,$code);

while($idlist=~/case ([x\da-fA-F]+)u?:/g){
$opcode=hex2dec($1);

foreach $line(@lines){
if($line=~/CRunningScript::StoreParameters[^,]+,\s+([x\d]+)/){
$params.="p".hex2dec($1);
}
if($line=~/CRunningScript::GetPointerToScriptVariable/){
$params.="p1";
}
if($line=~/CRunningScript::CollectParameters[^,]+,\s+([x\d]+)u?\)/){
$params.="p".hex2dec($1);
}
if($line=~/CRunningScript::ReadTextLabelFromScript[^,]+,[^,]+,\s+([x\d]+)u?\)/){
$params.="s".hex2dec($1);
}
if($line=~/CRunningScript::ReadParametersForNewlyStartedScript/){
$params.="o";
}
if($line=~/CRunningScript::LocateCharCommand/){
if($opcode<0xFE || $opcode>0x103){$params.="p6";} else {$params.="p8";}
}

}

#if(length($code)<10){$params.="l";}

$codes[$opcode]=$params;
}


}

write_file("codeparam.pl",encode_json(\@codes));

print $codes[0x08BA]."\n";


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

