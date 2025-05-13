#make alpha
#convert pre0.png -gaussian-blur 0x3 blurry3.png
#convert pre0.png -gaussian-blur 0x2 blurry2.png
#convert pre0.png -gaussian-blur 0x1 blurry1.png
#convert -compose screen -size 3072x3072 xc:black blurry3.png -composite blurry2.png -composite pre0.png -composite pre0.png -composite alpha.png
#convert -colorspace srgb -compose copyopacity -size 3072x3072 xc:red alpha.png -composite test1.png
convert -colorspace srgb -compose copyopacity filler.png -resize 3072x3072 alpha.png -composite test2.png

exit;

convert layer-0.png -blur 0x3 blurry-l0.png
convert layer-1.png -blur 0x3 blurry-l1.png
convert layer-2.png -blur 0x2 blurry-l2.png
convert layer-3.png -blur 0x1 blurry-l3.png
#convert layer-4.png -blur 0x1 blurry-l4.png
#convert layer-5.png -blur 0x1 blurry-l5.png
convert blurry-l0.png -threshold 128 -canny 0x1+10%+30% -blur 0x1 -threshold 20% outline-l0.png
convert blurry-l1.png -threshold 128 -canny 0x1+10%+30% -blur 0x1 -threshold 20% outline-l1.png
convert blurry-l2.png -threshold 128 -canny 0x1+10%+30% -blur 0x1 -threshold 20% outline-l2.png
convert layer-3.png -threshold 128 -canny 0x1+10%+30% outline-l3.png
convert layer-4.png -threshold 128 -canny 0x1+10%+30% outline-l4.png
convert layer-5.png -threshold 128 -canny 0x1+10%+30% outline-l5.png

convert layer-6.png -threshold 128 -canny 0x1+10%+30% -threshold 50% outline-l6.png
convert layer-7.png -threshold 128 -canny 0x1+10%+30% -threshold 50% outline-l7.png
convert layer-8.png -threshold 128 -canny 0x1+10%+30% -threshold 50% outline-l8.png
convert layer-9.png -threshold 128 -canny 0x1+10%+30% -threshold 50% outline-l9.png

convert outline-l0.png -blur 0x3 -threshold 1% -negate outline-l0-mask.png
convert outline-l1.png -blur 0x2 -threshold 1% -negate outline-l1-mask.png
convert outline-l2.png -blur 0x1 -threshold 1% -negate outline-l2-mask.png
convert outline-l3.png -blur 0x1 -threshold 1% -negate outline-l3-mask.png
convert outline-l4.png -blur 0x1 -threshold 1% -negate outline-l4-mask.png
convert outline-l5.png -blur 0x1 -threshold 1% -negate outline-l5-mask.png
convert outline-l6.png -blur 0x1 -threshold 1% -negate outline-l6-mask.png
convert outline-l7.png -blur 0x1 -threshold 1% -negate outline-l7-mask.png
convert outline-l8.png -blur 0x1 -threshold 1% -negate outline-l8-mask.png
convert outline-l9.png -blur 0x1 -threshold 1% -negate outline-l9-mask.png

convert -compose multiply outline-l9.png outline-l8-mask.png -composite -brightness-contrast -10x0 -compose screen outline-l8.png -composite pre8.png
convert -compose multiply pre8.png outline-l7-mask.png -composite -brightness-contrast -20x0 -compose screen outline-l7.png -composite pre7.png
convert -compose multiply pre7.png outline-l6-mask.png -composite -brightness-contrast -10x0 -compose screen outline-l6.png -composite pre6.png
convert -compose multiply pre6.png outline-l5-mask.png -composite -brightness-contrast -10x0 -compose screen outline-l5.png -composite pre5.png
convert -compose multiply pre5.png outline-l4-mask.png -composite -brightness-contrast -10x0 -compose screen outline-l4.png -composite pre4.png
convert -compose multiply pre4.png outline-l3-mask.png -composite -brightness-contrast -10x0 -compose screen outline-l3.png -composite pre3.png
convert -compose multiply pre3.png outline-l2-mask.png -composite -brightness-contrast -1x0 -compose screen outline-l2.png -composite pre2.png
convert -compose multiply pre2.png outline-l1-mask.png -composite -brightness-contrast -1x0 -compose screen outline-l1.png -composite pre1.png
convert -compose multiply pre1.png outline-l0-mask.png -composite -brightness-contrast -10x0 -compose screen outline-l0.png -composite pre0.png

