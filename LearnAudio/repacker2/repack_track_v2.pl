use File::Basename;

$dir1='/dev/shm/t/gta/trans/streams/dub';
$dir2='/dev/shm/t/gta/trans/streams/dub_v3';
$rawdir='//dev/shm/t/gta/trans/streams/raw';

($sample_rate,$pack_id,$ret_filename)=@ARGV;
$fileid=basename($ret_filename);
$fileid=~s/\.(mp3|ogg|mp4)$//is;

print "Try to find $fileid...\n";

$infile=$dir2.'/'.$fileid.".ogg";
if(!-e($infile)){
$infile=$dir1.'/'.$fileid.".OGG";
}
if(!-e($infile)){
$infile=$rawdir.'/'.$fileid.".ogg";
}

print "Found: $infile\n";

unlink($ret_filename);
`oggz-comment -d -a "$infile" -o tmp.ogg`;
rename("tmp.ogg",$ret_filename);
