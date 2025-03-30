
$id=-1;
$id2=-2;
$num=0;

print "<table border=0 cellspacing=1>";

open(dd,"col_load.ms");
while(<dd>){

if(/-- \d+: \((\d+) in max\) (\S+)/){
$id=$1;
$name=$2;
}
if(/surfaces\[(\d+)\]=\[(\d+, \d+, \d+)\]/){
$id2=$1;
$color=$2;

@comp=split(/,\s*/,$color);
$luma=0.2126*$comp[0]+0.7152*$comp[1]+0.0722*$comp[2];
$fcolor=$luma<128?"white":"black";

}



if($id==$id2){

if($num%5==0){print "\n\n<tr>";}
$num++;

print <<CODE;
<td style="text-align:center;height:12px;display:inner-block;color:$fcolor;background-color:rgb($color);border:1px solid black;">$name</td>
CODE

$id=-1;
$id2=-2;
}

}

