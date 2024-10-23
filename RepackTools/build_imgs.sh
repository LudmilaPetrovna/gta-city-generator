#rm -r Dst
mkdir gta3-dst/

#perl /dev/shm/packer.pl Dst/Models/cutscene.img img_unpacked/models/cutscene cutscene-dst/

#perl /dev/shm/packer.pl Dst/anim/cuts.img img_unpacked/anim/cuts cuts-dst/
#perl /dev/shm/packer.pl Dst/Models/player.img img_unpacked/models/player player_img_remove.txt

#perl /dev/shm/gta-city-generator/Lesson3/packer.pl Dst/Models/gta3.img     img_unpacked/models/gta3/ gta3-dst/ col_unpacked/gta3/ cols_remove.txt

perl /dev/shm/gta-city-generator/Lesson3/packer.pl Dst/Models/gta3.img     img_unpacked/models/gta3/ gta3-dst/ no_world_remove.txt col_prepared/gta3
perl /dev/shm/gta-city-generator/Lesson3/packer.pl Dst/Models/gta_int.img  img_unpacked/models/gta_int/ no_world_remove.txt col_prepared/gta_int
