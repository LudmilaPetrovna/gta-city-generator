use utf8;
use JSON;
use Encode;
use File::Slurp;
use Data::Dumper;

$root_file="streams_tk_0";

$json_file=$root_file.'-en.json';
$json=decode_json(read_file($json_file));

process_srt('ru');
process_srt('en');

process_json('ru');
process_json('en');


sub process_json{
my $suffix=shift;
my($subs,$tokens,$speakers)=read_json($root_file.'-'.$suffix.'.json');
write_file($root_file.'-'.$suffix.'-json-subs.txt',encode_utf8(join("",map{join("\t",@{$_})."\n"}@{$subs})));
write_file($root_file.'-'.$suffix.'-json-tokens.txt',encode_utf8(join("",map{join("\t",@{$_})."\n"}@{$tokens})));
write_file($root_file.'-'.$suffix.'-json-speakers.txt',encode_utf8(join("",map{join("\t",@{$_})."\n"}@{$speakers})));
}

sub read_json{
my $json_file=shift;
my $json=decode_json(read_file($json_file));
my $subs=[];
my $tokens=[];
my $speakers=[];
my $cs=-1;
foreach(@{$json->{subtitles}}){
push(@{$subs},[$_->{startMs}/1000,($_->{startMs}+$_->{durationMs})/1000,$_->{text}]);
if($_->{speakerId}!=$cs){
push(@{$speakers},[$_->{startMs}/1000,($_->{startMs}+$_->{durationMs})/1000,$_->{speakerId}]);
$cs=$_->{speakerId};
}
if(defined $_->{tokens}){
foreach $t(@{$_->{tokens}}){
push(@{$tokens},[$t->{startMs}/1000,($t->{startMs}+$t->{durationMs})/1000,$t->{text}]);
}
}
}
return($subs,$tokens,$speakers);
}


sub process_srt{
my $suffix=shift;
my $srt_file=$root_file.'-'.$suffix.'.srt';
my $label_file=$root_file.'-'.$suffix.'.txt';
write_file($label_file,join("",map{join("\t",@{$_})."\n"}read_srt($srt_file)));
}

sub read_srt{
my $filename=shift;
my $file=read_file($filename);
my $srtnum=1;
my $wait=0;
$file=~s/\r//sg;

my $st;
my $en;
my $text;
my @res=();
foreach(split(/\n/,$file)){
if($wait==0 && $_==$srtnum){$srtnum++;$wait++;next;}
if($wait==1 && /(\d{2}):(\d{2}):(\d{2}),(\d{3}) --> (\d{2}):(\d{2}):(\d{2}),(\d{3})/){
$st=$1*3600+$2*60+$3+('0.'.$4);
$en=$5*3600+$6*60+$7+('0.'.$8);
$wait++;
$text="";
next;
}
if($wait==2 && $_ eq ""){push(@res,[$st,$en,$text]);$wait=0;next;}
if($wait==2 && length($_)>0){
$text.=$text ne ""?"\n".$_:$_;
next;
}
die "Wrong srt format";
}
return(@res);
}

