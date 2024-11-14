print "inst\r\n";
$scale=50.0;

for($w=-3;$w<=3;$w++){
for($q=-3;$q<=3;$q++){
print "10000, korobulka, 0, ".($q*$scale).",".($w*$scale).",0,  0.0,0.0,0.0,1.0, -1\r\n";
}
}
print "end\r\n"