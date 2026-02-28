use strict;
use JSON;
use File::Slurp;
use Data::Dumper;
use File::Path qw(make_path remove_tree);
use File::Basename;

sub find_exist_sounds{
my @res=();
my %res2=();
my $root='/dev/shm/Rdown/Glovemansion  Video  SiteRip 2012 - 2024/Video';
my @atlas=`find "$root" -iname "*-*.mp4"`;
my $at;
chomp(@atlas);

foreach $at(@atlas){
my $dir=dirname($at);
my $filename=basename($at);
my $fileid=$filename;
$fileid=~s/\.mp4$//s;
my $subfile=$dir.'/'.$fileid.'.srt';
my $transfile=$dir.'/translated/'.$fileid.'-ru-live.mp3';
my $transsize=-s($transfile);
#print "Processing $fileid (have $transsize bytes) in $dir...\n";
if(!-e($subfile)){next;}
if(!-e($transfile)){next;}


my @srt=read_srt($subfile);
foreach my $s(@srt){
my $t=$s->[2];
if($t=~/sound_sfx\/[^\/]+\/bank(\d+)\/sound_(\d+)\.wav \([^:]+:(\d+):(\d+)\)/){
my($bank_id,$sound_id,$offset,$len)=($1,$2,$3,$4);
push(@res,[$bank_id,$sound_id,$offset,$len]);
my $k=$bank_id.'-'.($sound_id*1);
$res2{$k}=$offset;
}
}
}
return(\%res2);
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

1
