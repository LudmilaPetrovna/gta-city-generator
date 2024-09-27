
sub getXorKey{
open(dd,"gta_sa_1.exe");
binmode(dd);
read(dd,$file,-s(dd));
close(dd);

my $sign="\xEA\x3B\xC6";
my $regidx=8;
my $q;
my $asm=""; # assembly code with mangled key
my $key="";
for($q=0;$q<3;$q++){
$asm.="\xC6\x44\x24".pack("C",$regidx++).substr($sign,$q,1);
}

my $prekey_offset=index($file,$asm); # must be 0xf0b5d for version 1.0US

for($q=0;$q<16;$q++){
$key.=chr($q^ord(substr($file,$prekey_offset+$q*5+4,1)));
}

return($key);
}

sub getXorKeyArray{
my $key=getXorKey();
my $q;
my $ret=[];
for($q=0;$q<16;$q++){
push(@{$ret},ord(substr($key,$q,1)));
}
return(@{$ret});
}


1
