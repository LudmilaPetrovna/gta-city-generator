FROM="/dev/shm/t/gta/Grand Theft Auto - San Andreas"
TO="repack"

mkdir -p $TO

find "$FROM" -iname "*.txd" | while read aa; do OUT=`sed -r "s,$FROM,$TO,g" <<< $aa`;
echo "$aa -->> $OUT";
mkdir -p `dirname "$OUT"`;
perl txd_resizer.pl "$aa" "$OUT"

done

