{ ... }:

{
  environment.interactiveShellInit = builtins.readFile ../../scripts/nixos-functions.sh;

  programs = {
    neovim.enable = true;
    ssh.systemd-ssh-proxy.enable = false;
  };
}
