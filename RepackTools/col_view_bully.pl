use Data::Dumper;

$target=$ARGV[0];

open(dd,$target);
binmode(dd);
read(dd,$file,-s(dd));
close(dd);

#print_floats($file,16);
#print_repeat($file,16);
#die;
$sign=substr($file,0,4);
$filesize=substr($file,4,4);
$header=substr($file,8,24);
$some_offset=substr($file,0x20,4);

=pod
stlOpen("balls");

$part1=substr($file,32,44);
($unk1,$radius,$center_x,$center_y,$center_z,$min_x,$min_y,$min_z,$max_x,$max_y,$max_z)=unpack("ffffffffff",$part1);

createSphere([$center_x,$center_y,$center_z],abs($radius),20);
createSphere([$min_x,$min_y,$min_z],.1,50);
createSphere([$max_x,$max_y,$max_z],.1,50);


$balls_count=substr($file,76,4);
$balls=substr($file,0x24-4+12-4+0x28,20*0x14);
print_color_hex($balls,20,"ffffI");

for($q=0;$q<0x14;$q++){
($rad,$ox,$oy,$oz,$flags)=unpack("ffffI",substr($balls,$q*20,20));
createSphere([$ox,$oy,$oz],abs($rad),5);

}
stlClose();

=cut
#bounding box??? I, I, point_min, point_max, main surface, verts count;
$part25=substr($file,480,40);
#print_color_hex($part25,16,"ffff");


=pod
#part3
stlOpen("mesh");

$verts_count=unpack("I",substr($file,516,4));
$verts=substr($file,520,$verts_count*6);
print_color_hex($verts,6,"sss");
for($q=0;$q<$verts_count;$q++){
push(@verts,[map{$_/128.0}unpack("sss",substr($verts,$q*6,6))]);
}

#part4
$faces_count=unpack("I",substr($file,984,4));
$faces=substr($file,988,$faces_count*8);
print_color_hex($faces,8,"SSSCC");

for($q=0;$q<$faces_count;$q++){
($vert1,$vert2,$vert3)=unpack("SSSCC",substr($faces,$q*8,8));
writeTriangle($verts[$vert1],$verts[$vert2],$verts[$vert3]);
}

stlClose();
die;
=cut

$part5=substr($file,1980);
print_color_hex($part5,16,"ffff");
die;

for($w=1;$w<50;$w++){
}

sub print_color_hex{
my $data=shift;
my $width=shift;
my $format=shift;

my $offset=0;
my $q;
my $len=length($data);
my $byte;
my $line=1;
while($offset<$len){
printf("\x1b[1;44;33m%08X: (line $line) ",$offset);
$line++;
for($q=0;$q<$width;$q++){
if($offset+$q>=$len){last;}
$byte=ord(substr($data,$offset+$q,1));
printf("\x1b[38;5;%d;48;5;%dm%02X\x1b[0m ",$byte^0x80,$byte,$byte);
}
if($format){
print "vals: ".join(", ",unpack($format,substr($data,$offset,$width)));
}
print "\x1b[0m\n";
$offset+=$width;
}

}

sub print_floats{
my $data=shift;
my $width=shift;

my $offset=0;
my $q;
my $len=length($data);
my $byte;
my @colors=();
my $line=1;
while($offset<$len){
printf("\x1b[1;44;33m%08X: (line $line) ",$offset);
$line++;
@colors=();
@vals=();
for($q=0;$q<$width;$q++){
$val=unpack("f",substr($data,$offset+$q,4));
if($val==0 || ($val<10000 && $val>0.0001)){
push(@vals,sprintf("%.3f",$val));
$colors[$q]++;
$colors[$q+1]++;
$colors[$q+2]++;
$colors[$q+3]++;
} else {
push(@vals,"===");
}
}

for($q=0;$q<$width;$q++){
if($offset+$q>=$len){last;}
$byte=ord(substr($data,$offset+$q,1));
printf("\x1b[38;5;%d;48;5;%dm%02X\x1b[0m ",$colors[$q]^0x80,$colors[$q],$byte);
}
print join("|",@vals);
print "\x1b[0m\n";
$offset+=$width;
}

}



sub print_repeat{
my $data=shift;
my $width=shift;

my $offset=0;
my $q;
my $len=length($data);
my $byte;
my %count=();

for($q=0;$q<$len;$q++){
$count{substr($data,$q,4)}++;
}

while($offset<$len){
printf("\x1b[1;44;33m%08X: ",$offset);

for($q=0;$q<$width;$q++){
if($offset+$q>=$len){last;}
$byte=ord(substr($data,$offset+$q,1));
$color=$count{substr($data,$offset+$q,4)}&0xff;
printf("\x1b[38;5;%d;48;5;%dm%02X\x1b[0m ",$color^0x80,$color^1,$byte);
}
print "\x1b[0m\n";
$offset+=$width;
}

}









sub stlOpen{
my $filename=shift;
$outfilename="debug-".$filename.".stl";
open(ss,">".$outfilename.".tmp");
binmode(ss);
print ss "\x00" x 80;
print ss pack("I",$poly_count);

}


sub stlClose{
my $fpos=tell(ss);
my $poly_count=($fpos-80-4)/50;
seek(ss,80,0);
print ss pack("I",$poly_count);
close(ss);
rename($outfilename.".tmp",$outfilename);
}

sub writeTriangle{
my $pp1=shift;
my $pp2=shift;
my $pp3=shift;
my $offset=shift;
my $q;
print ss pack("III",0,0,0);
foreach my $vert(($pp1,$pp2,$pp3)){
for($q=0;$q<3;$q++){
print ss pack("f",$vert->[$q]+$offset->[$q]);
}
}
print ss pack("S",0);

}



sub getSpherePoint{
my $R=shift;
my $SEGS=shift;
my $q=shift;
my $w=shift;

my $qTheta;
my $wTheta;
my $pp;

$wTheta=($w-1)*1.0/$SEGS*180.0/360*2.0*3.14159265;
$qTheta=($q-1)*1.0/$SEGS*360.0/360*2.0*3.14159265;
$pp=[sin($qTheta)*sin($wTheta)*$R,cos($qTheta)*sin($wTheta)*$R,cos($wTheta)*$R];
return($pp);
}

sub createSphere{
my $POS=shift;
my $R=shift;
my $SEGS=shift;
print "Creating sphere at ".join("x",@{$POS})." ($R radius, $SEGS segments)...\n";

my $q;
my $w;
my $pp1;
my $pp2;
my $pp3;
my $pp4;

for($w=1;$w<=$SEGS;$w++){
for($q=1;$q<=$SEGS;$q++){

$pp1=getSpherePoint($R,$SEGS,$q,  $w);
$pp2=getSpherePoint($R,$SEGS,$q+1,$w);
$pp3=getSpherePoint($R,$SEGS,$q+1,$w+1);
$pp4=getSpherePoint($R,$SEGS,$q,  $w+1);

writeTriangle($pp1,$pp2,$pp3,$POS);
writeTriangle($pp4,$pp1,$pp3,$POS);
}
}

}

