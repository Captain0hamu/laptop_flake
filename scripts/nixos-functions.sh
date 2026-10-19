NIXOS_FLAKE_DIR="${NIXOS_FLAKE_DIR:-/home/nix/nixos-flake}"
NIXOS_FLAKE_HOST="${NIXOS_FLAKE_HOST:-nixos}"

_nixos_flake_ref() {
  printf '%s#%s' "$NIXOS_FLAKE_DIR" "$NIXOS_FLAKE_HOST"
}

_home_flake_ref() {
  printf '%s#nix@%s' "$NIXOS_FLAKE_DIR" "$1"
}

lsgen() {
  sudo nix-env --list-generations --profile /nix/var/nix/profiles/system
}

delgen() {
  local gen="${1:-3}"
  local ans

  [[ "$gen" =~ ^[0-9]+$ ]] || {
    printf "\e[1;31m[ERROR]\e[0m Invalid count: %s\n" "$gen"
    return 2
  }

  (( gen >= 1 )) || {
    printf "\e[1;31m[ERROR]\e[0m input must be >= 1 (got %s)\n" "$gen"
    return 2
  }

  printf "\n\e[1;33m[WARNING] Are you sure to delete generation\e[0m"
  printf "\e[1;31m+%s\e[0m ?\n\n" "$gen"

  read -r -p "Proceed? [y/N]: " ans
  [[ "$ans" == "y" ]] || {
    printf "\e[1;36m[INFO]\e[0m Aborted.\n"
    return 1
  }

  sudo nix-env --delete-generations +"$gen" \
    --profile /nix/var/nix/profiles/system
}

gendum() {
  sudo nix-shell -p nix-du --run "nix-du -s 500M | xdot -"
}

sweep() {
  nix-collect-garbage
}

loadgen() {
  sudo nixos-rebuild boot --flake "$(_nixos_flake_ref)" --impure
}

drybuild() {
  sudo nixos-rebuild dry-build --flake "$(_nixos_flake_ref)" --impure
}

rebuild_n_switch() {
  sudo nixos-rebuild switch --flake "$(_nixos_flake_ref)" --impure
}

rebuild_and_switch() {
  rebuild_n_switch "$@"
}

switch-dev() {
  home-manager switch --flake "$(_home_flake_ref dev)" --impure
}

switch-lab() {
  home-manager switch --flake "$(_home_flake_ref lab)" --impure
}

build-dev() {
  home-manager build --flake "$(_home_flake_ref dev)" --impure
}

build-lab() {
  home-manager build --flake "$(_home_flake_ref lab)" --impure
}
