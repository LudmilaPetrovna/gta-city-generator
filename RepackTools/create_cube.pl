$build=0x1803FFFF;

$texture_name="world0";
$model_name="card5";

$faces_count=12;
$verts_count=8;
$tvert_count=36;

$scale=50.0;

$verts=[
[0,0,-1],
[1,0,-1],
[0,1,-1],
[1,1,-1],
[0,0,0],
[1,0,0],
[0,1,0],
[1,1,0]
];

$bounds=[
-0.1,-.1,-1,
1.1,1.1,0,
3
];

$faces=[
[1,3,4],
[4,2,1],
[5,6,8],
[8,7,5],
[1,2,6],
[6,5,1],
[2,4,8],
[8,6,2],
[4,3,7],
[7,8,4],
[3,1,5],
[5,7,3]
];

$tverts=[
[0.9995,0.000499487,0.000499487],
[0.000499487,0.000499487,0.9995],
[0.000499487,0.000499487,0.000499725],
[0.000499487,0.000499487,0.9995],
[0.9995,0.999501,0.000499487],
[0.000499487,0.999501,0.9995],
[0.000499487,0.999501,0.000499725],
[0.000499487,0.999501,0.9995],
[0.999501,0.000499725,0.000499487],
[0.9995,0.999501,0.000499487],
[0.000499487,0.9995,0.000499487],
[0.000499487,0.9995,0.000499487],
[0.000499725,0.000499487,0.000499487],
[0.999501,0.000499725,0.000499487],
[0.000499487,0.000499725,0.999501],
[0.9995,0.000499487,0.999501],
[0.999501,0.9995,0.999501],
[0.999501,0.9995,0.999501],
[0.000499725,0.999501,0.999501],
[0.000499487,0.000499725,0.999501],
[0.000499487,0.000499487,0.000499725],
[0.9995,0.000499487,0.000499487],
[0.9995,0.999501,0.000499487],
[0.9995,0.999501,0.000499487],
[0.000499487,0.999501,0.000499725],
[0.000499487,0.000499487,0.000499725],
[0.000499487,0.000499487,0.9995],
[0.9995,0.000499487,0.999501],
[0.9995,0.999501,0.999501],
[0.9995,0.999501,0.999501],
[0.000499487,0.000499487,0.9995],
[0.9995,0.000499487,0.999501],
[0.9995,0.999501,0.999501],
[0.9995,0.999501,0.999501],
[0.000499487,0.000499487,0.000499725],
[0.9995,0.999501,0.000499487]
];

$normals=[
[0,0,-1.5708],
[0,0,-1.5708],
[0,0,-1.5708],
[0,0,-1.5708],
[0,0,1.5708],
[0,0,1.5708],
[0,0,1.5708],
[0,0,1.5708],
];

open(oo,">".$model_name.".dff");
print oo gen_Clump();
close(oo);

open(oo,">".$model_name.".col");
print oo gen_collision();
close(oo);

sub gen_collision{
my $ret=pack("A4IZ22S","COL3",140,$model_name,0); #header
$ret.=pack("ffffffffff",$bounds->[0]*$scale,$bounds->[1]*$scale,$bounds->[2]*$scale,
$bounds->[3]*$scale,$bounds->[4]*$scale,$bounds->[5]*$scale,
0,0,0,$bounds->[6]*$scale); #TBound
$ret.=pack("SSSCCIIIIIIIIII",0,1,0,0,0,2,0,0x74,0,0,0,0,0,0,0);

my $box=pack("ffffffCCCC",$bounds->[0]*$scale,$bounds->[1]*$scale,$bounds->[2]*$scale, # bound min
$bounds->[3]*$scale,$bounds->[4]*$scale,$bounds->[5]*$scale, # bound max
0x3D,0x00,0xBB,0x00 # surface props
);
return($ret.$box);

}



sub get_by_path{
#dump-dff-100e03253f2fe.bin
#my $path="dump-dff-".join("",map{sprintf("%02x",$_)}@_).".bin";
my $buf;
my $path=shift;
$path="dump-dff-".$path.".bin";
open(ii,$path) or die "Can't open \"$path\": $!";
read(ii,$buf,-s(ii));
close(ii);
return($buf);
}

