use utf8;
use GD;
use JSON;
use Encode;
use File::Slurp;
use Data::Dumper;

$root_file="atlas-0";


$width=620;
$height=10000;
$image=GD::Image->new($width,$height,1);
$image->alphaBlending(0);
$image->saveAlpha(1);
#$image->filledRectangle(0,0,$width,$height,0x7F000000);
$image->filledRectangle(0,0,$width,$height,0xDDDDDD);
$image->alphaBlending(1);

$scale_pixms=7;

# draw scale
for($q=0;$q<2000;$q++){
$oy=int($q*$scale_pixms);
$text=sprintf("%02d:%02d",int($q/60),$q-int($q/60)*60);
$image->filledRectangle(0,$oy,$width,$oy,0x70000000);
$image->string(gdTinyFont,0,$oy-4,$text,0);
if($oy>$height){last;}
}

# calc status
@source_srt=read_srt($root_file.".srt");

%status=();
my($subs,$tokens,$speakers)=read_json($root_file.'-ru.json');
foreach $ru(@{$subs}){
($rust,$ruen,$rutext)=@{$ru};
$rust-=0.3;
$ruen+=2.0;
$oy1=$rust*$scale_pixms;
$oy2=$ruen*$scale_pixms;
$image->filledRectangle(150,$oy1,200,$oy2,0x5000DDFF);
#print "RU: $rust .. $ruen ($rutext)\n";
@rel=();
foreach $src(@source_srt){
#if($src->[0]>=$rust && $src->[1]<=$ruen){
if(($src->[0]>=$rust && $src->[0]<=$ruen) || ($src->[1]>=$rust && $src->[1]<=$ruen)){
$srcfile=$src->[2];
$srcfile=~s/ .*$//s;
push(@rel,$srcfile);
print "SRC: $src->[0] .. $src->[1] ($srcfile)\n";
}
}
if(@rel==1){
$status{$rel[0]}="ok";
print "ok\n";
}
if(@rel>1){
map{$status{$_}="bad"}@rel;
print "bad\n";
}
}

foreach $src(@source_srt){
$srcfile=$src->[2];
$srcfile=~s/ .*$//s;
if(!exists $status{$srcfile}){$status{$srcfile}='notfound';}
}

#print Dumper(\%status);

# draw sources
foreach $s(@source_srt){
($st,$en,$text)=@{$s};
$text=~s/ .+//s;
$oy1=int($st*$scale_pixms);
$oy2=int($en*$scale_pixms);
$offsetX1=30;
$offsetX2=120;
$color=0;
if($status{$text} eq 'ok'){
$color=0x00FF00;
}
if($status{$text} eq 'bad'){
$color=0xFF0000;
}
if($status{$text} eq 'notfound'){
$color=0x00FFFF;
}


$image->filledRectangle($offsetX1,$oy1,$offsetX2,$oy2,0x30555599);
draw_wrapped_string($offsetX1,$oy1,70,"$text",$color);
}




#@events=();

#push(@events,map{[$_->[0],$_->[1],"FILEID",230,$_->[2]]}$source_srt);

#process_srt('ru');
#process_srt('en');
process_json('ru');
process_json('en');

$ruto=$root_file.'-ru-live-ru.json';
if(-s($ruto)){
my($subs,$tokens,$speakers)=read_json($ruto);
#push(@events,map{[$_->[0],$_->[1],"TOKEN",50,$_->[2]]}@{$tokens});
}

#@events=sort{$a->[0] <=> $b->[0]}@events;
#$ssa=get_ssa_header();
#$ssa.=join("",map{get_ssa_event(@{$_})}@events);
#write_file($root_file."-ru-dub.ass",encode_utf8($ssa));

write_file("timescale.png",$image->png(9));

sub process_json{
my $suffix=shift;
my($subs,$tokens,$speakers)=read_json($root_file.'-'.$suffix.'.json');
my $offsetX1=$suffix eq "ru"?320:120;
my $offsetX2=$offsetX1+200;
my $colorBG=$suffix eq "ru"?0x00FF00:0xFFFF00;

#push(@events,map{[$_->[0],$_->[1],$suffix eq "ru"?"RUSSIAN":"ENGLISH",$suffix eq "ru"?0:120,$_->[2]]}@{$subs});
#push(@events,map{[$_->[0],$_->[1],"TOKEN",170,$_->[2]]}@{$tokens});
#push(@events,map{[$_->[0],$_->[1],"SPEAKERID",200,"$suffix:".$_->[2]]}@{$speakers});
foreach $s(@{$tokens}){
($st,$en,$text)=@{$s};
$oy1=int($st*$scale_pixms);
$oy2=int($en*$scale_pixms);
draw_wrapped_string($offsetX1+rand()*100,$oy1,190,"$text",0x50FF7777);
}

foreach $s(@{$subs}){
($st,$en,$text)=@{$s};
$oy1=int($st*$scale_pixms);
$oy2=int($en*$scale_pixms);
$image->filledRectangle($offsetX1,$oy1,$offsetX2,$oy2,0x50000000|$colorBG);
$image->rectangle($offsetX1,$oy1,$offsetX2,$oy2,0x50000000);
draw_wrapped_string($offsetX1,$oy1,190,"$text",0);
}


}

sub draw_wrapped_string{
my($ox,$oy,$width,$text,$color)=@_;
my $font='/usr/share/fonts/truetype/Fifaks10Dev1.ttf';
$oy+=12;
my $len=length($text);
my $perline=int($width/6);
#$text=decode_utf8($text);
while($len>0){
if($color){
$image->stringFT(0,$font,9,0,$ox+1,$oy+1,substr($text,0,$perline));
}
$image->stringFT($color,$font,9,0,$ox,$oy,substr($text,0,$perline));
#$image->string(gdSmallFont,$ox,$oy,substr($text,0,$perline),0);
$text=substr($text,$perline);
$len=length($text);
$oy+=11;
}


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

