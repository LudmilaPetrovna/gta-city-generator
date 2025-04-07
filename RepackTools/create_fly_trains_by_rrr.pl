use File::Path qw(make_path remove_tree);
use File::Basename;

@plane_track_ids=(41,42,43,49);
$out_dir="out_fly_trains";
$out_track_id=1;

foreach $rrr_id(@plane_track_ids){

$rrr_file=sprintf("img_unpacked/carrec/carrec%03d.rrr",$rrr_id);

open(dd,$rrr_file) or die;
read(dd,$file,-s(dd));
close(dd);

print "Processing $rrr_file...\n";

$q=0;
$prev_time=-1;
@track=();

while($q*32<length($file)){
($time,$vel_x,$vel_y,$vel_z,$r_x,$r_y,$r_z,$top_x,$top_y,$top_z,$steering,$gas,$brake,$handbrake,$pos_x,$pos_y,$pos_z)=unpack("Isssccccccccccfff",substr($file,$q*32,32));
if($prev_time>$time||($time==0&&$pos_x==0&&$pos_y==0&&$pos_z==0)){last;}

push(@track,[$pos_x,$pos_y,$pos_z,$q==0?1:0]);

$q++;
$prev_time=$time;
}

# save file
$out_track_file=$out_dir."/data/Paths/tracks".($out_track_id>1?$out_track_id:"").".dat";
$out_track_dir=dirname($out_track_file);
make_path($out_track_dir);
$path_count=@track;
print "Writing train track to $out_track_file...\n";
open(oo,">".$out_track_file) or die $!;
print oo "$path_count\r\n";
print oo map{join(" ",@{$_})."\r\n"}@track;
close(oo);
$out_track_id++;

}
