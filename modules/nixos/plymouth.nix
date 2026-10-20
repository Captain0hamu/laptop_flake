{ pkgs, grubThemeSrc, ... }:

let
  gtgPlymouthTheme = pkgs.runCommand "plymouth-theme-gtg" {
    nativeBuildInputs = [ pkgs.imagemagick pkgs.dejavu_fonts ];
  } ''
    themeDir=$out/share/plymouth/themes/gtg
    mkdir -p "$themeDir"

    bank=${grubThemeSrc}/assets/fonts/BankGothic.ttf
    dejavu=${pkgs.dejavu_fonts}/share/fonts/truetype/DejaVuSans.ttf
    dejavu_bold=${pkgs.dejavu_fonts}/share/fonts/truetype/DejaVuSans-Bold.ttf

    magick ${grubThemeSrc}/assets/images/blur_background.png \
      -resize 1920x1200^ -gravity center -extent 1920x1200 \
      -modulate 45,70,100 -fill black -colorize 30% -depth 8 "$themeDir/bg.png"
    magick ${grubThemeSrc}/assets/images/poster.jpg \
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

    cat > "$themeDir/gtg.plymouth" <<EOF
    [Plymouth Theme]
    Name=Grand Theft Gentoo
    Description=GTA San Andreas inspired Plymouth theme
    ModuleName=script

    [script]
    ImageDir=$themeDir
    ScriptFile=$themeDir/gtg.script
    EOF

    cat > "$themeDir/gtg.script" <<'EOF'
    screen.w = Window.GetWidth(0);
    screen.h = Window.GetHeight(0);
    progress = 0.0;

    bg.image = Image("background.png").Scale(screen.w, screen.h);
    bg.sprite = Sprite(bg.image);
    bg.sprite.SetPosition(0, 0, 0);

    bar.x = screen.w * (1152.0 / 1920.0);
    bar.y = screen.h * (1122.0 / 1200.0);
    bar.w = screen.w * (686.0 / 1920.0);
    bar.h = screen.h * (12.0 / 1200.0);

    bar.full = Image("bar_full.png").Scale(bar.w, bar.h);
    bar.sprite = Sprite(bar.full.Crop(0, 0, 1, bar.h));
    bar.sprite.SetPosition(bar.x, bar.y, 10);

    shine.image = Image("shine.png").Scale(bar.w * 0.12, bar.h);
    shine.sprite = Sprite(shine.image);
    shine.sprite.SetOpacity(0.0);
    shine.sprite.SetPosition(bar.x, bar.y, 11);

    glow.size = screen.w * (64.0 / 1920.0);
    glow.image = Image("glow.png").Scale(glow.size, glow.size);
    glow.sprite = Sprite(glow.image);
    glow.sprite.SetOpacity(0.0);
    glow.sprite.SetPosition(bar.x, bar.y, 12);

    panel.x = screen.w * (110.0 / 1920.0);
    panel.y = screen.h * (900.0 / 1200.0);
    panel.w = screen.w * (800.0 / 1920.0);
    panel.h = screen.h * (200.0 / 1200.0);

    for (i = 0; i < 11; i++) {
      radio_image[i] = Image("radio-" + i + ".png").Scale(panel.w, panel.h);
    }
    radio.sprite = Sprite(radio_image[0]);
    radio.sprite.SetPosition(panel.x, panel.y, 20);

    tip_count = 12;
    for (i = 0; i < tip_count; i++) {
      tip_image[i] = Image("tip-" + i + ".png").Scale(screen.w * (680.0 / 1920.0), screen.h * (28.0 / 1200.0));
    }
    tip.sprite = Sprite(tip_image[0]);
    tip.sprite.SetPosition(screen.w * (230.0 / 1920.0), screen.h * (1050.0 / 1200.0), 21);

    vinyl.x = screen.w * (134.0 / 1920.0);
    vinyl.y = screen.h * (964.0 / 1200.0);
    vinyl.size = screen.w * (72.0 / 1920.0);
    for (i = 0; i < 16; i++) {
      vinyl_image[i] = Image("vinyl-" + i + ".png").Scale(vinyl.size, vinyl.size);
    }
    vinyl.sprite = Sprite(vinyl_image[0]);
    vinyl.sprite.SetPosition(vinyl.x, vinyl.y, 22);

    load.x = screen.w * (1150.0 / 1920.0);
    load.y = screen.h * (1068.0 / 1200.0);
    load.w = screen.w * (690.0 / 1920.0);
    load.h = screen.h * (40.0 / 1200.0);
    for (i = 0; i < 4; i++) {
      load_image[i] = Image("load-" + i + ".png").Scale(load.w, load.h);
    }
    load.sprite = Sprite(load_image[0]);
    load.sprite.SetPosition(load.x, load.y, 30);

    fun progress_callback(duration, p) {
      progress = p;
    }
    Plymouth.SetBootProgressFunction(progress_callback);

    counter = 0;
    fun refresh_callback() {
      counter++;

      load.sprite.SetImage(load_image[Math.Int(counter / 25) % 4]);
      vinyl.sprite.SetImage(vinyl_image[Math.Int(counter / 3) % 16]);
      radio.sprite.SetImage(radio_image[Math.Int(counter / 60) % 11]);
      tip.sprite.SetImage(tip_image[Math.Int(counter / 70) % 12]);

      synthetic = counter / 150.0;
      if (synthetic > 0.95) { synthetic = 0.95; }
      if (progress > synthetic) { synthetic = progress; }
      if (progress >= 0.999) { synthetic = 1.0; }

      filled = bar.w * synthetic;
      w = Math.Int(filled);
      if (w < 1) { w = 1; }
      if (w > bar.w) { w = bar.w; }
      bar.sprite.SetImage(bar.full.Crop(0, 0, w, bar.h));

      shine.sprite.SetOpacity(0.0);
      if (filled > shine.image.GetWidth() + 8) {
        pos = (counter % 120) / 120.0;
        shine.sprite.SetPosition(bar.x + pos * (filled - shine.image.GetWidth()), bar.y, 11);
        shine.sprite.SetOpacity(0.35);
      }

      glow.sprite.SetOpacity(0.0);
      if (filled > 4) {
        glow.sprite.SetPosition(bar.x + filled - glow.image.GetWidth() / 2, bar.y + bar.h / 2 - glow.image.GetHeight() / 2, 12);
        if ((Math.Int(counter / 12) % 2) == 0) {
          glow.sprite.SetOpacity(0.25);
        }
        if ((Math.Int(counter / 12) % 2) == 1) {
          glow.sprite.SetOpacity(0.5);
        }
      }
    }
    Plymouth.SetRefreshFunction(refresh_callback);
    EOF
  '';
in
{
  boot.kernelParams = [ "quiet" ];

  boot.plymouth = {
    enable = true;
    theme = "gtg";
    themePackages = [ gtgPlymouthTheme ];
  };
}
