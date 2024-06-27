



open(dd,$ARGV[0]);
binmode(dd);
read(dd,$file,-s(dd));
close(dd);

($header,$poly_count)=unpack("a80I",substr($file,0,84));
$file_len=length($file);

$file_must_len=84+$poly_count*50;

print "File have $poly_count triangles, must be at least $file_must_len, actual $file_len\n";

