in="OC-01 Video 02Nov2019_creditKathyHough.mp4"
out="OC-01 Video 02Nov2019_creditKathyHough_small.mp4"
ffmpeg -i $in -filter:v scale=720:-1 -c:a copy $out
ffmpeg -i $in -filter:v scale=720:404 -c:a copy $out

in="Equip_FKNMS_04.mp4"
out="Equip_FKNMS_04_small.mp4"
ffmpeg -i $in -filter:v scale=720:-1 -c:a copy $out
ffmpeg -i $in -filter:v scale=720:404 -c:a copy $out

in="Hearing-ranges.gif"
tmp="Hearing-ranges_temp.gif"
out="Hearing-ranges_small.gif"
convert $in -coalesce -scale 640x360 -fuzz 2% +dither -remap $in[0] -layers Optimize $out
