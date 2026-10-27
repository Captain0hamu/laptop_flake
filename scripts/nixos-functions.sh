NIXOS_FLAKE_DIR="${NIXOS_FLAKE_DIR:-/home/nix/nixos-flake}"
NIXOS_FLAKE_HOST="${NIXOS_FLAKE_HOST:-nixos}"
NIXOS_BUILD_HOST="${NIXOS_BUILD_HOST:-nixos@100.81.40.56}"

_nixos_flake_ref() {
  printf '%s#%s' "$NIXOS_FLAKE_DIR" "$NIXOS_FLAKE_HOST"
}

_home_flake_ref() {
  printf '%s#razero@%s' "$NIXOS_FLAKE_DIR" "$1"
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
  local system_path
  case "${1:-}" in
    "")
      sudo nixos-rebuild switch --flake "$(_nixos_flake_ref)" --impure
      ;;
    --remote)
      if (( $# != 1 )); then
        printf 'Usage: rebuild_n_switch [--remote]\n' >&2
        return 2
      fi
      system_path=$(nix eval --impure --raw \
        "$NIXOS_FLAKE_DIR#nixosConfigurations.\"$NIXOS_FLAKE_HOST\".config.system.build.toplevel.outPath") || return
      if nix-store --check-validity "$system_path" 2>/dev/null; then
        printf '[INFO] Reusing locally built system: %s\n' "$system_path"
        nixos-rebuild switch --store-path "$system_path" --elevate sudo
        return
      fi
      nixos-rebuild switch --flake "$(_nixos_flake_ref)" --impure \
        --build-host "$NIXOS_BUILD_HOST" --elevate sudo
      ;;
    *)
      printf 'Usage: rebuild_n_switch [--remote]\n' >&2
      return 2
      ;;
  esac
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
