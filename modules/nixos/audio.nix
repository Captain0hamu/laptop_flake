{ ... }:

{
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
}
