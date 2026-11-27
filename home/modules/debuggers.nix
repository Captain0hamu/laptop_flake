{ pkgs, inputs, ... }:

let
  commonConfig = ../../files/gdb/common.gdb;

  pwndbgPackage = inputs.pwndbg.packages.${pkgs.stdenv.hostPlatform.system}.default;

  # nixpkgs のGEFが用意するpythonの依存関係をそのまま利用する
  gefLauncher = pkgs.writeShellScriptBin "gef" ''
    exec ${pkgs.gef}/bin/gef \
    -nx \
    -x ${commonConfig} \
    "$@"
  '';

  #Pwndbgのlauncher
  pwndbgLauncher = pkgs.writeShellScriptBin "pwndbg" ''
    exec ${pwndbgPackage}/bin/pwndbg \
    -nx \
    -x ${commonConfig} \
    "$@"
  '';

in
{
  home.packages = [
    pkgs.gdb
    gefLauncher
    pwndbgLauncher
  ];

  home.file.".gdbinit".source = commonConfig;
}
