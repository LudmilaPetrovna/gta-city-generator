use File::Slurp;
use Data::Dumper;
use JSON;

$cmds=read_file("commands.txt");
$cmds=~tr/\r//d;
@cmds=split(/(?=\n {6,9}case [x\da-fA-F]+u?:)/,$cmds);

=pod
Search this strings to calc parameters count:
CRunningScript::CollectParameters(this, 4u);
CRunningScript::ReadTextLabelFromScript(this, ptr, 8u);
CRunningScript::ReadParametersForNewlyStartedScript(this, started); (0x4Fu and 0x913u only)
=cut

@codes=map{"u"}(0..3000);

foreach $code(@cmds){
$name="";
$params="";
if($code=~s/\s+case ([x\da-fA-F]+)u?://s){
$name=hex2dec($1);
}
#if($name ne "913"){next;}

$code=~s/return[^;]+//gs;

foreach $line(split(/;/,$code)){
if($line=~/CRunningScript::CollectParameters[^,]+,\s+([x\d]+)u?\)/){
$params.="p".hex2dec($1);
}
if($line=~/CRunningScript::ReadTextLabelFromScript[^,]+,[^,]+,\s+([x\d]+)u?\)/){
$params.="s".hex2dec($1);
}
if($line=~/CRunningScript::ReadParametersForNewlyStartedScript/){
$params.="o";
}
}

if(length($code)<10){$params.="l";}

$codes[$name]=$params;
}

write_file("codeparam.pl",encode_json(\@codes));


sub hex2dec{
my $str=shift;
if($str=~/^0x([\da-f]+)/i){return(hex($1));}
return($str*1);
}