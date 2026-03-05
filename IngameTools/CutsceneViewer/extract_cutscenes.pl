use Data::Dumper;

@want=qw/load_cutscene switch_widescreen force_weather_now force_weather set_area_visible set_char_coordinates set_char_heading load_mission_text set_time_of_day set_time_of_day set_current_char_weapon set_extra_colours set_fading_colour load_scene clear_area/;
#push(@want,qw/set_darkness_effect set_char_has_used_entry_exit/);







#switch gen
$count=156;
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

die;





$is_cj_only_char={};
map{$is_cj_only_char->{$_}=1}qw/set_char_coordinates set_char_coordinates_dont_warp_gang set_char_coordinates_no_offset set_char_heading set_current_char_weapon/;

$onclear="clear_cutscene|script_name";
$onwant=join("|",sort @want);

$is_multiple={};
$is_multiple{clear_area}=1;

$current={};

open(ii,"main[0].txt");
while(<ii>){
s/[\r\n]//sg;
if(/^([\dA-F]{4}):\s+(\S+)(.*)/){
($opcode,$command,$params)=($1,lc($2),$3);

if($command eq 'start_cutscene'){
print_scene();
next;
}

if($command=~/$onclear/){
print_scene();
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
if($cut_uid>=134){
print_scene();
}
next;
}


$current->{$command}=$params;


}

}
}


sub print_scene{

if($current_name){
print ":prepare_".(++$cut_uid)."\n";
print map{"$_$current->{$_}\n"}keys %{$current};
print "cutscene_name=$current_name;\n";
print "return\n";
print "\n";
}

$current={};
$current_name="";

}



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