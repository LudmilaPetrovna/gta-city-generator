#!/bin/bash

find sound_sfx -iname "*.wav" | sort -n | sed "s,^,file ',g;s,$,',g" > wav_files_list.txt
ffmpeg -f concat -i wav_files_list.txt -af dynaudnorm,dynaudnorm -b:a 128k test.mp3
ffmpeg -f concat -i wav_files_list.txt -af dynaudnorm,atempo=2,dynaudnorm,atempo=1.5,dynaudnorm -b:a 128k fast_test.mp3
