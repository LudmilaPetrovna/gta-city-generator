

($sample_rate,$pack_id,$filename)=@ARGV;

`ffmpeg -nostdin -i "$filename" -ac 1 -ar $sample_rate -qscale:a 0 -compression_level 10 -application voip -map_metadata -1 -y tmp0.ogg`;
`oggz-comment -d -a tmp0.ogg -o tmp.ogg`;
rename($filename,$filename.".bak");
unlink("tmp0.ogg");
rename("tmp.ogg",$filename);
