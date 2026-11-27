profile:
{ ... }:

let
  profileModule =
    if profile == "dev" then ./profiles/dev.nix
    else if profile == "lab" then ./profiles/lab.nix
    else throw "Unsupported home profile: ${profile}";
in
{
  imports = [
    ./common.nix
    ./modules/debuggers.nix
    ./modules/cool-retro-term.nix
    ./modules/plasma.nix
    ./modules/easyeffects.nix
    ./modules/neovim.nix
    profileModule
  ];
}
