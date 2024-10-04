use Data::Dumper;
use Digest::CRC "crc32";


my $using_GXT_table="MAIN";
my @all_gxt_tables=();

initGxts();


print resolve_GXT("BLUEB")."\n";
print resolve_GXT_all("RYD1a05")."\n";
print resolve_GXT_all("RYD1A05")."\n";


my $gxts={};
my $gxts_data={};


sub resolve_GXT{
my $key=shift;
my $crc=crc32($key)^0xFFFFFFFF;
my $offset=-1;

if(!exists $gxts->{$using_GXT_table}){
die "Current table is $using_GXT_table, not found in GXT";
}
if(!exists $gxts->{$using_GXT_table}->{$crc}){
die "Current crc $crc not found in GXT";
}
$offset=$gxts->{$using_GXT_table}->{$crc};
if(length($gxts_data->{$using_GXT_table})<$offset){
die "Current table \"$using_GXT_table\" data len is ".length($gxts_data->{$using_GXT_table}).", but offset $offset!";
}
my $value=substr($gxts_data->{$using_GXT_table},$offset,500);
$value=~s/\x00.*//s;
return($value);
}




sub resolve_GXT_all{
my $key=shift;
my $crc=crc32($key)^0xFFFFFFFF;
my $offset=-1;
foreach $tn(@all_gxt_tables){
if(!exists $gxts->{$tn} || !exists $gxts->{$tn}->{$crc}){next;}

$offset=$gxts->{$tn}->{$crc};
if(length($gxts_data->{$tn})<$offset){
die "Current table \"$tn\" data len is ".length($gxts_data->{$tn}).", but offset $offset!";
}
my $value=substr($gxts_data->{$tn},$offset,500);
$value=~s/\x00.*//s;
return($value);

}
return(undef);
}


sub use_GXT_table{
$using_GXT_table=shift;
}

sub initGxts{

open(dd,"american.gxt");

read(dd,$buf,4);
($version,$char_width)=unpack("SS",$buf);

if($version!=4 || $char_width!=8){
die "Broken file or not San Andreas";
}

read(dd,$buf,8);
($table,$table_size)=unpack("A4I",$buf);
if($table ne "TABL"){
die "wrong first table!";
}

@stables=();
for($q=0;$q<$table_size;$q+=12){
read(dd,$buf,12);
($subtable,$offset)=unpack("Z8I",$buf);
push(@stables,[$subtable,$offset]);
$gxts->{$subtable}={};
#printf("found subtable % 8s at 0x%08x\n",$subtable,$offset);
}

foreach(@stables){
($subtable_name,$subtable_offset)=@{$_};
#print STDERR "Reading ($subtable_name,$subtable_offset)\n";
seek(dd,$subtable_offset,0);
#printf("we expect TKEY at %08x\n",tell(dd));
$is_main=$subtable_name eq "MAIN"?1:0;
if($is_main){
read(dd,$buf,8);
($table,$table_size)=unpack("A4I",$buf);
} else {
read(dd,$buf,16);
($name2,$table,$table_size)=unpack("Z8A4I",$buf);
if($name2 ne $subtable_name){
die "Wrong name? Expect $subtable_name, got $name2";
}
}

if($table ne "TKEY"){
die "table TKEY expected!";
}
#printf("reading TKEY, size %08x\n",$table_size);
for($q=0;$q<$table_size;$q+=8){
read(dd,$buf,8);
($offset,$crc)=unpack("II",$buf);
$gxts->{$subtable_name}->{$crc}=$offset;
}

#printf("we expect TDAT at %08x\n",tell(dd));
read(dd,$buf,8);
($table,$table_size)=unpack("A4I",$buf);
if($table ne "TDAT"){
die "table TDAT expected at ".sprintf("%08x",tell(dd)-8)."!";
}

read(dd,$values,$table_size);
$gxts_data->{$subtable_name}=$values;
}

@all_gxt_tables=keys %{$gxts};
close(dd);
}




