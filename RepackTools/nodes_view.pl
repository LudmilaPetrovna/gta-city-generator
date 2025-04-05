use GD;
use Digest::CRC qw(crc64 crc32 crc16);

require "./gxt_read.pl";

$wholemap_size=4096;
$radar_tile=256;
$min_width=5;
$infozon="/dev/shm/gta-micro/Clean/data/info.zon";


$pic=GD::Image->new($wholemap_size,$wholemap_size,1);
$pic->saveAlpha(0);
$pic->alphaBlending(1);
$pic->setAntiAliased(0);

%snode=();
%nnode=();
@joints=();
%links=();



# todo:
# add semaphores icons at intersections
# add parking icons
# +draw trains path
# +draw RRR-tracks
# +draw region names
# +draw radar 12x12 bounds
# +draw nodes 8x8 bounds


print STDERR "# add background image...\n";
$bg=GD::Image->newFromPng("nodes_bgmap512.png",1);
$pic->copyResampled($bg,0,0,0,0,$wholemap_size,$wholemap_size,$bg->getBounds);


draw_zones_bounds(0x10);
#draw_nodes_bounds();

print STDERR "# dim background image...\n";
$pic->alphaBlending(1);
$pic->filledRectangle(0,0,$wholemap_size,$wholemap_size,0x50000000);
$pic->alphaBlending(0);

draw_pre_recorded();
draw_trains_tracks();

read_nodes_graph();
#draw_navi_points();
draw_nodes_joints();
draw_zones_bounds(0x65);

save_pic();

#generate_radar_map();


@colorama=();

#RGRGBRGB
#76543210
for($q=0;$q<256;$q++){
$R=((($q>>2)&1)<<2)|((($q>>5)&1)<<1)|(($q>>7)&1);
$G=((($q>>1)&1)<<2)|((($q>>4)&1)<<1)|(($q>>6)&1);
$B=(($q&1)<<1)|((($q>>3)&1));
$colorama[$q^0xFF]=(int($R/7*255)<<16)|(int($G/7*255)<<8)|(int($B/3*255));
#$ox=$q%16;
#$oy=int($q/16);
#$pic->filledRectangle($ox*32,$oy*32,$ox*32+31,$oy*32+31,$colorama[$q]);
}


for($q=0;$q<256;$q++){
}


