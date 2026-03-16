use Data::Dumper;
use File::Slurp;

%cutdata=();
%cutcode=();
%cutorder=();
@id2cut=();
$cutcurid=0;

$is_cj_only_char={};
map{$is_cj_only_char->{$_}=1}qw/set_char_coordinates set_char_coordinates_dont_warp_gang set_char_coordinates_no_offset set_char_heading set_current_char_weapon/;

@want=qw/load_cutscene switch_widescreen force_weather_now force_weather set_area_visible set_char_coordinates set_char_heading load_mission_text set_time_of_day set_time_of_day set_current_char_weapon set_extra_colours set_fading_colour load_scene clear_area/;
#push(@want,qw/set_darkness_effect set_char_has_used_entry_exit/);

$onclear="clear_cutscene|script_name";
$onwant=join("|",sort @want);
$is_multiple={};
$is_multiple{clear_area}=1;


# step 1: read cutscenes info from cuts.img (unpacked in 'cuts' dir)
read_cuts_dir();

# step 2: read decompiled main script
parse_script();

#add ids
foreach $cutid(keys %cutdata){
if(!exists $cutorder{$cutid}){print STDERR "Can't find order for $cutid scene! gen new $cutcurid\n";$cutorder{$cutid}=$cutcurid++;}
if(!exists $cutcode{$cutid}){
print STDERR "Can't find code initialization for $cutid scene! This scene may be very simple\n";
$code="load_scene ".$cutdata{$cutid}->[1]."\n";
} else {
$code=$cutcode{$cutid};
}
$code=':prepare_'.($cutorder{$cutid}+1)."\n".$code;
$code.="cutscene_name='".uc($cutid)."'\n";
$code.="cutscene_dur=".$cutdata{$cutid}->[0]."\n";
$code.="return\n\n";
$cutcode{$cutid}=$code;
print "order: $cutid $cutorder{$cutid}\n";
$id2cut[$cutorder{$cutid}]=$cutid;
}

# step 3: produce jump table

#switch gen
$count=$cutcurid;
$maxswitch=64;
$mswcount=int($count/64+.999);
@ids=();
$pos=0;
while($pos<$count){
$len=$count-$pos;
if($len>$maxswitch){$len=$maxswitch;}
push(@ids,[$pos..($pos+$len-1)]);
$pos+=$len;
}


print 'int cutscene_id_ms=cutscene_id/64'."\n";
print '0871: switch_start cutscene_id_ms '.$slen.' ';
for($q=0;$q<8;$q++){
$case=$q;
$label='@my_switch_'.($case);
if($case>=$mswcount){
$case=-1;
$label='@my_switch_0';
}
print " $case $label";
}
print "\n\n";

for($e=0;$e<$mswcount;$e++){
print ":my_switch_$e\n";

$num=$ids[$e]->[0];
$snum=0;
$slen=@{$ids[$e]};
$is_done=0;
for($w=0;!$is_done;$w++){
if($w==0){
print '0871: switch_start cutscene_id '.$slen.' ';
} else {
print '0872: switch_continued ';
}
for($q=0;$q<($w==0?8:9);$q++){
$case=$num;
$label='@prepare_'.($case+1);
if($case>=$count || $snum>=$maxswitch){
$case=-1;
$label='@prepare_1';
$is_done=1;
}
print " $case $label";
$num++;
$snum++;
}
print "\n";

}
}

for($q=0;$q<$cutcurid;$q++){
$cutid=$id2cut[$q];
print "// $q $cutid\n";
print $cutcode{$cutid};
}

die;












=pod


01B6: force_weather_now {type} WeatherType.SunnyLa
04BB: set_area_visible {areaId} 5
00A1: set_char_coordinates $3 {x} 2175.4116 {y} 1681.5483 {z} 9.8203
0173: set_char_heading $3 {heading} 90.0
054C: load_mission_text {tableName} 'HEIST5'
00C0: set_time_of_day {hours} 0 {minutes} 0
01B9: set_current_char_weapon $3 {weaponType} WeaponType.Unarmed
04F9: set_extra_colours {color} 4 {fade} False
0169: set_fading_colour {r} 0 {g} 0 {b} 0
03CB: load_scene {x} 2028.9316 {y} 1023.2923 {z} 9.813
01B5: force_weather {type} WeatherType.SunnyVegas
(mult)0395: clear_area {x} 419.6919 {y} 2529.9143 {z} 16.6612 {radius} 6.86 {clearParticles} False

