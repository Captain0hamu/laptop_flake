{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    openvpn libreoffice wl-clipboard qemu nodejs_24 kitty jdk21 virt-manager
    libvirt gcc docker mesa-demos
    (python3.withPackages (ps: with ps; [ ipython ]))
    binutils pciutils unzip gdb nmap wayland-utils
    kdePackages.kcolorchooser kdePackages.print-manager kdePackages.sddm-kcm
    kdePackages.kdenlive checksec bat util-linux git tree-sitter curl firefox fastfetch
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
  ];
}