sub read_nodes_graph{

open(sn,">nodes_simple.txt");

for($file_id=0;$file_id<=63;$file_id++){
#for($file_id=26;$file_id<=26;$file_id++){


open(dd,"img_unpacked/gta3/nodes${file_id}.dat") or die $!;
read(dd,$file,-s(dd));
close(dd);


($count_nodes,$count_vehnodes,$count_pednodes,$count_navinodes,$count_links)=unpack("IIIII",substr($file,0,20));

print "We have nodes: ($count_nodes,$count_vehnodes,$count_pednodes,$count_navinodes,$count_links)\n";

if($count_navinodes*1.1<$count_vehnodes){
die "Strange: navipoints less than vehnodes $count_navinodes<$count_vehnodes";
}

if($count_navinodes>$count_vehnodes*1.1){
die "Strange: navipoints more than 110\% of vehnodes! $count_navinodes>$count_vehnodes*1.1";
}


for($q=0;$q<$count_nodes;$q++){
($unused1,$zero2,$pos_x,$pos_y,$pos_z,$cost_7FFE,$link_id,$area_id,$node_id,$node_width,$floodfill,$flags)=unpack("IIssssSSSCCI",substr($file,20+$q*28,28));
=pod
4b - UINT32   - Mem Address, unused
4b - UINT32   - always zero, unused
6b - INT16[3] - Position (XYZ), see below
2b - INT16    - heuristic cost, always 0x7FFE, used internally to calculate routes
2b - UINT16   - Link ID
2b - UINT16   - Area ID (same as in filename)
2b - UINT16   - Node ID (increments by 1)
1b - UINT8    - Path Width
1b - UINT8    - Flood Fill, used in route calculations
4b - UINT32   - Flags
=cut

if($zero2!=0 || $cost_7FFE!=0x7FFE || $area_id!=$file_id || $node_id!=$q){
die "Strange values in node $zero2!=0 || $cost_7FFE!=0x7FFE  $area_id!=$file_id || $node_id!=$q";
}

if($count_nodes != $count_vehnodes+$count_pednodes){
die "Total nodes $count_nodes must be sum of veh+ped nodes $count_vehnodes+$count_pednodes";
}

if($link_id>=$count_links){
die "link_id out of range $link_id>=$count_links";
}

$count_node_links=$flags&0x0F;
$traffic_level=($flags>>4)&0x7;
$spawn=($flags>>16)&0x7;
$zeros=$flags>>24;
if($zeros!=0 || (($flags>>9)&1) || (($flags>>11)&1) || (($flags>>14)&1) || (($flags>>15)&1) || (($flags>>22)&1)){
die "Wrong node flags!";
}

$flags&=0xFFF8FFFF;

$node_width/=8;
$pos_x/=8;
$pos_y/=8;
$pos_z/=8;

print sn join("\t",$pos_x,$pos_y,$pos_z,$node_width)."\n";

$pos_x=int(($pos_x+3000)/6000*$wholemap_size);
$pos_y=int((3000-$pos_y)/6000*$wholemap_size);
$node_width=$node_width/6000*$wholemap_size;
if($node_width<$min_width){$node_width=$min_width;}

$is_vehicle=$node_id<$count_vehnodes?1:0;

$color=$is_vehicle?0x77aaff:0xFFFF00;

if(($flags>>8)&1){$color=0xAAAA00;} #emergency
if(($flags>>7)&1){$color=0xFFFFFF;} #boats
if(($flags>>13)&1){$color=0x0000FF;} #highway
if(($flags>>21)&1){$color=0xCCCCCC;} #parking

#$color=0;
if(($flags>>20)&1){$color=0xFFFF00;} #cityblock
if(($flags>>23)&1){$color=0xFFFF00;} #cityblock
if(($flags>>6)&1){$color=0x00FF00;} #road


$snode{"$area_id:$node_id"}=[$pos_x,$pos_y,$pos_z,$node_width];
push(@joints,[$area_id,$node_id,$link_id,$count_node_links,$color,$is_vehicle,$pos_z]);

#print "id:$node_id,link:$link_id,width:$node_width,links:$count_node_links,traf:$traffic_level,spawn:$spawn\t".sprintf("%b,\t%032b",$floodfill,$flags)."\n";
$pic->setPixel($pos_x,$pos_y,0xFFFFFF^$flags);
}

# read NAVI nodes
for($q=0;$q<$count_navinodes;$q++){
=pod
4b - INT16[2] - Position (XY), see below
2b - UINT16   - Area ID
2b - UINT16   - Node ID
2b - INT8[2]  - Direction (XY), see below
4b - UINT32   - Flags
=cut
($pos_x,$pos_y,$area_id,$node_id,$dir_x,$dir_y,$flags)=unpack("ssSSccI",substr($file,20+$count_nodes*28+$q*14,14));

$pos_x=int(($pos_x/8+3000)/6000*$wholemap_size);
$pos_y=int((3000-$pos_y/8)/6000*$wholemap_size);
$dir_x/=100;
$dir_y/=100;

=pod
 0- 7 - path node width, usually a copy of the linked node's path width (byte)
 8-10 - number of left lanes
11-13 - number of right lanes
   14 - traffic light direction behavior
   15 - zero/unused
16,17 - traffic light behavior
   18 - train crossing
19-31 - zero/unused
=cut

$node_width=$flags&0xFF;
$lanes_left=($flags>>8)&7;
$lanes_right=($flags>>11)&7;
$traf_dir=($flags>>14)&1;
$traf_light=($flags>>15)&3;
$train_cross=($flags>>17)&1;
$zero=($flags>>18);
if($zero!=0){die "strange data in NAVI node flags!";}

$node_width=$node_width/6000*$wholemap_size;

$nnode{"$file_id:$q"}=[$pos_x,$pos_y,$node_width];
#print "navi $file_id:$q: (area_to:$area_id,node_to:$node_id,vec:${dir_x}x${dir_y},width:$node_width,lanes:$lanes_left/$lanes_right,traf:$traf_dir/$traf_light,traincross:$train_cross)\n";

}


# links
for($q=0;$q<$count_links;$q++){
=pod
seg3 (4 bytes)
2b - UINT16 - Area ID
2b - UINT16 - Node ID
seg5 (2 bytes)
2b - UINT16 - lower 10 bit are the Navi Node ID, upper 6 bit the corresponding Area ID
seg6 (1 byte)
1b - UINT8 - Length
=cut
($area_id,$node_id)=unpack("SS",substr($file,20+$count_nodes*28+$count_navinodes*14+$q*4,4));
$packed1=unpack("S",substr($file,20+$count_nodes*28+$count_navinodes*14+$count_links*4+768+$q*2,2));
$len=unpack("C",substr($file,20+$count_nodes*28+$count_navinodes*14+$count_links*4+768+$count_links*2+$q,1));

$area_id2=($packed1>>10)&0x3f;
$node_id2=($packed1&0x3FF);

#print "$q/$count_links:($area_id,$node_id,$area_id2,$node_id2,$len)\n";

$links{$file_id}[$q]=[$area_id,"$area_id:$node_id","$area_id2:$node_id2",$len];

}

# filler
$filler=substr($file,20+$count_nodes*28+$count_navinodes*14+$count_links*4,768);
$filler_mustbe="\xFF\xFF\x00\x00" x 192;
if($filler ne $filler_mustbe){die "In original game files exists strange filler, this filler broken in your files!";}







}

}

