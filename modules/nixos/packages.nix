{ pkgs, ... }:

{
  environment.systemPackages =
    (with pkgs; [
      openvpn
      libreoffice
      wl-clipboard
      qemu
      nodejs_24
      kitty
      jdk21
      virt-manager
      libvirt
      gcc
      docker
      mesa-demos
      (python3.withPackages (ps: with ps; [ ipython ]))
      pciutils
      unzip
      gdb
      nmap
      wayland-utils
      v4l-utils
      checksec
      bat
      util-linux
      git
      tree-sitter
      curl
      firefox
      fastfetch
      (vim-full.customize {
        name = "vim";
        vimrcConfig.customRC = ''
          set number
          set relativenumber
          inoremap kk <esc>
          nnoremap : ;
          nnoremap ; :
          syntax on
          vnoremap <c-k> <esc>
        '';
      })
    ])
    ++ (with pkgs.kdePackages; [
      kcolorchooser
      print-manager
      sddm-kcm
      kdenlive
      kamera
      kamoso
    ]);
}
