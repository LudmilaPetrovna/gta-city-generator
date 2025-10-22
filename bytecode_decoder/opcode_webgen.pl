use JSON;
use File::Slurp;
use Data::Dumper;

@opnames=();

@sc_cmds=split(/<Command/s,read_file("opcode_db_gta3sc.xml"));
foreach $entry(@sc_cmds){
$id=-1;
if($entry=~/ID=\"0x([\da-f]+)/i){
$id=hex($1);
}
$count=0;
while($entry=~/<Arg ([^>]+)/g){
$arg=$1;
$name="";
if($arg=~/Enum="(.+?)"/){$name=$1;}
if($arg=~/Entity="(.+?)"/){$name=$1;}
if($arg=~/Desc="(.+?)"/){$name=$1;}
if($name && $id>=0){
$opnames[$id]->[$count]=$name;
}
$count++;
}

}


$my_len=decode_json(read_file("opcode_db_my_operands.json"));
for($q=0;$q<3000;$q++){
$ops=$my_len->[$q];
$count=0;
while($ops=~/([a-z])(\d*)/g){
($type,$num)=($1,$2*1);
if($type eq "s"){$num=1;}
if($type eq "v"){$num=1;}
if($type eq "b"){$num=1;}
$count+=$num;
}

$myl[$q]=$count;

}


$nops=decode_json(read_file("opcode_db_my_nops.json"));
$writables=decode_json(read_file("opcode_db_my_writables.json"));
$exists=decode_json(read_file("opcode_db_my_exists.json"));
$seealso=decode_json(read_file("opcode_db_my_seealso.json"));
$my_code=decode_json(read_file("opcode_db_my_snippets.json"));

$cleo_sa_cmds=decode_json(read_file("opcode_db_cleo.json"))->{extensions}->[0]->{commands};

$coperators=[];

foreach $cmd(@{$cleo_sa_cmds}){
$id=hex($cmd->{id});
$cleo[$id]=$cmd->{num_params};
$names[$id]=$cmd->{name};
$desc[$id]=$cmd->{short_desc};
$oppos=0;
$inp=$cmd->{input};
$coperators->[$id]=$cmd->{operator};
foreach(@{$inp}){
if(!$opnames[$id]->[$oppos]){
$opnames[$id]->[$oppos]=$_->{name} || $_->{type};
}
$oppos++;
}
$inp=$cmd->{output};
foreach(@{$inp}){
if(!$opnames[$id]->[$oppos]){
$opnames[$id]->[$oppos]=$_->{name} || $_->{type};
}
$oppos++;
}


}




$infile=decode_json(read_file("opcode_db_my_infile.json"));
$used_count=decode_json(read_file("opcode_db_my_count.json"));
$samples=decode_json(read_file("opcode_db_my_samples.json"));
$operators=decode_json(read_file("opcode_db_my_operators.json"));



for($q=0;$q<3000;$q++){
if($operators->[$q]==0 && $coperators->[$q] eq ""){next;}
if($operators->[$q] ne $coperators->[$q]){
#printf("%04X (%d) %s, operator \"%s\" cleo operator \"%s\"\n",$q,$q,$names[$q],$operators->[$q],$coperators->[$q]);
}
}



