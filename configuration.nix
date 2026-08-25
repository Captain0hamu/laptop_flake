{ config, lib, pkgs, unstable, ... }:

let
  sddmBackground = ./files/sddm/dmc-login-bg.jpg;
  gentlyBlurThemeSrc = ./files/sddm/Gently-Blur-SDDM-6;
  gentlyBlurThemeConfig = pkgs.writeText "theme.conf.user" ''
    [General]
    background=${toString sddmBackground}
    type=image
    showlogo=hidden
    showClock=true
    fontSize=10
    needsFullUserModel=false
  '';
  gentlyBlurTheme = pkgs.stdenvNoCC.mkDerivation {
    pname = "gently-blur-sddm-theme";
    version = "2025-04-28";
    dontUnpack = true;

    installPhase = ''
      theme_dir="$out/share/sddm/themes/Gently-Blur-SDDM-6"

      mkdir -p "$theme_dir"
      cp -r ${gentlyBlurThemeSrc}/. "$theme_dir"/
      chmod -R u+w "$theme_dir"
      rm -f "$theme_dir/theme.conf.user"
      cp ${gentlyBlurThemeConfig} "$theme_dir/theme.conf.user"
    '';
  };
in
{
  imports = [
    ./hardware-configuration.nix
  ];

  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  boot = {
    loader = {
      systemd-boot = {
        enable = lib.mkForce false;
	editor = false;
    };
    efi.canTouchEfiVariables = true;
    timeout = 60;
    };

    kernelModules = [ "kvm-amd" ];
  };

  fileSystems."/" = lib.mkForce {
    device = "/dev/disk/by-label/nixos";
    fsType = "ext4";
  };

  fileSystems."/home/nix/lab" = {
    device = "/dev/disk/by-uuid/c21c9a3b-376e-4450-97d3-d199a9bfac8e";
    fsType = "ext4";
  };

  fileSystems."/home/nix/lab/vms" = {
    device = "/dev/disk/by-uuid/c72eb9dd-7720-4ad9-99b4-cce96c21e316";
    fsType = "ext4";
  };

  networking.hostName = "nixos";
  networking.networkmanager.enable = true;
  hardware.wirelessRegulatoryDatabase = true;
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = false;
  };
  hardware.alsa.enablePersistence = true;

  services.pipewire = {
    enable = true;
    alsa.enable = true;
    pulse.enable = true;

    wireplumber.extraConfig."51-fujitsu-prefer-working-mic" = {
      "monitor.alsa.rules" = [
        {
          matches = [
            {
              "node.name" = "alsa_input.pci-0000_00_1f.3-platform-skl_hda_dsp_generic.HiFi__Mic2__source";
            }
          ];
          actions.update-props = {
            "priority.driver" = 3000;
            "priority.session" = 3000;
          };
        }
        {
          matches = [
            {
              "node.name" = "alsa_input.pci-0000_00_1f.3-platform-skl_hda_dsp_generic.HiFi__Mic1__source";
            }
          ];
          actions.update-props = {
            "priority.driver" = 100;
            "priority.session" = 100;
            "node.disabled" = true;
          };
        }
      ];
    };
  };

  time.timeZone = "Asia/Tokyo";

  i18n.defaultLocale = "en_US.UTF-8";
  console = {
    font = "Lat2-Terminus16";
    useXkbConfig = true;
  };

  services = {
    xserver.enable = true;
    displayManager = {
	sddm.enable = true;
	sddm.wayland.enable = true;
	sddm.theme = "Gently-Blur-SDDM-6";                  
	sddm.extraPackages = [ gentlyBlurTheme ];
	sddm.settings.theme.Current = "Gently-Blur-SDDM-6";
    };
    desktopManager.plasma6.enable = true;
    openssh.enable = true;
    tailscale = {
      enable = true;
      package = unstable.tailscale;
      extraSetFlags = [ "--accept-dns=false" ];
    };
    
    
    avahi = {
      enable = true;
      nssmdns4 = true;
      openFirewall = true;
    };
    printing = {
      enable = true;
      drivers = with pkgs; [
        cups-browsed
        cups-filters
      ];
    };
  };

  environment.etc."sddm.conf.d/kde_settings.conf".text = lib.mkForce ''
    [Theme]
    Current=Gently-Blur-SDDM-6
    CursorTheme=breeze_cursors
    Font=Noto Sans,10,-1,0,400,0,0,0,0,0,0,0,0,0,0,1

    [Users]
    MinimumUid=1000
    MaximumUid=30000
  '';

  i18n.inputMethod = {
    enable = true;
    type = "fcitx5";
    fcitx5.addons = with pkgs; [
      fcitx5-mozc
      fcitx5-gtk
      qt6Packages.fcitx5-configtool
    ];
  };

  virtualisation.libvirtd = {
    enable = true;
    qemu.swtpm.enable = true;
    sshProxy = false;
  };
  virtualisation.docker.enable = true;

  virtualisation.vmVariant = {
    fileSystems."/home/nix/lab" = lib.mkForce {
      device = "tmpfs";
      fsType = "tmpfs";
      options = [ "mode=755" "size=256M" ];
    };

    services.displayManager.sddm.wayland.enable = lib.mkForce false;

    virtualisation = {
      memorySize = 4096;
      cores = 4;
      graphics = true;
      resolution = {
        x = 1600;
        y = 900;
      };
    };
  };

  users.users.root.hashedPassword = "$6$D1yPR195la2OcHsV$ux/cvoQRyea.DCuZDNMZIEbnggw4NJaYWJm2nz98X49OsJ.ip9/MfKVMEJc9tw3K/dJ5W3lBsnV3pV1Mf8E1G0";
  users.users.nix = {
    isNormalUser = true;
    extraGroups = [
      "wheel"
      "docker"
      "networkmanager"
      "libvirtd"
      "kvm"
      "docker"
    ];
    hashedPassword = "$6$D1yPR195la2OcHsV$ux/cvoQRyea.DCuZDNMZIEbnggw4NJaYWJm2nz98X49OsJ.ip9/MfKVMEJc9tw3K/dJ5W3lBsnV3pV1Mf8E1G0";
    packages = with pkgs; [
      discord-ptb
    ];
  };

  environment.systemPackages = with pkgs; [
    gentlyBlurTheme
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
    (python3.withPackages (ps: with ps; [
      ipython
    ]))
    binutils
    pciutils
    unzip
    gdb
    nmap
    wayland-utils
    kdePackages.kcolorchooser
    kdePackages.sddm-kcm
    kdePackages.kdenlive
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
  ];

  environment.interactiveShellInit = builtins.readFile ./scripts/nixos-functions.sh;

  programs.neovim.enable = true;
  programs.ssh.systemd-ssh-proxy.enable = false;
  system.stateVersion = "25.05";
}