sub draw_navi_points{


# add navi points
foreach(keys %nnode){
$pic->setPixel($nnode{$_}->[0],$nnode{$_}->[1],0xFF0000);
$w=$nnode{$_}->[2]/2;
if($w<$min_width){$w=$min_width;}
$pic->filledEllipse($nnode{$_}->[0],$nnode{$_}->[1],$w,$w,0xFF0000);
}

foreach(keys %snode){
$pic->setPixel($snode{$_}->[0],$snode{$_}->[1],0x00FF00);
$w=$nnode{$_}->[2]/2;
if($w<$min_width){$w=$min_width;}
$pic->filledEllipse($snode{$_}->[0],$snode{$_}->[1],$w,$w,0x00FF00);
}

}

sub draw_nodes_joints{

print STDERR "sorting by Z-order...\n";
#@joints=sort{$a->[6] <=> $b->[6]}@joints;

print STDERR "drawing joints...\n";
for($w=0;$w<@joints;$w++){
($parent_area,$parent_id,$links_offset,$links_node_count,$color,$is_vehicle,$pos_z)=@{$joints[$w]};
$l1=$snode{$parent_area.':'.$parent_id};
for($q=0;$q<$links_node_count;$q++){
$pointer=$links{$parent_area}->[$links_offset+$q]->[1];
if(!exists $snode{$pointer}){
print "Invalid pointer to $pointer\n";
next;
}
$l2=$snode{$pointer};

$node_width=$l1->[3];

$pic->alphaBlending(1);
$pic->setThickness($node_width);
$pic->line($l1->[0],$l1->[1],$l2->[0],$l2->[1],$color|0x50000000);
$pic->alphaBlending(0);
$pic->setThickness(1);
$pic->line($l1->[0],$l1->[1],$l2->[0],$l2->[1],$color);

if(!$is_vehicle){next;}
$pointer=$links{$parent_area}->[$links_offset+$q]->[2];
#print "second pointer $parent_area:$parent_id to  $pointer\n";
if(!exists $nnode{$pointer}){
print "Invalid pointer to $pointer\n";
next;
}
$l3=$nnode{$pointer};
#$pic->alphaBlending(1);
#$pic->line($l1->[0],$l1->[1],$l3->[0],$l3->[1],0x5000FFFF);
#$pic->line($l2->[0],$l2->[1],$l3->[0],$l3->[1],0x5000FF00);


}
}

}



# add navi points
foreach(keys %nnode){
#$pic->setPixel($nnode{$_}->[0],$nnode{$_}->[1],0xFF0000);
}

foreach(keys %snode){
#$pic->setPixel($snode{$_}->[0],$snode{$_}->[1],0x00FF00);
}