sub gen_Clump{
#return(get_by_path("10"));

#00000000: chunk 10, len 0bf8 (3064) bytes ... up to 00000c04: Clump (тип RpClump)
#  0000000c: chunk 01, len 000c (12) bytes ... up to 00000024: STRUCT (data)
#  We found: parts: 1, lights: 0, cams: 0

my $add="";
$add.=pack("IIIIII",1,12,$build,1,0,0); # struct (data)
$add.=gen_RwFramelist();
$add.=gen_RwGeometryList();
$add.=gen_RwAtomic();
$add.=pack("III",3,0,$build);
return(pack("III",0x10,length($add),$build).$add);
}
#$add.=pack("III",3,length($main_ext),$build).$main_ext;


sub gen_RwGeometryList{
#return(get_by_path("101a"));
#  000000a0: chunk 1a, len 0b18 (2840) bytes ... up to 00000bc4: Geometry List (RW Section)
#    000000ac: chunk 01, len 0004 (4) bytes ... up to 000000bc: STRUCT (data)
#1A 00 00 00 18 0B 00 00 FF FF 03 18 01 00 00 00
#04 00 00 00 FF FF 03 18 01 00 00 00
my $add=gen_RpGeometry();
return(pack("IIIIIII",0x1a,length($add)+12+4,$build,1,4,$build,1).$add);
}

sub gen_RpGeometry{
#    000000bc: chunk 0f, len 0afc (2812) bytes ... up to 00000bc4: геометрия модели (тип RpGeometry)
#      000000c8: chunk 01, len 07a8 (1960) bytes ... up to 0000087c: STRUCT (data)
#https://gtamods.com/wiki/RpGeometry

$format=0x0001003e;
my $out=pack("IIII",$format,$faces_count,$verts_count,1);
$out.="\xFF\xFF\xFF\xFF" x $verts_count; #prelit
$out.=join("",map{pack("ff",$_->[0],$_->[1])}@{$verts}); # tex coords (very bad)
$out.=join("",map{pack("SSSS",$_->[1]-1,$_->[0]-1,0,$_->[2]-1)}@{$faces}); # triangles
$out.=pack("ffff",0,0,0,3); # bounding sphere
$out.=pack("II",1,1);
$out.=join("",map{pack("fff",$_->[0]*$scale,$_->[1]*$scale,$_->[2]*$scale)}@{$verts}); # vertices
$out.=join("",map{pack("III",@{$_})}@{$normals}); # normals

$add=gen_RwMatList($texture_name);
$u50e=gen_50e();
$add.=pack("III",3,length($u50e),$build).$u50e;

$out=pack("IIIIII",0x0f,length($add)+length($out)+12,$build,1,length($out),$build).$out.$add;
return($out);
}

sub get_padded_string{
my $str=shift;
my $pad=shift;
my $len=length($str);
my $tail=$len%$pad;
if($tail){
$pad=$pad-$tail;
$str.="\x00" x $pad;
}
return($str);
}

sub gen_RwFramelist{
return(get_by_path("100e"));

#  00000024: chunk 0e, len 0070 (112) bytes ... up to 000000a0: Frame List (RW Section)
#    00000030: chunk 01, len 003c (60) bytes ... up to 00000078: STRUCT (data)
#    We found: frames: 1
#    00000078: chunk 03, len 001c (28) bytes ... up to 000000a0: Extension (RW Section)
#      00000084: chunk 78563412, len 0010 (16) bytes ... up to 000000a0:
#0E 00 00 00 54 00 00 00 FF FF 03 18 01 00 00 00
#3C 00 00 00 FF FF 03 18 01 00 00 00 00 00 80 3F
#00 00 00 00 00 00 00 00 00 00 00 00 00 00 80 3F
#00 00 00 00 00 00 00 00 00 00 00 00 00 00 80 3F
#00 00 00 00 00 00 00 00 00 00 00 00 FF FF FF FF
#00 00 00 00
#03 00 00 00 00 00 00 00 FF FF 03 18
return(join("",map{chr($_)}(0x0E, 0x00, 0x00, 0x00, 0x54, 0x00, 0x00, 0x00, 0xFF, 0xFF, 0x03, 0x18, 0x01, 0x00, 0x00, 0x00, 0x3C, 0x00, 0x00, 0x00, 0xFF, 0xFF, 0x03, 0x18, 0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x80, 0x3F, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x80, 0x3F, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x80, 0x3F, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xFF, 0xFF, 0xFF, 0xFF, 0x00, 0x00, 0x00, 0x00, 0x03, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xFF, 0xFF, 0x03, 0x18)));
}

