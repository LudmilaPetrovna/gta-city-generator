BACK="$1"
OVER="$2"
FINAL="$3"
TMPPREFIX="tmp-rand-$RANDOM-"

`ffmpeg -i "$BACK" -ar 48000 -ac 2 -y "${TMPPREFIX}back.wav"`;
`ffmpeg -i ${TMPPREFIX}back.wav -i "$OVER" -filter_complex "[0:a][1:a]sidechaincompress=threshold=0.05:ratio=5:attack=1:release=350[ducked]" -map "[ducked]" -y ${TMPPREFIX}ducked.wav`;
`ffmpeg -i ${TMPPREFIX}ducked.wav -i "$OVER" -filter_complex "[0:a][1:a]amix=inputs=2:duration=longest:dropout_transition=2:normalize=0:weights='1 0.8'[dub]" -map "[dub]" -y ${TMPPREFIX}res.wav`;
`ffmpeg -i ${TMPPREFIX}res.wav -acodec libvorbis -ac 2 -ar 32000 -qscale:a 0 -compression_level 10 -application voip -map_metadata -1 -y "$FINAL"`;

rm -vf "${TMPPREFIX}back.wav" "${TMPPREFIX}ducked.wav" "${TMPPREFIX}res.wav"



