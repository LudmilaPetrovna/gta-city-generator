

ffmpeg -i "$1" -i "$2" -filter_complex "[1:a]aresample=48000,dynaudnorm,speechnorm,speechnorm,speechnorm,volume=1.2,asplit[vo][side];[0:a][side]sidechaincompress=threshold=0.05:ratio=5:attack=1:release=50[ducked];[ducked][vo]amix=inputs=2:duration=longest:dropout_transition=2:normalize=0:weights='1 0.8'[dub]" -map "[dub]" -acodec libvorbis -ac 2 -ar 32000 -qscale:a 0 -compression_level 10 -map_metadata -1 -y "$3"