sub save_pic{
print STDERR "writing nodes_pic.png...\n";
open(oo,">nodes_pic.png");
print oo $pic->png(9);
close(oo);
}



##############

sub generate_radar_map{
# generate radar map
$tile=GD::Image->new($radar_tile,$radar_tile,1);
$tile->saveAlpha(0);
$tile->alphaBlending(0);
$tile->setAntiAliased(0);

$step=$wholemap_size/12;
for($q=0;$q<144;$q++){
$out_filename=sprintf("newcol/frames%.4d.png",$q);
$ox=$q%12;
$oy=int($q/12);
$tile->copyResampled($pic,0,0,int($ox*$step),int($oy*$step),$radar_tile,$radar_tile,$step,$step);
print "writing $out_filename...\n";
open(oo,">$out_filename") or die $!;
print oo $tile->png(9);
close(oo);
}

}


sub draw_radar_bounds{
# draw radar 12x12 bounds
$step=$wholemap_size/12;
$pic->alphaBlending(1);
for($q=0;$q<144;$q++){
$ox=int(($q%12)*$step);
$oy=int(int($q/12)*$step);
$filename=sprintf("radar%02d.txd",$q);
$pic->filledRectangle($ox,$oy,$ox+$step,$oy+$step,0x7E0000000|(((($q%12)^int($q/12))&1)?0xAA88AA:0x008800));
$pic->rectangle($ox,$oy,$ox+$step,$oy+$step,0xAAFFAA);
$pic->string(gdSmallFont,$ox+4,$oy+$step-12,$filename,0x000000);
$pic->string(gdSmallFont,$ox+3,$oy+$step-13,$filename,0xAAFFAA);
}
$pic->alphaBlending(0);
}


sub draw_nodes_bounds{
# draw nodes 8x8 bounds
$step=$wholemap_size/8;
$pic->alphaBlending(1);
$pic->setThickness(1);
for($q=0;$q<64;$q++){
$ox=int(($q%8)*$step);
$oy=int((7-int($q/8))*$step);
$filename="nodes${q}.dat";
$pic->filledRectangle($ox,$oy,$ox+$step,$oy+$step,0x7E0000000|(((($q%8)^int($q/8))&1)?0xFFFFFF:0x000000));
$pic->rectangle($ox,$oy,$ox+$step,$oy+$step,0xFFFFFF);
$pic->string(gdSmallFont,$ox+4,$oy+2,$filename,0x000000);
$pic->string(gdSmallFont,$ox+3,$oy+1,$filename,0xFFFFFF);
}
$pic->alphaBlending(0);
}


sub draw_zones_bounds{
my $opacity=shift;
my $lpic=GD::Image->new(500,50,1);
$lpic->saveAlpha(1);
$pic->alphaBlending(1);
$pic->setThickness(1);

$opacity<<=24;

open(dd,$infozon) or die;
while(<dd>){
if(/^(zone|end)/){next;}
($zone_id,$type,$x1,$y1,$z1,$x2,$y2,$z2,$level,$label)=split(/\s*,\s*/);
$label=~s/\s//sg;
$label=resolve_GXT($label);

$color=int(rand()*256) | (int(rand()*256)<<8) | (int(rand()*256)<<16);
#$opacity=0x70;
$filled_color=$opacity|$color;

$x1=($x1+3000)/6000*$wholemap_size;
$y1=(3000-$y1)/6000*$wholemap_size;

$x2=($x2+3000)/6000*$wholemap_size;
$y2=(3000-$y2)/6000*$wholemap_size;

#$pic->filledRectangle($x1,$y1,$x2,$y2,$filled_color);
#$pic->rectangle($x1,$y1,$x2,$y2,$color);
#$pic->string(gdSmallFont,$x1+3,$y2+3,$label,0);
#$pic->string(gdSmallFont,$x1+2,$y2+2,$label,$color);

$str_width=6*length($label)+2;
$str_height=12+2;
$str_aspect=$str_width/$str_height;

$new_width=abs($x2-$x1);
$new_height=$new_width/$str_aspect;

$lpic->alphaBlending(0);
$lpic->filledRectangle(0,0,500,50,0x7FFFFFFF);
$lpic->alphaBlending(1);


$lpic->string(gdSmallFont,2,2,$label,$opacity);
$lpic->string(gdSmallFont,1,2,$label,$opacity);
$lpic->string(gdSmallFont,2,1,$label,$opacity);
$lpic->string(gdSmallFont,1,1,$label,$opacity|$color);

$pic->alphaBlending(1);
$pic->copyResampled($lpic,$x1,$y2+abs($y1-$y2)/2-$new_height/2,0,0,$new_width,$new_height,$str_width,$str_height);
}

close(dd);
$pic->alphaBlending(0);
}


