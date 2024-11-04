#mkdir gta-micro
#mount //192.168.1.10/Gta-Micro gta-micro/ -o username=42
#git clone https://github.com/LudmilaPetrovna/gta-city-generator/
mkdir cache
cd cache
find /dev/shm/gta-micro/Test0/ -iname "*.img" | while read aa; do rr=`sed "s,/dev/shm/gta-micro/Test0/,img_unpacked/,g;s,.img$,,g" <<< $aa`; echo "$aa -> $rr";curl -o tmp.img file://"$aa" tmp.img; perl /dev/shm/gta-city-generator/Lesson3/unpacker.pl tmp.img "$rr";rm tmp.img;done
