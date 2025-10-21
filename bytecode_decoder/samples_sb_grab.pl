use File::Slurp;
use File::Basename;
use Data::Dumper;
use JSON;


%opcodes=();
%count=();
%infile=();

@files=map{"scripts.img/decoded/$_"}grep{/\.scm\.txt$/}read_dir("scripts.img/decoded/");
push(@files,'main_raw[1].txt');

#@files=grep{/dealer/}@files;



%related=();
%see=();

# see also black list
@seeblack=();
$operators=decode_json(read_file("opcode_db_my_operators.json"));
for($q=0;$q<3000;$q++){
if($operators->[$q]){$seeblack[$q]=1;}
}
map{/^(....):/;$seeblack[hex($1)]=1}split(/\n/,<<CODE);
0000: nop
0001: wait {time} 0
00D6: if 
0002: goto
004D: goto_if_false @Label0001D7
0050: gosub @Label000D28
0002: goto @Label0001C2
03A4: script_name {name} 'DEALER'
0051: return
0871: switch_start 
CODE

foreach $infile(@files){
print STDERR "Processing $infile...\n";
$file=read_file($infile);
$script_prefix=lc(basename($infile));
$script_prefix=~s/_raw\[.+//;
$script_prefix=~s/\..+//;
$script_name=$script_prefix;

@opcodes_all=();
@opcodes_see=();

while($file=~/^(([0-9a-fA-F]{4}):[^\r\n]+)/gm){
($line,$opcode)=($1,hex($2)&0x7FFF);
$count{$opcode}++;
$infile{$opcode}{$script_name}++;


if($line=~/^03A4: script_name[^\']+'([^\']+)'/){
$script_suffix=$1;
if($script_prefix ne lc($1)){
$script_name=$script_prefix." (".$1.")";
}
}

$norm=$line;
$norm=~s/\s+/ /gs;
$norm=~s/ (False|True)/ TRUEFALSE/gs;
$norm=~s/ TIMER[AB]/ TIMERAB/gs;
$norm=~s/\@Label[0-9A-F]+/LABEL/gs;
$norm=~s/\"[^\"\"]+\"/STRINGAA/gs;
$norm=~s/\'[^\'\"]+\'/STRINGBB/gs;
$norm=~s/[a-zA-Z]+\.[a-zA-Z]\S+/ENUM/gs;
$norm=~s/[0-9\.]+/11111/gs;


$opcodes{$opcode}{cl1}{$norm}=$line;
$opcodes{$opcode}{cl2}{$line}=$line;
push(@opcodes_all,$opcode);
}
@opcodes_see=grep{!$seeblack[$_]}@opcodes_all;

$max=@opcodes_see;
for($w=0;$w<$max;$w++){
$opcode=$opcodes_see[$w];
$prev="";
$next="";
for($e=1;$e<=10;$e++){
if($w-$e>=0){
$prev.=sprintf("%04X",$opcodes_see[$w-$e]);
}
if($w+$e<$max){
$next.=sprintf("%04X",$opcodes_see[$w+$e]);
}
}
$see{$opcode}{$prev}++;
$see{$opcode}{$next}++;
#print "$prev $next\n";

}

}


%see_also=();
%uniq=();
for($q=0;$q<3000;$q++){
if(!$see{$q}){next;}
@res=();
%uniq=();
$uniq{$q}++;
@ops=keys %{$see{$q}};
for($e=0;$e<10;$e++){
foreach(@ops){
$op=hex(substr($_,$e*4,4));
if($uniq{$op}++){next;}
if(@res>=10){last;}
push(@res,$op|0);
}
}
$see_also{$q}=join(", ",map{sprintf("%04X",$_)}@res);
$see_also{$q}=[@res];
}


write_file("opcode_db_my_seealso.json",key2arr(0,\%see_also));

for($q=0;$q<0x7FFF;$q++){
if(!exists $opcodes{$q}){next;}
#if($q!=0x03A4){next;}

%uniq=();
@res=();
foreach $v((values %{$opcodes{$q}{cl1}},values %{$opcodes{$q}{cl2}})){
if($uniq{$v}++){next;}
push(@res,$v);
if(@res>=5){last;}
}
#print map{"$_\n"}@res;
$opcodes{$q}=join("\n",@res);
}


foreach $in(keys %infile){
@list=keys %{$infile{$in}};
@res=();
%uniq=();
foreach(@list){
$norm=$_;
$norm=~s/ .+//;
if($uniq{$norm}++){next;}
$uniq{$_}++;
push(@res,$_);
}
foreach(@list){
if($uniq{$_}++){next;}
push(@res,$_);
}
if(@res>5){
splice(@res,5);
push(@res,"...");
}
$infile{$in}=join(", ",@res);


}


write_file("opcode_db_my_infile.json",key2arr("",\%infile));
write_file("opcode_db_my_samples.json",key2arr("",\%opcodes));
write_file("opcode_db_my_count.json",key2arr(0,\%count));



sub key2arr{
my $null=shift;
my $h=shift;
my @res=map{$null}(0..2800);
my $q;
for($q=0;$q<2800;$q++){
if(!$h->{$q}){next;}
$res[$q]=$h->{$q};
}
return(encode_json(\@res));
}

