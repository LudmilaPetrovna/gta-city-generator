
$packages_count=1;
$streams_count=1922;

# create dummy OGG track
`ffmpeg -ss 10 -f s16le -ac 1 -ar 8000 -i /proc/kcore -af volume=3 -ab 8000 -t 1 -y dummy.ogg`;
open(dd,"dummy.ogg");
read(dd,$dummy_data,-s(dd));
close(dd);
$dummy_size=length($dummy_data);



# create file index
open(oo,">StrmPaks.dat");
for($q=0;$q<$packages_count;$q++){
$filename="strmpak".($q<10?$q:chr(65+$q-10));
push(@package_names,$filename);
$filename.="\x00" x (16-length($filename));
print oo $filename;
}
close(oo);

# create pointers
open(oo,">TrakLkup.dat");
for($q=0;$q<$streams_count;$q++){
print oo pack("CA3II",0,"\xCD\xCD\xCD",0,$dummy_size);
}

# create package (must be encoded in PC version)

$package_data="\xFF\xFF\xFF\xFF\x00\x00\x00\x00" x 1000; # beats
$package_data.=pack("II",$dummy_size,8000); # filesize and samplerate
$package_data.="\xCD" x 56; # padding?
$package_data.="\x01\x00\xCD\xCD"; # trailer???
$package_data.=$dummy_data;

@key=map{hex($_)}qw/EA 3A C4 A1 9A A8 14 F3 48 B0 D7 23 9D E8 FF F1/;

$out="";
$len=length($package_data);
for($q=0;$q<$len;$q++){
$out.=chr(ord(substr($package_data,$q,1))^$key[$q&0xf]);

}

open(oo,">".$package_names[0]);
print oo $out;
close(oo);
