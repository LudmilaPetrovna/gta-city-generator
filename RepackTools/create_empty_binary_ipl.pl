use File::Path qw(make_path remove_tree);
use File::Basename;
use File::Slurp;

create_empty("no_barriers/models/gta3.img/barriers2.ipl");
create_empty("no_barriers/models/gta3.img/barriers1.ipl");

sub create_empty{
my $path=shift;
my $out="bnry"; # signature
$out.=pack("IIIIII",0,0,0,0,0,0); # number of items
$out.=pack("IIIIIIIIIIII",0x4c,0,0,0,0,0,0,0,0,0,0,0); # offsets and sizes

#622, veg_palm03, gta_tree_palm, 150, 2130052^M

make_path(dirname($path));
write_file($path,$out);
}

