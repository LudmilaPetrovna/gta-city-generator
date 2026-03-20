use JSON;
use File::Basename;
use File::Slurp;
use Data::Dumper;

%modloader=();
open(ii,"sounds.txt");
while(<ii>){
chomp;
@p=split(/\t\|/);
$modloader{$p[10]}=$p[9];
}

$js={};

$url='https://uzzimodding.blogspot.com/2022/09/GTASASoundsList.html';
$filename=basename($url);
if(!-s($filename)){`curl -sL "$url" -o "$filename"`;}
$page=read_file($filename);


$page=~s/<span class='share-button-link-text'>Email This.+//s;
$page=~s/.+?<h3 class='post-title entry-title'>//s;

$parts='STREAMS|GENRL|PAIN_A|SCRIPT|SPC_EA|SPC_FA|SPC_GA|SPC_NA|SPC_PA';
$page=~s/<\/?span[^>]*>//sg;
$page=~s/<\/?b[^>]*>//sg;
$page=~s/&nbsp;/ /gs;

@parts=grep{/$parts/}split(/<\/div><div><\/div><div><\/div>/,$page);

foreach $part(@parts){
$package_name=$package_descr="-----------";

$part=~s/^.+(?=$parts)//s;
if($part=~s/<div style="display: none;">(.+)//s){
$content=$1;
}
$part=~s/<[^>]*>//gs;
if($part=~/($parts)(.+)/){
($package_name,$package_descr)=($1,$2);
$package_descr=~tr/()//d;
$package_descr=~s/<[^>]*>//gs;
$package_descr=~s/^\s+-\s//gs;
$package_descr=~s/\'//gs;
$package_descr=~s/^\s+|\s*$//gs;
print "$package_name/=$package_descr)\n";
}


foreach $line(split(/<\/?(li|p|br)[^>]*>/,$content)){
if($line=~/(sound|bank)_?(\d+[\-_]?\d*)(.*)/is){
($type,$id,$val)=($1,$2,$3);
#print "got ($type,$id,$val), curbank: $current_bank\n";
$is_range=0;
$range=[];
$val=~s/<[^>]*>//gs;
$val=~s/^\s+-\s//gs;
$val=~s/\'//gs;
$val=~s/^\s+|\s*$//gs;
if($id=~/^(\d+)\D(\d+)$/){
$is_range=1;
($st,$en)=($1|0,$2|0);
$range=[($st..$en)];
} else {
$id|=0;
$range=[$id|0];
}
if(lc($type) eq "bank"){
if(!$is_range){
$current_bank=$id;
} else {
$current_bank=-1;
}

print map{
$key='audio/'."$package_name/bank".$_.'/sound_0001.wav';
if(!exists $modloader{$key}){die "can't find key";}
$oval=$modloader{$key};
$oval=~s/\/sound_.+//s;
if($oval=~/(bank\d+)/){
$js->{$1}=$val;
}
"$oval\t|$package_name/bank".$_.'/='.$val."\n"
}@{$range};
}

if(lc($type) eq "sound"){

print map{
$key=sprintf('audio/%s/bank%d/sound_%04d.wav',$package_name,$current_bank,$_|0);
if(!exists $modloader{$key}){die "can't find key $key";}
$oval=$modloader{$key};


"$oval\t|$package_name/bank".$current_bank.'/sound_'.$_.'='.$val."\n"
}@{$range};

}



#print "($type,$id,$val)\n";

}

}
#print Dumper(\@lines);

print "\n\n\n";
}

write_file('bank_names.js',encode_json($js));
