{ pkgs, ... }:

{
  home.packages = with pkgs; [
    burpsuite
    wireshark
    zap
    spice-gtk
    spice-vdagent
    swtpm
  ];
}
