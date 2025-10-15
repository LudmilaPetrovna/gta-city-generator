use JSON;
use File::Slurp;
use Data::Dumper;
#0038:   $452 == 4

@operators=map{0}(0..2010);
open(dd,$ARGV[0]||"main_raw[1].txt");
while(<dd>){
s/[\r\n]//gs;
s/\s+/ /gs;
if(/^([\da-fA-F]{4}):\s+([a-z_]+\s+)*([\$\@\#\d\.]+) ([<>\+\-\=\*\/\%\#]+) ([\.\$\@\#\d+])/){
$operators[hex($1)&0x7fff]=$4;
}

}

write_file("opcode_db_my_operators.json",encode_json(\@operators));

print "7: $operators[7]\n";
