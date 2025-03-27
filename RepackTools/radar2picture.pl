
=pod
`rm -rf txd_unpacked`;
`mkdir txd_unpacked`;
=cut
for($q=0;$q<144;$q++){
$src_filename=sprintf("./img_unpacked/models/gta3/radar%.2d.txd",$q);
$src_filename=sprintf("./radar_orig/radar%.2d.txd",$q);
print "Unpacking $src_filename\n";
print `perl /dev/shm/gta-city-generator/Lesson3/txd_unpacker.pl $src_filename txd_unpacked`;
}


$list="";
for($q=0;$q<144;$q++){
$src_filename=sprintf("./txd_unpacked/png/radar%.2d.png",$q);
$list.=" $src_filename";
}

`montage -tile 12x -geometry 128x128+0+0 $list radar-glued.png`;

print ` identify radar-glued.png`;
