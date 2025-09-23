

#for arc in {anim/anim,anim/cuts,models/cutscene,models/gta3,models/gta_int,models/player}; do 
for arc in {anim/cuts,models/cutscene,models/gta3,models/gta_int,models/player}; do 

#arc=models/gta3
outdir=`basename $arc`
srcimg=/dev/shm/t/gta/unpacked/$arc/

[ -e $outdir.img ] && continue
[ -e $outdir ] && continue

mkdir $outdir


find $srcimg -iname "*txd" | sort -R | while read aa; do OUT=`sed -r "s,^.+\/,$outdir/,g" <<< $aa`;perl txd_randomizer.pl $aa $OUT memes.txt; done

perl /dev/shm/gta-city-generator/Lesson3/packer.pl "$outdir.img" "$srcimg" "$outdir"

done