????
0924: set_darkness_effect {enable} True {pitchBlack} -1
08AD: set_char_has_used_entry_exit $3 {x} 2016.4222 {y} 1017.1024 {radius} 10.0

clear:
02EA: clear_cutscene
02E4: load_cutscene {name} 'D10_ALT'
03A4: script_name {name} 'DES10'

bad:
00C0: set_time_of_day {hours} 359@ {minutes} 360@
=cut


sub read_cuts_dir{
# read cutscenes info
my @cuts=grep{/\.ifp$/i}read_dir("cuts");
foreach $cutid(@cuts){
$cutid=~s/\.ifp$//si;
#print "Reading cutscene $cutid info...\n";

$timemax=0;

# read cut-file
$cut_file='cuts/'.$cutid.'.cut';
$in_text=0;
$in_info=0;
foreach(read_file($cut_file)){
s/[\r\n]//sg;

if(/^end$/){
$in_text=0;
$in_info=0;
next;
}

if(/^info$/){
$in_info=1;
next;
}

if(/^text$/){
$in_text=1;
next;
}

if($in_info){
@p=split(/\s+/);
if($p[0] eq "offset"){$offset=join(" ",@p[1..3]);}

}

if($in_text){
($timestart,$timelen,$text)=split(/\s*,\s*/,$_,3);
$timeend=$timestart+$timelen;
if($timemax<$timeend){$timemax=$timeend;}
}


}


#read dat-files
foreach(read_file('cuts/'.$cutid.'.dat')){
s/[\r\n]//sg;
@p=split(/\s*,\s*/);

if(@p>3 && $p[0]=~/^([\d\.\-]+)/){
$timecode=int($1*1000);
if($timemax<$timecode){$timemax=$timecode;}
}


}

$cutdata{$cutid}=[$timemax,$offset];
#print "max time: $timemax\n";


}

#print Dumper(\%cutdata);
}


sub parse_script{


$current={};

open(ii,"main[0].txt");
while(<ii>){
s/[\r\n]//sg;
if(/^([\dA-F]{4}):\s+(\S+)(.*)/){
($opcode,$command,$params)=($1,lc($2),$3);

if($command eq 'start_cutscene'){
gen_scene_code();
next;
}

if($command=~/$onclear/){
gen_scene_code();
next;
}

if($command=~/$onwant/){
if($command eq 'force_weather'){$command='force_weather_now';}
if($is_cj_only_char->{$command} && index($params,' $3 ')!=0){next;}
if(index($params,'@')>=0){next;}
if($params=~/\$(\d+)/){
if($1 != 3 ){
#print "skipping variable $command$params\n";
next;
}
}
if($command eq 'set_current_char_weapon' && index($params,'WeaponType.Unarmed')<0){next;}

if($command eq 'load_cutscene'){
$params=~s/\s+\{name\}\s*//s;
$current_name=$params;
$cutid=lc($current_name);
$cutid=~s/[\"\']+//sg;
if(!exists $cutorder{$cutid}){
$cutorder{$cutid}=$cutcurid++;
#print "DEBUG: $cutid $cutorder{$cutid}\n";
}
next;
}


$current->{$command}=$params;


}

}
}


}

sub gen_scene_code{
my $code="";
if($current_name){

if(!exists $cutdata{$cutid}){die "can't find data entry for $cutid $cutdata{$cutid}";}

if($current->{set_area_visible}){ #always be first
$code='set_area_visible'.$current->{set_area_visible}."\n";
delete $current->{set_area_visible};
}

if(!exists $current->{load_scene} && !exists $current->{load_scene_in_direction}){
$current->{load_scene}=' '.$cutdata{$cutid}->[1];
}
$code.=join("",map{"$_$current->{$_}\n"}sort keys %{$current});
$cutcode{$cutid}=$code;
}
$current={};
$current_name="";
}