open(pp,">opcodes.html");
print pp <<HTML;
<html><head><meta http-equiv="Content-Type" content="text/html; charset=utf8"/>
<title>GTA San Andreas bytecode instructions database</title>
<style>
body{background:#555;color:#888;}
a{background:#0000FF80;color:white;}
a:hover{background:black;color:red;}
h1{background:navy;color:white;font-family:fixed;margin:0px;padding:5px;}
h1.exists0{background:#300;color:#333;}
.snippet{background:black;color:lime;}
.usage{background:black;color:cyan;}
.desc{background:#00F;color:white;}
textarea{background:black;width:100%;color:gold;font-weight:bold;border:1px #aaa inset;}
.signature{background:#050;color:#FF0;}
.no{background:maroon;}
.opname td{text-align:center;color:white;}

.writable td{text-align:center;}
.writable .a1{color:lime;background:#070;}
.writable .a0{color:red;background:#700;}
.readable td{text-align:center;}
.readable .a1{color:lime;background:#070;}
.readable .a0{color:red;background:#700;}
.n{color:white;text-align:left;}

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
if($nops->[$q]){
$op.=" (NOP)";
}
printf(pp "<h1$ex><a href=#%04X name=%04X>%04X</a> (%d): %s$op</h1>\n",$q,$q,$q,$q,$names[$q]);
if(!$exists->[$q]){
printf(pp "<div class=snippet>%s</div>\n",$code);
next;
}

$descr=$desc[$q];
$descr=~s/\b([0-9a-f]{4})\b/"<a href=#$1 title='".$names[hex($1)]."'>$1<\/a>"/egs;
if($nops->[$q]){
$descr="Этот опкод не делает ничего, но может быть в скриптах и будет обработан игрой";
}

printf(pp "<div class=desc>%s</div>\n",$descr);
$sign="";
$s=$my_len->[$q];
@arg=();
$sign=join(", ",@arg);
if($sign){
$sign=" ($sign)";
}


if(!$writables->[$q]){
$writables->[$q]=[];
}

printf(pp "<div class=signature>Параметров: %d, cигнатура: %s%s</div>\n",$myl[$q],$my_len->[$q] || "<span class=no>нет</span>");

if($myl[$q]!=0){
# PARAMETERS

print pp "<table border=1><tr><td>///";
$sign=$my_len->[$q];
$oppos=0;
$expect_line="<td class=n>Ожидается";
@readables=();
while($sign=~/([a-z])(\d*)/g){
$type="";
$count=1;
$is_rw=0;
if($1 eq "i"){$type="входной параметр";$count=$2;}
if($1 eq "o"){$type="выходной параметр";$count=$2;$is_rw=1;}
if($1 eq "p"){$type="указатель";$count=$2;}
if($1 eq "g"){$type="глобальный указатель";$count=1;}
if($1 eq "b"){$type="блок в $2 байт";}
if($1 eq "s"){$type="строка до $2 символов";$count=1;}
if($1 eq "v"){$type="дополнительные аргументы (если есть, произвольное количество)";$count=1;}
for($e=0;$e<$count;$e++){
print pp "<td class=n>Параметр ".($e+$oppos+1);
$expect_line.="<td class=n>".$type;
$writables->[$q]->[$e+$oppos]|=$is_rw;
$readables[$e+$oppos]=1-$is_rw;
}
$oppos+=$count;
}


print pp "<tr class=opname><td class=n>Название";
for($e=0;$e<$myl[$q];$e++){
print pp "<td>".$opnames[$q]->[$e];
}



if($operators->[$q] && $operators->[$q] ne "==" && $operators->[$q] ne ">=" && $operators->[$q] ne ">"){
$writables->[$q]->[0]=1;
}

print pp "<tr class=readable><td class=n>Чтение";
for($e=0;$e<$myl[$q];$e++){
$is_yes=$readables[$e]?1:0;
print pp "<td class=a$is_yes>".($is_yes?"да":"нет");
}

print pp "<tr class=writable><td class=n>Запись";
for($e=0;$e<$myl[$q];$e++){
$is_yes=$writables->[$q]->[$e]?1:0;
print pp "<td class=a$is_yes>".($is_yes?"да":"нет");
}

print pp "<tr>".$expect_line;

print pp "</table>";

# /PARAMETERS
}

if($seealso->[$q]){
$seealso_text=join(", ",map{sprintf("<a href=#%04X title='%s'>%04X</a>",$_,$names[$_],$_)}@{$seealso->[$q]});

printf(pp "<div class=usage>Используется совместно с: %s</div>\n",$seealso_text);
}
printf(pp "<div class=usage>Встречается в коде скриптов раз: %d, встречается в файлах: %s</div>\n",$used_count->[$q],$infile->[$q]||"<span class=no>нигде</span>");
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