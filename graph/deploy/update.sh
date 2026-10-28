#!/usr/bin/env bash
set -euo pipefail

base="${SHOWCASE_HOME:-$HOME/.local/share/nixos-showcase}"
repo="$base/repository.git"
releases="$base/releases"
url="https://github.com/Captain0hamu/laptop_flake.git"
mkdir -p "$releases"
if [[ ! -d "$repo" ]]; then
  git init --bare "$repo" >/dev/null
fi
git -C "$repo" fetch --quiet --depth=1 "$url" refs/heads/main
revision=$(git -C "$repo" rev-parse FETCH_HEAD)
if [[ "$(readlink "$base/current" 2>/dev/null || :)" == "releases/$revision" ]]; then
  exit 0
fi
if [[ ! -d "$releases/$revision" ]]; then
  staging=$(mktemp -d "$releases/.staging.XXXXXXXX")
  trap 'rm -rf -- "$staging"' EXIT
  git -C "$repo" archive "$revision" graph files/fonts/BankGothic.ttf \
    files/sddm/Gently-Blur-SDDM-6/anim | tar -x -C "$staging"
  chmod 755 "$staging"
  mv -- "$staging" "$releases/$revision"
  trap - EXIT
fi
ln -sfn -- "releases/$revision" "$base/current.next"
mv -Tf -- "$base/current.next" "$base/current"
printf 'Published revision %s\n' "$revision"
