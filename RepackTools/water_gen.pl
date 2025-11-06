$max_poly=1021;
$splitby=15;
$splitby=15;
$poly_size=[6000/$splitby,6000/$splitby];

for($q=1;$q<20;$q++){
print "Dev: $q, size: ".(6000/$q)."\n";
}

@res=();
for($w=0;$w<$splitby;$w++){
for($q=0;$q<$splitby;$q++){

$xx=$q*$poly_size->[0]-3000;
$yy=3000-$w*$poly_size->[1];

$vert1=[$xx,$yy-$poly_size->[1]];
$vert2=[$xx+$poly_size->[0],$yy-$poly_size->[1]];
$vert3=[$xx,$yy];
$vert4=[$xx+$poly_size->[0],$yy];

$dat=sprintf("%.1f %.1f %.1f %.1f %.1f %.1f %.1f    %.1f %.1f %.1f %.1f %.1f %.1f %.1f    %.1f %.1f %.1f %.1f %.1f %.1f %.1f    %.1f %.1f %.1f %.1f %.1f %.1f %.1f  %d",
$vert1->[0],$vert1->[1],0.0, 0,0,0,0,
$vert2->[0],$vert2->[1],0.0, 0,0,0,0,
$vert3->[0],$vert3->[1],0.0, 0,0,0,0,
$vert4->[0],$vert4->[1],0.0, 0,0,0,0,
1);
push(@res,$dat);

if(--$max_poly<0){die "Max poligon count reached!";}

}
}


@res=sort{rand()<.5?-1:1}@res;

open(oo,">water.dat");
print oo "processed\n";
print oo map{$_."\n"}@res;
