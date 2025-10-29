use JSON;
use File::Slurp;

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


$my_exists=decode_json(read_file("opcode_db_my_exists.json"));
$my_code=decode_json(read_file("opcode_db_my_snippets.json"));

$cleo_sa_cmds=decode_json(read_file("opcode_db_cleo.json"))->{extensions}->[0]->{commands};

foreach $cmd(@{$cleo_sa_cmds}){
$id=hex($cmd->{id});
$cleo[$id]=$cmd->{num_params};
$names[$id]=$cmd->{name};
}

open(dd,"opcode_db_ghidra_scm_len.txt");
while(<dd>){
if(/^([\da-f]{4}), (\d+)/i){
$ghidra[hex($1)]=$2;
}
}
close(dd);

@sc_cmds=split(/<Command/s,read_file("opcode_db_gta3sc.xml"));
foreach(@sc_cmds){
$id=-1;
if(/ID=\"0x([\da-f]+)/i){
$id=hex($1);
}
if(/Name=\"([^\"]+)\"/){
$names[$id]=$1;
}
$count=0;
while(/<Arg /g){
$count++;
}
if($id>=0){
$sc[$id]=$count;
}
}



open(dd,"opcode_db_wiki.wiki");
while(<dd>){
if(!/^\|\[\[/){next;}
@cols=split(/\|\|/);
$id=-1;
$paramcount=-1;
$icon=0;
if($cols[0]=~/\[\[([\da-f]{4})\]\]/i){
$id=hex($1);
}

if($cols[1]=~/\{\{Icon\|SA\}\}|\{\{Icon\|t\}\}/){
$icon=1;
}

if($cols[2]=~/(\d+)/){
$paramcount=$1;
}

if($icon){
$wiki[$id]=$paramcount;
}
}
 

#############

@bad=();
open(oo,">opcode_db_my_fix_.pl");

for($q=0;$q<3000;$q++){
if($my_exists->[$q]!=1){next;}
$res="";
if($cleo[$q]==$ghidra[$q] && $sc[$q]==$wiki[$q] && $ghidra[$q]==$sc[$q]){
$res="other_ok";
}
if($cleo[$q]==$myl[$q]){
$res="all_ok";
next;
}
#if($my_code->[$q]=~/return/){
print "\x1b[1;44;33m";
printf("% 4s % 4s (% 50s) % 5s % 5s % 5s % 5s % 5s % 10s\n","hex","dec","name","cleo","ghidr","sc","wiki","my","res");
printf("%04X %04d (% 50s) % 5d % 5d % 5d % 5d % 5d % 10s\n",$q,$q,$names[$q],$cleo[$q],$ghidra[$q],$sc[$q],$wiki[$q],$myl[$q],$res);
print "\x1b[0m\x1b[92m".$my_code->[$q]."\x1b[0m\n";
$opcode=sprintf("0x%04X /* % 5d = %- 42s */",$q,$q,$names[$q]);

print oo "if(\$opcode==$opcode){\$params=\"".$my_len->[$q]."\";} #";
printf(oo "cleo:%d gh:%d sc:%d wiki:%d my:%d\n",$cleo[$q],$ghidra[$q],$sc[$q],$wiki[$q],$myl[$q]);

#}

}



