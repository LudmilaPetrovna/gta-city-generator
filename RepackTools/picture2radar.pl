
`rm -rf out_radar`;
`mkdir out_radar`;


`rm -rf tmp`;
`mkdir tmp`;

`convert picture.jpg -resize 768x768^ -gravity center -extent 768x768+0+0 picture-resized.png`;
`convert picture-resized.png -crop 64x64 tmp/frames.png`;

$list="";
for($q=0;$q<144;$q++){
$src_filename=sprintf("./tmp/frames-%d.png",$q);
$src_filename=sprintf("radar_render/frames%.4d.png",$q);
$list.=" $src_filename";

`rm -rf tmp/txddir`;
`mkdir tmp/txddir`;

$radname=sprintf("radar%.2d",$q);
`convert $src_filename -alpha off -resize 64x64 tmp/txddir/$radname.png`;
`perl /dev/shm/gta-city-generator/RepackTools/png2txd.pl out_radar/$radname.txd tmp/txddir/$radname.png`;
}

`montage -tile 12x -geometry 64x64+0+0 $list picture-glued-test.png`;
` perl /dev/shm/gta-city-generator/Lesson3/packer.pl gta3.img img_unpacked/models/gta3/ out_radar/`;
