{ pkgs, grubThemeSrc, ... }:

let
  gtgPlymouthTheme = pkgs.runCommand "plymouth-theme-gtg" {
    nativeBuildInputs = [ pkgs.imagemagick ];
  } ''
    themeDir=$out/share/plymouth/themes/gtg
    mkdir -p "$themeDir"

    magick ${grubThemeSrc}/assets/images/blur_background.png \
      -resize 1920x1200^ -gravity center -extent 1920x1200 \
      -modulate 45,70,100 -fill black -colorize 30% bg.png
    magick ${grubThemeSrc}/assets/images/poster.jpg \
      -resize x1000 -modulate 90,90,100 \
      -bordercolor '#8fb3d9' -border 2 poster.png
    magick bg.png poster.png -gravity northeast -geometry +80+60 -composite base.png
    magick base.png \
      -font ${grubThemeSrc}/assets/fonts/BankGothic.ttf \
      -pointsize 32 -kerning 3 -fill '#a9c9ef' -annotate +1150+1100 'LOADING...' \
      -fill '#0b0f12' -stroke '#475a6b' -strokewidth 2 \
      -draw 'rectangle 1150,1120 1840,1136' \
      "$themeDir/background.png"

    magick -size 686x12 gradient:'#6f8fae-#cfe3ff' "$themeDir/bar_full.png"
    magick -size 120x12 xc:white -alpha set -channel A \
      -fx '1 - abs(2*i/(w-1) - 1)' "$themeDir/shine.png"

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
    shine.sprite.SetOpacity(0.35);
    shine.sprite.SetPosition(bar.x, bar.y, 11);

    fun progress_callback(duration, p) {
      progress = p;
      w = Math.Int(bar.w * p);
      if (w < 1) { w = 1; }
      if (w > bar.w) { w = bar.w; }
      bar.sprite.SetImage(bar.full.Crop(0, 0, w, bar.h));
    }
    Plymouth.SetBootProgressFunction(progress_callback);

    counter = 0;
    fun refresh_callback() {
      counter++;
      filled = bar.w * progress;
      if (filled > shine.image.GetWidth() + 8) {
        pos = (counter % 120) / 120.0;
        shine.sprite.SetPosition(bar.x + pos * (filled - shine.image.GetWidth()), bar.y, 11);
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
