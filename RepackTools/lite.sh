rm -r lite
mkdir lite
find gta-micro/Clean/ -iname "*.txd" | grep -v img_unpacked | while read aa; do OUTDIR=`sed -r "s,gta-micro/Clean/,lite/,g;s,\/[^\/]+$,,g" <<< $aa `; OUTNAME=`sed -r "s,^.+\/,,g" <<< "$aa"`; echo "$aa" "$OUTDIR" "$OUTNAME";mkdir -p $OUTDIR; perl txd_resizer.pl "$aa" "$OUTDIR/$OUTNAME";done
rm lite/models/txd/outro.txd
