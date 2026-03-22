#use strict;
use utf8;
use JSON;
use Encode;
use File::Slurp;
use Data::Dumper;
use File::Path qw(make_path remove_tree);
use File::Basename;
use Digest::CRC qw(crc64 crc32 crc16 crcccitt crc crc8 crcopenpgparmor);
require "./global_config.pl";

if(!$flac_repo){die "Global config is broken";}

binmode(STDOUT,":utf8");


sub calc_status{
my $root_file=shift;
my $src_lang=shift;
my $source_srt=read_srt($root_file.".srt");
my $ru_srt=read_srt($root_file."-ru.srt");
my $en_srt=read_srt($root_file."-$src_lang.srt");
my $ru_count=@{$ru_srt};
my $en_count=@{$en_srt};
my($src1,$ip,$q);
my $status={};
my $debug={};
my $join={};
my $ranges={};

my $fix=calc_fix_ranges($root_file."-$src_lang.json");
srt_fix($ru_srt);
srt_fix($en_srt);

my $ru_jump=calc_jump_table($ru_srt);
my $en_jump=calc_jump_table($en_srt);

#calc status
foreach $src1(@{$source_srt}){
my($sst,$sen,$srcfile)=@{$src1};
$srcfile=~s/ .*$//s;
#$srcfile.="anus".int($sst/1000);
$sst-=1.5;if($sst<0){$sst=0;}
$sen+=2.5;

$status->{$srcfile}='unresolved';

if($srcfile=~/^IS_GAP/){
$status->{$srcfile}='gap';
}

$ip=$ru_jump->[int($sst/5)]-5;
if($ip<0){$ip=0;}
for($q=$ip;$q<$ru_count;$q++){
my($rust,$ruen,$rutext)=@{$ru_srt->[$q]};
if(($rust>=$sst && $rust<=$sen) && ($ruen>=$sst && $ruen<=$sen) && $status->{$srcfile} eq 'unresolved'){
$status->{$srcfile}='ok';
$debug->{$srcfile}="in src ($sst,$sen) found ($rust,$ruen,$rutext)";
$ranges->{$srcfile}=[$sst,$sen];
}
if(($rust<$sst && $ruen>=$sst) || ($ruen>$sen && $rust<$sen)){
$status->{$srcfile}='bad';
$debug->{$srcfile}="bad: in src ($sst,$sen) ($rust,$ruen,$rutext)";
next;
}

if($rust>$sen){last;}
}

}

# calc join

foreach my $srcfile(sort keys %{$status}){
if($status->{$srcfile} ne 'ok'){next;} # we need only good translations

my($cap_st,$cap_en)=@{$ranges->{$srcfile}};
my @texts=();
my $ent;
foreach $ent(@{$en_srt}){
if(($ent->[0]>=$cap_st && $ent->[0]<=$cap_en) && ($ent->[1]>=$cap_st && $ent->[1]<=$cap_en)){
push(@texts,$ent->[2]);
}
}
my $entext=join(" ",@texts);

@texts=();
foreach $ent(@{$ru_srt}){
if(($ent->[0]>=$cap_st && $ent->[0]<=$cap_en) && ($ent->[1]>=$cap_st && $ent->[1]<=$cap_en)){
push(@texts,$ent->[2]);
}
if($ent->[1]>$cap_en){last;}
}
my $rutext=join(" ",@texts);

###if(length($rutext)<1 || length($entext)<1){next;die "We have empty translation!!!";}

if($rutext!~/[а-яА-Я]/){
$status->{$srcfile}='norus';
}

$join->{$srcfile}=[$cap_st,$cap_en,$entext,$rutext];

}

return($status,$debug,$join);
}


sub print_join_entry{
my $join=shift;
my $status=shift;
my $srcfile=shift;
my($cap_st,$cap_en,$entext,$rutext)=@{$join->{$srcfile}};
my($stt,$ent)=map{s2ssa_time($_)}($cap_st,$cap_en);
printf("%s -----> %-3s | %s -> %s | %-8.2f -> %-8.2f | %-2d | %-3d | %-70s | %-70s\n",$srcfile,$status->{$srcfile},$stt,$ent,$cap_st,$cap_en,int($cap_en-$cap_st+.5),int(($cap_en-$cap_st)/((length($entext)+length($rutext))/2)*10),$entext,$rutext);
}

