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
    profileModule
  ];
}
