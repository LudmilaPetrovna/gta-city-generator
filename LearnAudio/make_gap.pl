$samplerate=48000;
$dursec=2;
$dursam=$dursec*$samplerate;

$half=$dursam/2;

for($q=0;$q<$dursam;$q++){
$noise_level=.5-cos($q/$dursam*2.0*3.14159265)/2;
$sample=(rand()*65536-32768)*$noise_level*2;

$peaklevel=5**(abs($half-$q)/$half);
if($peaklevel<1.2){
$sample=sin($q*1440*2.0*3.14159265/$samplerate)*32768;
}

if($sample>32767){$sample=32767;}
if($sample<-32768){$sample=-32768;}

print pack("s",$sample);


}
