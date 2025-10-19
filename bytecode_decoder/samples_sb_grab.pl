use File::Slurp;
use File::Basename;
use Data::Dumper;
use JSON;


%opcodes=();
%count=();
%infile=();

@files=map{"scripts.img/decoded/$_"}grep{/\.scm\.txt$/}read_dir("scripts.img/decoded/");
push(@files,'main_raw[1].txt');

foreach $infile(@files){
print STDERR "Processing $infile...\n";
$file=read_file($infile);
$script_prefix=lc(basename($infile));
$script_prefix=~s/_raw\[.+//;
$script_prefix=~s/\..+//;
$script_name=$script_prefix;

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


}
}

print Dumper($opcodes{0x03A4});

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

