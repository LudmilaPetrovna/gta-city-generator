
`rm -rf out_radar`;
`mkdir out_radar`;


`rm -rf tmp`;
`mkdir tmp`;

# convert new radar map to TXD files
for($q=0;$q<144;$q++){
$src_filename=sprintf("newcol/frames%.4d.png",$q);
$radname=sprintf("radar%.2d",$q);

`rm -rf tmp/txddir`;
`mkdir tmp/txddir`;

`convert $src_filename -interpolate Integer -filter point -alpha off -resize 256x256 tmp/txddir/$radname.png`;
`perl /dev/shm/gta-city-generator/RepackTools/png2txd.pl out_radar/$radname.txd tmp/txddir/$radname.png`;
}

#` perl /dev/shm/gta-city-generator/Lesson3/packer.pl gta3.img img_unpacked/models/gta3/ out_radar/`;
` perl /dev/shm/gta-city-generator/Lesson3/packer.pl gta3.img img_unpacked/gta3/ out_radar/`;

die;



# for compare and checking quality
$compare_size_block="256x256";
$list="";
`rm -rf tmp`;
`mkdir tmp`;
for($q=0;$q<144;$q++){
$src_filename=sprintf("newcol/frames%.4d.png",$q);
$tmp_filename=sprintf("tmp/frames%.4d.png",$q);
$list.=" $tmp_filename";
`convert $src_filename -interpolate Integer -filter point -resize $compare_size_block $tmp_filename`;
}
`montage -tile 12x -geometry ${compare_size_block}+0+0 $list radar-compare-new.png`;

# result 3072x3072
`convert radar-gtasa-ref.png -interpolate Integer -filter point -resize 3072x3072 radar-compare-ref.png`;
`convert radar-compare-ref.png radar-compare-new.png radar-anim0.gif`;
`gifsicle -O99 -f --lossy=90 --delay 50 -o radar-anim.gif radar-anim0.gif`;

die;



#`convert picture.jpg -resize 768x768^ -gravity center -extent 768x768+0+0 picture-resized.png`;
#`convert picture-resized.png -crop 64x64 tmp/frames.png`;


`convert radar-compare-sat.png radar-compare-new.png radar-anim0.gif`;
`gifsicle -O99 -f --lossy=90 --delay 50 -o radar-anim.gif radar-anim0.gif`;
die;


=pod
`rm -rf tmp/txddir`;
`mkdir tmp/txddir`;

$front="./front/fronten2.txd";
`perl /dev/shm/gta-city-generator/Lesson3/txd_unpacker.pl $front tmp/txddir`;
`convert picture-glued-test.png -trim -resize 256x256\! tmp/txddir/png/map.png`;

`perl /dev/shm/gta-city-generator/RepackTools/png2txd.pl out_radar/fronten2.txd tmp/txddir/png/*.png`;

=cut