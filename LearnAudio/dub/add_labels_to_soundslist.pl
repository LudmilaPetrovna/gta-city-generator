use utf8;
use JSON;
use Encode;
use File::Slurp;
use Data::Dumper;
use File::Basename;

#read sounds.txt
%sounds=();
open(dd,"sounds.txt") or die "Can't open list: $!";
while(<dd>){
s/[\r\n]+//gs;
@p=split(/\t\|/,$_);
$sounds{$p[9]}=$_;
}
close(dd);

# find sources
@ats=`find -iname "atlas-*.mp4"`;
chomp(@ats);

foreach $root_file(@ats){
$dir=dirname($root_file);
$file_id=basename($root_file);
$file_id=~s/\.mp4$//s;
print "Processing fileid $file_id...\n";

$in_srt=$dir.'/'.$file_id.".srt";
$ru_srt=$dir.'/'.$file_id."-ru.json";
$en_srt=$dir.'/'.$file_id."-en.json";
if(!-e($ru_srt)){
$ru_srt=$dir.'/translated/'.$file_id."-ru.json";
}
if(!-e($en_srt)){
$en_srt=$dir.'/translated/'.$file_id."-en.json";
}

if(!-e($en_srt) || !-e($ru_srt)){next;} #skip!

@source_srt=read_srt($in_srt);

%status=();
%trans_ru=();
%trans_en=();
%ranges=();
my($subs,$tokens,$speakers)=read_json($ru_srt);
my($subs_en,$tokens_en,$speakers_en)=read_json($en_srt);
foreach $ru(@{$subs}){
($rust,$ruen,$rutext)=@{$ru};
$rust-=0.3;
$ruen+=2.0;
$oy1=$rust*$scale_pixms;
$oy2=$ruen*$scale_pixms;
@rel=();
foreach $src(@source_srt){
if(($src->[0]>=$rust && $src->[0]<=$ruen) || ($src->[1]>=$rust && $src->[1]<=$ruen)){
$srcfile=$src->[2];
push(@rel,$srcfile);
}
}
if(@rel==1){
$status{$rel[0]}="ok";
$ranges{$srcfile}=[$rust,$ruen];
print "ok [$rust,$ruen]\n";
}
if(@rel>1){
map{$status{$_}="bad"}@rel;
}
}

foreach $src(@source_srt){
$srcfile=$src->[2];
if(!exists $status{$srcfile}){$status{$srcfile}='notfound';}
}

# find translations in both languages
foreach $srcid(keys %status){
if($status{$srcid} ne 'ok'){next;} # we need only good translations
print "ok $srcfile\n";

if($srcid=~/sound_sfx\/([^\/]+)\/bank(\d+)\/sound_(\d+)\.wav \(([^:]+):(\d+):(\d+)\)/){
($src_package,$src_bank,$src_sound,$src_package2,$src_offset,$src_length)=($1,$2,$3,$4,$5,$6);
} else{
die "Can't parse src filename \"$srcfile\"!";
}

($st,$en)=@{$ranges{$srcid}};
print "searching in range ($st,$en)\n";
@entext=();
foreach $sen(@{$subs_en}){
if(($sen->[0]>=$st && $sen->[0]<=$en) || ($sen->[1]>=$st && $sen->[1]<=$en)){
push(@entext,$sen->[2]);
print "Found in en\n";
}
}
$entext=join(" ",@entext);

@rutext=();
foreach $sen(@{$subs}){
if(($sen->[0]>=$st && $sen->[0]<=$en) || ($sen->[1]>=$st && $sen->[1]<=$en)){
push(@rutext,$sen->[2]);
print "Found in ru\n";
}
}
$rutext=join(" ",@rutext);

print "$entext $rutext\n";
if(length($rutext)<1 || length($entext)<1){die "We have empty translation!!!";}

$srcfile=$srcid;
$srcfile=~s/ .*//s;
my($bank_id,$package_name,$bank_offset,$bank_size,$buffer_offset,$buffer_len,$loop_offset,$sample_rate,$headroom,$ourfilename,$modloader)=split(/\t\|/,$sounds{$srcfile});

print "$src_package eq $src_package2 && $src_offset==$buffer_offset && $src_length==$buffer_len ,$sounds{$srcfile} $srcfile\n";

if($src_package eq $src_package2 && $src_offset==$buffer_offset && $src_length==$buffer_len){
$sounds{$srcfile}=join("\t|",$sounds{$srcfile},$entext,$rutext);
} else {
die "something goes wrong";

}


}

}

write_file("sounds_labeled.txt",join("",map{"$_\n"}sort values %sounds));

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


