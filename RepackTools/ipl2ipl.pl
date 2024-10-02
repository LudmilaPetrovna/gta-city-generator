open(dd,"/dev/shm/cache/gta3-src/lae2_stream0.ipl");
read(dd,$file,-s(dd));


if(substr($file,0,4) eq "bnry"){ #this is binary IPL
($items_count,$null,$null,$null,$cars_count,$null)=unpack("IIIIII",substr($file,4,24));
for($q=0;$q<6;$q++){
($offset,$size)=unpack("II",substr($file,28+$q*8,8));
if($q==0){$items_offset=$offset;}
if($q==4){$cars_offset=$offset;}
}
}

if($items_offset!=0x4C){die "Items offset must be 0x4c, your file may be broken";}
print STDERR "We have $items_count items, offset: $items_offset; we have $cars_count, offset: $cars_offset\n";


print "inst\n";
# structs by 40 bytes
for($q=0;$q<$items_count;$q++){
($pos_x,$pos_y,$pos_z,$rot_x,$rot_y,$rot_z,$rot_w,$obj_id,$interrior,$lod_index)=unpack("fffffffIII",substr($file,$items_offset+$q*40,40));

print join(", ",$obj_id,"model_name",$interrior,$pos_y,$pos_z,$rot_x,$rot_y,$rot_z,$rot_w,$lod_index)."\n";

}
print "end\n";
print "cull\n";
print "end\n";
print "path\n";
print "end\n";
print "grge\n";
print "end\n";
print "enex\n";
print "end\n";
print "pick\n";
print "end\n";
print "cars\n";

# structs by 48 bytes
for($q=0;$q<$cars_count;$q++){
($pos_x,$pos_y,$pos_z,$rot_angle,$obj_id,$color_primary,$color_secondary,$force_spawn,$alarm,$locked,
$unk1,$unk2)=unpack("ffffIIIIIIII",substr($file,$items_offset+$q*48,48));


print join(", ",$pos_x,$pos_y,$pos_z,$rot_angle,$obj_id,$color_primary,$color_secondary,$force_spawn,$alarm,$locked,$unk1,$unk2)."\n";

}
print "end\n";
print "jump\n";
print "end\n";
print "tcyc\n";
print "end\n";
print "auzo\n";
print "end\n";
print "mult\n";
print "end\n";