sub draw_pre_recorded{
print STDERR "# add pre-recorded path...\n";
$pic->alphaBlending(0);

for($w=0;$w<1000;$w++){
$rrr_file=sprintf("img_unpacked/carrec/carrec%03d.rrr",$w);
if(!-s($rrr_file)){next;}
open(dd,$rrr_file) or die;
read(dd,$file,-s(dd));
close(dd);

print "Processing $rrr_file...\n";

$q=0;
$prev_time=-1;
$prev_pos_x=0;
$prev_pos_y=0;
$color=0xFF00FF;
$color_seed=crc32($rrr_file)&0xFFFFFF;
$color^=$color_seed&0x3f7f3f;
while($q*32<length($file)){
($time,$vel_x,$vel_y,$vel_z,$r_x,$r_y,$r_z,$top_x,$top_y,$top_z,$steering,$gas,$brake,$handbrake,$pos_x,$pos_y,$pos_z)=unpack("Isssccccccccccfff",substr($file,$q*32,32));
if($prev_time>$time||($time==0&&$pos_x==0&&$pos_y==0&&$pos_z==0)){last;}

#print "($time,$vel_x,$vel_y,$vel_z,$r_x,$r_y,$r_z,$top_x,$top_y,$top_z,$steering,$gas,$brake,$handbrake,$pos_x,$pos_y,$pos_z)\n";

$pos_x=($pos_x+3000)/6000*$wholemap_size;
$pos_y=(3000-$pos_y)/6000*$wholemap_size;

if($q){
$pic->setThickness($min_width+2);
$pic->line($prev_pos_x,$prev_pos_y,$pos_x,$pos_y,0);
$pic->setThickness($min_width);
$pic->line($prev_pos_x,$prev_pos_y,$pos_x,$pos_y,$color);
}

$q++;
$prev_time=$time;
$prev_pos_x=$pos_x;
$prev_pos_y=$pos_y;
}
}

$pic->alphaBlending(0);
}


sub draw_trains_tracks{
print STDERR "# add train tracks...\n";
$pic->alphaBlending(0);
$pic->setThickness($min_width*2);

for($w=0;$w<=4;$w++){
$dat_file="data/Paths/tracks".($w>0?$w:"").".dat";
if(!-s($dat_file)){next;}
open(dd,$dat_file) or die;
$records=<dd>;
$records=~s/\s//sg;
print "Processing $dat_file, here $records records...\n";

$q=0;
$prev_pos_x=0;
$prev_pos_y=0;
$train_color=0xAA0000|(($w*50)<<8);
for($q=0;$q<$records;$q++){
$line=<dd>;
($pos_x,$pos_y,$pos_z,$station)=split(/\s/,$line);

$pos_x=($pos_x+3000)/6000*$wholemap_size;
$pos_y=(3000-$pos_y)/6000*$wholemap_size;
$pic->filledEllipse($pos_x,$pos_y,25,25,0xBB0000);
$pic->filledEllipse($pos_x,$pos_y,20,20,$train_color);

if($station){
$pic->filledEllipse($pos_x,$pos_y,50,50,0xAA8888);
}

if($q){
$pic->line($prev_pos_x,$prev_pos_y,$pos_x,$pos_y,$train_color);
} else {
$origin_x=$pos_x;
$origin_y=$pos_y;
}



$prev_pos_x=$pos_x;
$prev_pos_y=$pos_y;
}
while(!eof(dd)){
print <dd>;
}
close(dd);
$pic->line($prev_pos_x,$prev_pos_y,$origin_x,$origin_y,$train_color);
}

$pic->alphaBlending(0);
}
