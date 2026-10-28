NIXOS_FLAKE_DIR="${NIXOS_FLAKE_DIR:-/home/nix/nixos-flake}"
NIXOS_FLAKE_HOST="${NIXOS_FLAKE_HOST:-nixos}"

_nixos_flake_ref() {
  printf '%s#%s' "$NIXOS_FLAKE_DIR" "$NIXOS_FLAKE_HOST"
}

_home_flake_ref() {
  printf '%s#razero@%s' "$NIXOS_FLAKE_DIR" "$1"
}

tor-start() {
  local data_dir="$HOME/.local/share/tor-dev-shell"
  mkdir -p -- "$data_dir" || return
  nix develop --impure "$NIXOS_FLAKE_DIR#tor" --command \
    tor --SocksPort 127.0.0.1:9050 --DataDirectory "$data_dir" \
    --RunAsDaemon 1 --PidFile "$data_dir/tor.pid" \
    --Log "notice file $data_dir/tor.log" || return
  printf 'Tor started. Check bootstrap progress: tail -f "%s/tor.log"\n' "$data_dir"
}

tor-stop() {
  local data_dir="$HOME/.local/share/tor-dev-shell" pid arg
  local found_pidfile=0 found_datadir=0 previous=""
  local -a args
  if ! read -r pid < "$data_dir/tor.pid" || [[ ! "$pid" =~ ^[0-9]+$ ]] || (( pid < 2 )); then
    printf 'Tor PID file missing or invalid: %s/tor.pid\n' "$data_dir" >&2
    return 1
  fi
  if [[ "$(readlink "/proc/$pid/exe")" != */bin/tor ]] ||
    ! mapfile -d '' -t args < "/proc/$pid/cmdline"; then
    printf 'Tor process %s is not running or cannot be verified.\n' "$pid" >&2
    return 1
  fi
  for arg in "${args[@]}"; do
    [[ "$previous" == --PidFile && "$arg" == "$data_dir/tor.pid" ]] && found_pidfile=1
    [[ "$previous" == --DataDirectory && "$arg" == "$data_dir" ]] && found_datadir=1
    previous="$arg"
  done
  if (( ! found_pidfile || ! found_datadir )); then
    printf 'Process %s does not match this Tor client; refusing to stop it.\n' "$pid" >&2
    return 1
  fi
  kill -TERM "$pid" || return
  printf 'Sent shutdown signal to Tor (PID %s).\n' "$pid"
}

tor-shell() {
  nix develop --impure "$NIXOS_FLAKE_DIR#tor"
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
  local system_path build_host
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
        nixos-rebuild switch --store-path "$system_path" --no-reexec --elevate sudo
        return
      fi
      build_host="${NIXOS_BUILD_HOST:-}"
      if [[ -z "$build_host" && -f "$NIXOS_FLAKE_DIR/local.nix" ]]; then
        build_host=$(nix eval --impure --raw --file "$NIXOS_FLAKE_DIR/local.nix" \
          --apply 'local: local.remoteBuildHost or ""') || return
      fi
      if [[ -z "$build_host" ]]; then
        printf '[ERROR] Set remoteBuildHost in local.nix or NIXOS_BUILD_HOST.\n' >&2
        return 2
      fi
      nixos-rebuild switch --flake "$(_nixos_flake_ref)" --impure \
        --build-host "$build_host" --elevate sudo
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
