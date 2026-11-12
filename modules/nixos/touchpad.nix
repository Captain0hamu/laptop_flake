{ ... }:

{
  # KWin enables libinput's disable-while-typing by default on this touchpad.
  # Match the single-key grace period to libinput's 500 ms typing timeout.
  nixpkgs.overlays = [
    (_final: prev: {
      libinput = prev.libinput.overrideAttrs (old: {
        postPatch = (old.postPatch or "") + ''
          grep -Fx '#define DEFAULT_KEYBOARD_ACTIVITY_TIMEOUT_2 usec_from_millis(500)' src/evdev-mt-touchpad.c
          substituteInPlace src/evdev-mt-touchpad.c \
            --replace-fail '#define DEFAULT_KEYBOARD_ACTIVITY_TIMEOUT_1 usec_from_millis(200)' \
                           '#define DEFAULT_KEYBOARD_ACTIVITY_TIMEOUT_1 usec_from_millis(500)'
        '';
      });
    })
  ];
}
