

for arc in {anim/anim,anim/cuts,models/cutscene,models/gta3,models/gta_int,models/player}; do 
outdir=`basename $arc`
srcimg=/dev/shm/t/gta/unpacked/$arc/

[ -e $outdir.img ] && continue

perl /dev/shm/gta-city-generator/Lesson3/packer.pl "$outdir.img" "$srcimg" "$outdir"

[ -e $outdir ] && continue

mkdir $outdir


find $srcimg -iname "*txd" | while read aa; do OUT=`sed -r "s,^.+\/,$outdir/,g" <<< $aa`;
perl txd_resizer.pl $aa $OUT; done


done