sub calc_jump_table{
my $sub=shift;
my $jump=[];
my $len=@{$sub};
my $q;
my $i;
#precalc jump tables;
for($q=0;$q<$len;$q++){
$i=int($sub->[$q]->[0]/5);
if($i<0){$i=0;}
if(!defined $jump->[$i]){
$jump->[$i]=$q;
}
}
my $lv=0;
foreach(@{$jump}){
if(!defined $_){$_=$lv;} else {$lv=$_;}
}
return($jump);
}




sub calc_fix_ranges{
my $filename=shift;
my %fixrange=();
my ($en_sub,$en_tok,$en_spk)=read_json($filename);
my $en_count=@{$en_sub};
my($q,$st,$en,$text,$toks,$lt);
for($q=0;$q<$en_count;$q++){
($st,$en,$text,$toks)=@{$en_sub->[$q]};
$lt=$toks->[-1];
my($tst,$ten,$text)=@{$lt};
if($ten-$tst>2){ #no more than 2 seconds per token
$fixrange{int($st)."_".int($en)}=[$st,$tst+length($text)*.1+.3];
}
}
return(\%fixrange);
}

sub srt_fix{
my($srt,$fix)=@_;
my $key;
foreach(@{$srt}){
$key=int($_->[0])."_".int($_->[1]);
if(exists $fix->{$key}){
$_->[0]=$fix->{$key}->[0];
$_->[1]=$fix->{$key}->[1];
}
}
}


sub read_json{
my $json_file=shift;
my $json=decode_json(read_file($json_file));
my $subs=[];
my $tokens=[];
my $curtokens=[];
my $speakers=[];
my $cs=-1;
my $p=0;
foreach(@{$json->{subtitles}}){
$subs->[$p]=[$_->{startMs}/1000,($_->{startMs}+$_->{durationMs})/1000,$_->{text}];
$speakers->[$p]=[$_->{startMs}/1000,($_->{startMs}+$_->{durationMs})/1000,$_->{speakerId}];
$curtokens=[];
if(defined $_->{tokens}){
foreach my $t(@{$_->{tokens}}){
push(@{$tokens},[$t->{startMs}/1000,($t->{startMs}+$t->{durationMs})/1000,$t->{text}]);
push(@{$curtokens},[$t->{startMs}/1000,($t->{startMs}+$t->{durationMs})/1000,$t->{text}]);
}
$subs->[$p]->[3]=$curtokens;
}
$p++;
}
return($subs,$tokens,$speakers);
}


sub read_srt{
my $filename=shift;
my $file=decode_utf8(read_file($filename));
my $srtnum=1;
my $wait=0;
$file=~s/\r//sg;

my $st;
my $en;
my $text;
my @res=();
my $l=0;
foreach(split(/\n/,$file)){
$l++;
if($wait==0 && $_ eq ''){
print STDERR "SRT: $filename: empty string, not error\n";
next;
}
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
die "Wrong srt format in $filename, wait:$wait, line $l \"$_\"";
}
if($wait==2 && $text){
push(@res,[$st,$en,$text]);
}
return(\@res);
}


sub print_srt{
my $srt=shift;
my $sub;
foreach $sub(@{$srt}){
my($st,$en,$text)=@{$sub};
my($stt,$ent)=map{s2ssa_time($_)}($st,$en);
printf("%9s -> %9s | %8.3f -> %8.3f | %6.3f | %s\n",$stt,$ent,$st,$en,$en-$st,$text);
}
}





sub s2ssa_time{
my $s=shift;
#     0    1    2     3     4    5     6     7     8
my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = gmtime($s);
my $ii=$sec+$min*60+$hour*3600;
return sprintf("%d:%02d:%02d.%02d",$hour,$min,$sec,int(($s-$ii)*100));
}

sub s2time{
my $s=shift;
#     0    1    2     3     4    5     6     7     8
my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = gmtime($s);
if($hour==0 && $min==0){return sprintf("%ds",$sec);}
if($hour==0){return sprintf("%02d:%02d",$min,$sec);}
return sprintf("%02d:%02d:%02d:%02d",$mday-1,$hour,$min,$sec);
}

sub s2srt{
my $s=shift;
#     0    1    2     3     4    5     6     7     8
my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = gmtime($s);
my $ii=$sec+$min*60+$hour*3600;
return sprintf("%02d:%02d:%02d,%03d",$hour,$min,$sec,int(($s-$ii)*1000));
}
