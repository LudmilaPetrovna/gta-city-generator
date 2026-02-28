use utf8;
use JSON;
use Encode;
use File::Slurp;
use Data::Dumper;

@events=();

$src_srt="/dev/shm/t/gta/trans/streams/joined_v3/streams_hc_0.srt";
$root_file="streams_hc_0";

push(@events,map{[$_->[0],$_->[1],"FILEID",230,$_->[2]]}read_srt($src_srt));

#process_srt('ru');
#process_srt('en');
process_json('ru');
process_json('en');

$ruto=$root_file.'-ru-live-ru.json';
if(-s($ruto)){
my($subs,$tokens,$speakers)=read_json($ruto);
push(@events,map{[$_->[0],$_->[1],"TOKEN",50,$_->[2]]}@{$tokens});
}

@events=sort{$a->[0] <=> $b->[0]}@events;
$ssa=get_ssa_header();
$ssa.=join("",map{get_ssa_event(@{$_})}@events);
write_file($root_file."-ru-dub.ass",encode_utf8($ssa));

sub process_json{
my $suffix=shift;
my($subs,$tokens,$speakers)=read_json($root_file.'-'.$suffix.'.json');
push(@events,map{[$_->[0],$_->[1],$suffix eq "ru"?"RUSSIAN":"ENGLISH",$suffix eq "ru"?0:120,$_->[2]]}@{$subs});
push(@events,map{[$_->[0],$_->[1],"TOKEN",170,$_->[2]]}@{$tokens});
push(@events,map{[$_->[0],$_->[1],"SPEAKERID",200,"$suffix:".$_->[2]]}@{$speakers});
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
if($wait==2 && $text){
push(@res,[$st,$en,$text]);
}
return(@res);
}


sub get_ssa_header{
my $ret="";
$ret.=<<CODE;
[Script Info]
ScriptType: v4.00+
PlayResX: 384
PlayResY: 288
ScaledBorderAndShadow: yes

[V4+ Styles]
Format: Name, Fontname, Fontsize, PrimaryColour, SecondaryColour, OutlineColour, BackColour, Bold, Italic, Underline, StrikeOut, ScaleX, ScaleY, Spacing, Angle, BorderStyle, Outline, Shadow, Alignment, MarginL, MarginR, MarginV, Encoding
Style: Default,Arial,16,&Hffffff,&Hffffff,&H0,&H0,0,0,0,0,100,100,0,0,1,1,0,2,10,10,10,0
Style: FILEID,Arial,16,&Hff0000,&Hff0000,&H0,&H0,0,0,0,0,100,100,0,0,1,1,0,2,10,10,10,0
Style: SPEAKERID,Arial,16,&Hffff00,&Hffff00,&H0,&H0,0,0,0,0,100,100,0,0,1,1,0,2,10,10,10,0
Style: ENGLISH,Arial,16,&H00ffff,&H00ffff,&H0,&H0,0,0,0,0,100,100,0,0,1,1,0,2,10,10,10,0
Style: TOKEN,Arial,16,&H00ffff,&H00ffff,&H0,&H0,0,0,0,0,100,100,0,0,1,1,0,2,10,10,10,0
Style: RUSSIAN,Arial,16,&H00ff00,&H00ff00,&H0,&H0,0,0,0,0,100,100,0,0,1,1,0,2,10,10,10,0

[Events]
Format: Layer, Start, End, Style, Name, MarginL, MarginR, MarginV, Effect, Text
CODE

return($ret);
}

sub get_ssa_event{
my($st,$en,$style,$offset,$text)=@_;
$st=s2ssa_time($st);
$en=s2ssa_time($en);
return("Dialogue: 0,$st,$en,$style,,0,0,$offset,,$text\n");
}

sub s2ssa_time{
my $s=shift;
#     0    1    2     3     4    5     6     7     8
my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = gmtime($s);
my $ii=$sec+$min*60+$hour*3600;
return sprintf("%d:%02d:%02d.%02d",$hour,$min,$sec,int(($s-$ii)*100));
}

