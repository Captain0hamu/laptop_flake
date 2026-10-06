{ pkgs, ... }:

{
  imports = [
    ../modules/deepseek-harness-codex.nix
  ];

  programs.deepseekHarnessCodex.enable = true;

  home.packages = with pkgs; [
    codex
    claude-code
  ];

}
