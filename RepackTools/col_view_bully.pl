use Data::Dumper;

$target=$ARGV[0];

open(dd,$target);
binmode(dd);
read(dd,$file,-s(dd));
close(dd);

print_floats($file,16);
print_repeat($file,16);
die;
$sign=substr($file,0,4);
$filesize=substr($file,4,4);
$header=substr($file,8,24);
$some_offset=substr($file,0x20,4);

$part1=substr($file,0x24,0x1B8+12);

$part2=substr($file,487,10*$w);

$verts=substr($file,512);

$faces=substr($file,988,1980-988);
#print_color_hex($faces,8,"SSSCC");

$part5=substr($file,1988);
print_color_hex($part5,12,"fff");


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
while($offset<$len){
printf("\x1b[1;44;33m%08X: ",$offset);
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
while($offset<$len){
printf("\x1b[1;44;33m%08X: ",$offset);
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

