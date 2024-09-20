

($source_img,$dest_dir)=@ARGV;

if(!$source_img || !$dest_dir){
die "Usage: unpacker.pl [source.img] [dest dir]";
}

open(dd,$source_img);
binmode(dd);

read(dd,$buf,8);
($sign,$entries)=unpack("A4I",$buf);

if($sign ne "VER2"){
die "This tool supports only IMG files for GTA:SA! ONLY!!!";
}

print "Unpacking $entries files\n";

@files=();
for($e=0;$e<$entries;$e++){

read(dd,$buf,32);
($offset,$size,$size_arch,$name)=unpack("ISSA24",$buf);
$name=~s/\0.*//gs;
if($size_arch!=0){
die "Very strange!!! Size_arch must be 0 in GTA:SA!";
}
$offset*=2048;
$size*=2048;
push(@files,[$name,$offset,$size]);
print "$offset: $name ($size, $size_arch)\n";
}

# unpacking real files

`mkdir -p $dest_dir`;
#mkdir $dest_dir,0777;


foreach $fileinfo(@files){
($filename,$offset,$size)=@{$fileinfo};

seek(dd,$offset,0);
read(dd,$buf,$size);

open(oo,">".$dest_dir."/".$filename);
binmode(oo);
print oo $buf;
close(oo);

}

