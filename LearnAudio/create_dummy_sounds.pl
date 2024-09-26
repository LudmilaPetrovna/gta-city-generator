open(dd,"|ffmpeg -f s16le -ar 44100 -ac 1 -i - -y dummy.wav");


for($w=0;$w<100;$w++){

$div=rand()*rand()*80+1;
$ph=rand()*10000;

for($q=0;$q<2000;$q++){
print dd pack("s",int(sin($ph+$q/$div)*15000));
}

}
