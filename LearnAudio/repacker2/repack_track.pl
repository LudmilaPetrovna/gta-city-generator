

($sample_rate,$pack_id,$filename)=@ARGV;


if($pack_id==3){ # ambient sounds
$max_ambient=10;

# get duration
$dur_info=`ffprobe "$filename" 2>&1`;
$dur=0;
if($dur_info=~/Duration: (\d+):(\d+):(\d+)\.(\d+)/){
$dur=$1*3600+$2*60+$3;
print "Duration $dur\n";
$offset=int(($dur-$max_ambient)/2);
if($offset>1){
print "Trimming $filename ($dur seconds), slice from $offset...\n";
`ffmpeg -v 0 -nostdin -i "$filename" -ss $offset -t $max_ambient -c copy -y tmp.ogg`;
`mv tmp.ogg "$filename"`;
}
}

}

#if($pack_id!=4){ # don't touch beats-tracks!

`ffmpeg -v 0 -nostdin -i "$filename" -af "pan=stereo|c0<c0+c1|c1<c0+c1,lowpass=f=500,volume=2" -ac 2 -ar $sample_rate -qscale:a 0 -compression_level 10 -application voip -map_metadata -1 -y tmp0.ogg`;
`oggz-comment -d -a tmp0.ogg -o tmp.ogg`;
rename($filename,$filename.".bak");
unlink("tmp0.ogg");
rename("tmp.ogg",$filename);
unlink($filename.".bak");
#}