sub gen_RwAtomic{
return(get_by_path("1014"));
#14 00 00 00 28 00 00 00 FF FF 03 18 01 00 00 00
#10 00 00 00 FF FF 03 18 00 00 00 00 00 00 00 00
#05 00 00 00 00 00 00 00 03 00 00 00 00 00 00 00
#FF FF 03 18
#  00000bc4: chunk 14, len 0028 (40) bytes ... up to 00000bf8: составная часть модели (тип RpAtomic)
#    00000bd0: chunk 01, len 0010 (16) bytes ... up to 00000bec: STRUCT (data)
#    00000bec: chunk 03, len 0000 (0) bytes ... up to 00000bf8: Extension (RW Section)
return(pack("IIIIIIIIIIIII",0x14,0x28,$build,1,0x10,$build,0,0,5,0,3,0,$build));
}


sub gen_50e{
#return(get_by_path("101a0f0350e"));
my $out=pack("IIIIIIII",0x50e,$faces_count*12+5*4,$build,0,1,$faces_count*3,$faces_count*3,0);
my $q;
for($q=0;$q<$faces_count;$q++){
$out.=pack("III",$faces->[$q]->[0]-1,$faces->[$q]->[1]-1,$faces->[$q]->[2]-1);
}
return($out);
=pod
    writeLong f 0<-----><------><------><------><------><------><------>--Split Type^M
    writeLong f FIDAry.count^M
    writeLong f (msh.numfaces * 3)^M
    for i = 1 to FIDAry.count do (^M
        writeLong f (FIDAry[i].count * 3)^M
        writeLong f (i - 1)^M
        for j = 1 to FIDAry[i].count do (^M
            local tmp = getFace msh FIDAry[i][j]^M
    <--><------>writeLong f (tmp.x - 1)^M
            writeLong f (tmp.y - 1)^M
            writeLong f (tmp.z - 1)^M
        )--end for j^M
=cut

}

sub gen_RwMatList{
my $texture_name=shift;
my $out=pack("IIIIi",1,8,$build,1,-1).gen_RwMaterial($texture_name);
$out=pack("III",8,length($out),$build).$out;
return($out);
}

sub gen_RwMaterial{
my $texture_name=shift;
=pod
        0000089c: chunk 07, len 0088 (136) bytes ... up to 00000930: материал модели (тип RpMaterial)
          000008a8: chunk 01, len 001c (28) bytes ... up to 000008d0: STRUCT (data)
          00000924: chunk 03, len 0000 (0) bytes ... up to 00000930: Extension (RW Section)
=cut
my $out=pack("IIIIIIIfff",1,0x1c,$build,0,0xFFFFFFFF,0,1,1,0.05,1); # color and surface props, https://gtamods.com/wiki/RpMaterial
$out.=gen_RwTexture($texture_name);
$out.=pack("III",3,0,$build);
$out=pack("III",7,length($out),$build).$out;

return($out);
}

sub gen_RwTexture{
my $texture_name=shift;
$texture_name=get_padded_string($texture_name."\x00",4);
my $texture_len=56+length($texture_name);
my $out=pack("IIIIIII",6,$texture_len,$build,1,4,$build,0x00001101);
$out.=pack("III",2,length($texture_name),$build).$texture_name;
$out.=pack("IIII",2,4,$build,0); # alpha name, always NULL
$out.=pack("III",3,0,$build);
return($out);

=pod
          000008d0: chunk 06, len 0048 (72) bytes ... up to 00000924: текстура (тип RwTexture)
            000008dc: chunk 01, len 0004 (4) bytes ... up to 000008ec: STRUCT (data)
            000008ec: chunk 02, len 0010 (16) bytes ... up to 00000908: Plain string
            We found string: "cardboxes_128"
            00000908: chunk 02, len 0004 (4) bytes ... up to 00000918: Plain string
            We found string: ""
            00000918: chunk 03, len 0000 (0) bytes ... up to 00000924: Extension (RW Section)
          00000924: chunk 03, len 0000 (0) bytes ... up to 00000930: Extension (RW Section)

06 00 00 00 48 00 00 00 FF FF 03 18 01 00 00 00
04 00 00 00 FF FF 03 18 06 11 00 00 02 00 00 00
10 00 00 00 FF FF 03 18 63 61 72 64 62 6F 78 65
73 5F 31 32 38 00 00 00 02 00 00 00 04 00 00 00
FF FF 03 18 00 00 00 00 03 00 00 00 00 00 00 00
FF FF 03 18 03 00 00 00 00 00 00 00 FF FF 03 18


=cut


}


