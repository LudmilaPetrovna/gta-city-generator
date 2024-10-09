ffmpeg -i gta-micro/Clean/movies/GTAtitles.mpg -vcodec mpeg1video -acodec mp2 -s 512x384 -qmin 31 -qmax 69 -ar 16000 -ac 1 -ab 16000 -y GTAtitles.mpg
ffmpeg -i gta-micro/Clean/movies/Logo.mpg -vcodec mpeg1video -acodec mp2 -s 320x240 -qmin 31 -qmax 69 -ar 16000 -ac 1 -ab 16000 -y Logo.mpg

