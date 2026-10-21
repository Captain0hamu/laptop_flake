#!/usr/bin/env bash
set -eu

mkdir -p "$themeDir"

magick "$src/blur_background.png" \
  -resize 1920x1200^ -gravity center -extent 1920x1200 \
  -modulate 45,70,100 -fill black -colorize 30% -depth 8 "$themeDir/bg.png"
magick "$src/poster.jpg" \
  -resize x1000 -modulate 90,90,100 \
  -bordercolor '#8fb3d9' -border 2 -depth 8 "$themeDir/poster.png"
magick "$themeDir/bg.png" "$themeDir/poster.png" -gravity northeast \
  -geometry +80+60 -composite -depth 8 "$themeDir/base.png"
magick "$themeDir/base.png" \
  -fill '#0b0f12' -stroke '#475a6b' -strokewidth 2 \
  -draw 'rectangle 1150,1120 1840,1136' -depth 8 "$themeDir/background.png"

magick -size 800x200 xc:none \
  -fill 'rgba(7,10,13,0.82)' -stroke '#475a6b' -strokewidth 2 \
  -draw 'roundrectangle 1,1 798,198 12,12' \
  -stroke none -fill '#a9c9ef' -draw 'rectangle 12,20 16,180' \
  -fill '#e06c75' -draw 'circle 706,26 710,26' \
  -font "$dejavu_bold" -pointsize 14 -kerning 2 -fill '#e06c75' \
  -annotate +718+31 'ON AIR' -depth 8 "$themeDir/panel-base.png"

station() {
  n=$1
  name=$2
  freq=$3
  track=$4
  magick "$themeDir/panel-base.png" \
    -font "$bank" -pointsize 38 -kerning 2 -fill '#a9c9ef' -annotate +120+56 "$name" \
    -font "$bank" -pointsize 20 -kerning 2 -fill '#8fb3d9' -annotate +120+96 "$freq" \
    -font "$dejavu_bold" -pointsize 15 -fill '#6f8fae' -annotate +120+136 'NOW PLAYING:' \
    -font "$dejavu" -pointsize 21 -fill '#e6edf5' -annotate +280+136 "$track" \
    -depth 8 "$themeDir/radio-$n.png"
}
station 0 'RADIO GENTOO' '101.3 FM // COMPILING' 'emerge --sync'
station 1 'K-ERNEL' '6.1.0 LTS // STABLE' 'have you tried rebooting?'
station 2 'PLAYBACK FM' '88.1 FM // USERSPACE' 'sudo make me a sandwich'
station 3 'BOUNCE FM' '94.7 FM // FREE SOFTWARE' 'GNU is Not Unix'
station 4 'RADIO X' '107.9 FM // TECH TIPS' 'it works on my machine'
station 5 'K-DST' 'THE DUST 94.7' 'git push --force'
station 6 'SF-UR' 'SAN FIERRO UNDERGROUND' 'docker run --privileged'
station 7 'MASTER SOUNDS' '98.3 FM // KERNEL SPACE' 'segfault (feat. core dump)'
station 8 'WCTR' 'TALK RADIO 101.3' 'tabs vs spaces'
station 9 'K-JAH' 'K-JAH WEST 88.1' 'kill -9'
station 10 'RADIO LOS SANTOS' '106.2 FM // NETWORK' "it's always DNS"

tip() {
  n=$1
  text=$2
  magick -size 680x28 xc:none -depth 8 \
    -font "$dejavu_bold" -pointsize 17 -fill '#6f8fae' -annotate +0+24 'TIP:' \
    -font "$dejavu" -pointsize 17 -fill '#8fb3d9' -annotate +50+24 "$text" \
    "$themeDir/tip-$n.png"
}
tip 0 "it's always DNS."
tip 1 'have you tried turning it off and on again?'
tip 2 'read the friendly manual.'
tip 3 'git commit early, git commit often.'
tip 4 'there is no place like 127.0.0.1.'
tip 5 '640K ought to be enough for anybody.'
tip 6 "never trust a computer you can't throw out a window."
tip 7 'works on my machine is not a test.'
tip 8 'NixOS: it works on my machine, reproducibly.'
tip 9 "the cloud is just someone else's computer."
tip 10 'AI will fix it in the next release.'
tip 11 'rm -rf is not a cleanup strategy.'

magick -size 72x72 xc:none \
  -fill '#10161c' -stroke '#475a6b' -strokewidth 2 -draw 'circle 36,36 36,3' \
  -stroke '#2a3742' -strokewidth 1 \
  -draw 'circle 36,36 36,10' -draw 'circle 36,36 36,15' -draw 'circle 36,36 36,20' \
  -fill '#1f2b36' -stroke '#6f8fae' -strokewidth 2 -draw 'circle 36,36 36,23' \
  -fill '#cfe3ff' -stroke none -draw 'circle 36,36 36,39' -depth 8 \
  "$themeDir/vinyl-base.png"
for i in $(seq 0 15); do
  ang=$(awk "BEGIN{print $i*22.5*3.141592653589793/180}")
  x1=$(awk "BEGIN{printf \"%.2f\", 36+14*sin($ang)}")
  y1=$(awk "BEGIN{printf \"%.2f\", 36-14*cos($ang)}")
  x2=$(awk "BEGIN{printf \"%.2f\", 36+30*sin($ang)}")
  y2=$(awk "BEGIN{printf \"%.2f\", 36-30*cos($ang)}")
  magick "$themeDir/vinyl-base.png" -depth 8 \
    -stroke '#a9c9ef' -strokewidth 2 -draw "line $x1,$y1 $x2,$y2" \
    -fill '#cfe3ff' -stroke none \
    -draw "circle $x2,$y2 $(awk "BEGIN{printf \"%.2f\", $x2+2}"),$y2" \
    "$themeDir/vinyl-$(printf '%02d' $i).png"
done

for n in 0 1 2 3; do
  dots=""
  if [ "$n" -gt 0 ]; then dots=$(printf '.%.0s' $(seq 1 $n)); fi
  magick -size 690x40 xc:none -depth 8 \
    -font "$bank" -pointsize 32 -kerning 3 -fill '#a9c9ef' \
    -annotate +0+32 "LOADING$dots" "$themeDir/load-$n.png"
done

magick -size 686x12 gradient:'#6f8fae-#cfe3ff' -depth 8 "$themeDir/bar_full.png"
magick -size 120x12 xc:white -alpha set -channel A \
  -fx '1 - abs(2*i/(w-1) - 1)' -channel A -evaluate multiply 0.35 +channel \
  -depth 8 "$themeDir/shine.png"
magick -size 64x64 xc:none -fill white -draw 'circle 32,32 32,4' -blur 0x10 \
  -fill '#cfe3ff' -colorize 100 -depth 8 "$themeDir/glow.png"

rm "$themeDir/bg.png" "$themeDir/poster.png" "$themeDir/base.png" \
  "$themeDir/panel-base.png" "$themeDir/vinyl-base.png"
