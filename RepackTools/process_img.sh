
outdir=cuts
srcimg=gta-micro/Clean/img_unpacked/anim/cuts.img




outdir=player
srcimg=gta-micro/Clean/img_unpacked/models/player.img


outdir=gta_int
srcimg=gta-micro/Clean/img_unpacked/models/gta_int.img


outdir=cutscene
srcimg=gta-micro/Clean/img_unpacked/models/cutscene.img

outdir=gta3
srcimg=gta-micro/Clean/img_unpacked/models/gta3.img



rm -r $outdir
mkdir $outdir
find $srcimg -iname "*txd" | while read aa; do OUT=`sed -r "s,^.+\/,$outdir/,g" <<< $aa`;
perl txd_resizer.pl $aa $OUT; done
perl packer.pl $outdir.img $srcimg $outdir

rm -r $outdir
