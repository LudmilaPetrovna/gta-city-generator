use Data::Dumper;
use File::Slurp;
use File::Find;
use File::Path qw(make_path remove_tree);
use File::Basename;


$path_data="data";
$path_dst_game="no_world/game";
$path_dst_cols="no_world/col_patched";
$path_unpacked="/dev/shm/t/gta/unpacked/";
$path_cols="col_unpacked/";
@imgs=('anim/anim','anim/cuts','models/cutscene','models/gta3','models/gta_int','models/player');

open(oo,">no_cs_remove.txt") or die;

#./data/clothes.dat:CUTS tramline        cs_tramline
$clothes=read_file("data/clothes.dat");
while($clothes=~s/^CUTS\s+\S+\s+(\S+)//m){
print oo "".lc($1).".dff"."\t!REMOVE!\n";
print "$1\n";
}
write_file($path_dst_game."/data/clothes.dat",$clothes);

$cs=read_file("data/txdcut.ide");
while($cs=~s/([a-z\d]+), [a-z\d]+\r\n//m){
print oo "".lc($1).".dff"."\t!REMOVE!\n";
print oo "".lc($1).".txd"."\t!REMOVE!\n";
}
write_file($path_dst_game."/data/txdcut.ide",$cs);