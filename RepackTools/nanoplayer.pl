use List::MoreUtils qw(uniq);

opendir(dd,"/dev/shm/cache/img_unpacked/models/player");
@files=grep{/\..../}readdir(dd);
closedir(dd);

open(dd,"gta_sa_1.exe");
binmode(dd);
read(dd,$bin,-s(dd));
close(dd);

@files=uniq(@files);

open(oo,">player_img_remove.txt");

$bin=lc($bin);

foreach $filename(@files){
$key=lc($filename);
$key=~s/\.(dff|txd)$//s;
if(index($bin,$key)>=0 || $key=~/jeansdenim|sneakerbincblk|sneaker|legspants|jeans/i){
print STDERR "$key in binary!\n";
} else {
print oo join("\t",$filename,"!REMOVE!")."\n";
}

}





