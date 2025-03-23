open(dd,"data/surfinfo.dat");

$id=0;
while(<dd>){
if(/^\s*#/){next;}
if(/^\s*$/i){next;}
/(\S+)/;
$name=$1;

$color=join(", ",map{int(rand()*256)}(1..3));

print "-- $id: (".($id+1)." in max) $name\nsurfaces[".($id+1)."]=[$color]\n";

$id++;
}
