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


$exists=decode_json(read_file("opcode_db_my_exists.json"));
$my_code=decode_json(read_file("opcode_db_my_snippets.json"));

$cleo_sa_cmds=decode_json(read_file("opcode_db_cleo.json"))->{extensions}->[0]->{commands};

foreach $cmd(@{$cleo_sa_cmds}){
$id=hex($cmd->{id});
$cleo[$id]=$cmd->{num_params};
$names[$id]=$cmd->{name};
$desc[$id]=$cmd->{short_desc};
}



$infile=decode_json(read_file("opcode_db_my_infile.json"));
$count=decode_json(read_file("opcode_db_my_count.json"));
$samples=decode_json(read_file("opcode_db_my_samples.json"));
$operators=decode_json(read_file("opcode_db_my_operators.json"));


open(pp,">opcodes.html");
print pp <<HTML;
<html><head><meta http-equiv="Content-Type" content="text/html; charset=utf8"/>
<title>GTA San Andreas bytecode instructions database</title>
<style>
body{background:#555;color:#888;}
h1{background:navy;color:white;font-family:fixed;margin:0px;padding:5px;}
h1.exists0{background:#300;color:#333;}
.snippet{background:black;color:lime;}
.usage{background:black;color:cyan;}
.desc{background:#00F;color:white;}
textarea{background:black;width:100%;color:gold;font-weight:bold;border:1px #aaa inset;}
.signature{background:#050;color:#FF0;}
</style>
<body>


HTML


for($q=0;$q<2700;$q++){
$ex=' class=exists'.$exists->[$q];
$op="";
$code="";
if($operators->[$q]){
$op=" (оператор $operators->[$q])";
}
printf(pp "<h1$ex>%04X (%d): %s$op</h1>\n",$q,$q,$names[$q]);
if(!$exists->[$q]){
printf(pp "<div class=snippet>%s</div>\n",$code);
next;
}

printf(pp "<div class=desc>%s</div>\n",$desc[$q]);
$sign="";
$s=$my_len->[$q];
@arg=();
while($s=~/([iophbsv])(\d*)/g){
if($1 eq "i"){push(@arg,"входной параметр - $2шт");}
if($1 eq "o"){push(@arg,"входной параметр - $2шт");}
if($1 eq "p"){push(@arg,"указатель");}
if($1 eq "g"){push(@arg,"глобальный указатель");}
if($1 eq "b"){push(@arg,"блок в $2 байт");}
if($1 eq "s"){push(@arg,"строка до $2 символов");}
if($1 eq "v"){push(@arg,"дополнительные аргументы");}
}
$sign=join(", ",@arg);
if($sign){
$sign=" ($sign)";
}
printf(pp "<div class=signature>Параметров: %d, cигнатура: %s%s</div>\n",$myl[$q],$my_len->[$q],$sign);
printf(pp "<div class=usage>Встречается в коде скриптов раз: %d, встречается в файлах: %s</div>\n",$count->[$q],$infile->[$q]||"нигде");
$code=$my_code->[$q];
$code=~s/ /&nbsp;/gs;
$code=~s/\n/<br>/gs;
printf(pp "<div class=snippet>%s</div>\n",$code);
if($samples->[$q]){
$lines=($samples->[$q]=~tr/\n/\n/);
$lines++;
printf(pp "<textarea rows=$lines>%s</textarea>",$samples->[$q]);
}



}