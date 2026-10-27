{ lib, pkgs, ... }:

let
  name = "Internal Speaker - Balanced";
  speaker = "alsa_output.pci-0000_00_1f.3-platform-skl_hda_dsp_generic.HiFi__Speaker__sink";
  # Conservative starting point, not a measured response curve. Leave headroom
  # for boosts; the compressor only catches peaks and does not crush dynamics.
  bands = [
    { frequency = 85; gain = -4.0; q = 0.8; type = "Lo-shelf"; }
    { frequency = 190; gain = -2.0; q = 1.0; type = "Bell"; }
    { frequency = 420; gain = -1.5; q = 1.1; type = "Bell"; }
    { frequency = 2800; gain = 1.5; q = 1.0; type = "Bell"; }
    { frequency = 5500; gain = 1.0; q = 0.9; type = "Bell"; }
    { frequency = 10000; gain = 1.0; q = 0.7; type = "Hi-shelf"; }
  ];
  channel = builtins.listToAttrs (lib.imap0 (index: band: {
    name = "band${toString index}";
    value = band // { mode = "RLC (BT)"; slope = "x1"; solo = false; mute = false; width = 1.0; };
  }) bands);
  preset = {
    output = {
      blocklist = [ ];
      plugins_order = [ "equalizer#0" "compressor#0" ];
      "equalizer#0" = {
        bypass = false;
        input-gain = -3.0;
        output-gain = 0.0;
        mode = "IIR";
        decramp = "Off";
        split-channels = false;
        balance = 0.0;
        pitch-left = 0.0;
        pitch-right = 0.0;
        num-bands = builtins.length bands;
        left = channel;
        right = channel;
      };
      "compressor#0" = {
        bypass = false;
        input-gain = 0.0;
        output-gain = 0.0;
        dry = -80.0;
        wet = 0.0;
        mode = "Downward";
        attack = 15.0;
        release = 120.0;
        threshold = -14.0;
        ratio = 2.0;
        knee = 6.0;
        makeup = 0.0;
      };
    };
  };
in
{
  home.packages = [ pkgs.easyeffects ];
  home.file.".local/share/easyeffects/output/${name}.json".text = builtins.toJSON preset;
  home.file.".local/share/easyeffects/autoload/output/${speaker}:Speaker.json".text = builtins.toJSON {
    device = speaker;
    device-description = "Raptor Lake-P/U/H cAVS Speaker";
    device-profile = "Speaker";
    preset-name = name;
  };
}
