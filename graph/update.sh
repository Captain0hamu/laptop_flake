#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
repo_dir="$(cd -- "$script_dir/.." && pwd)"

# Nix normally writes its fetcher cache below the user's home. Using /tmp also
# lets this script run in restricted development environments.
export XDG_CACHE_HOME="${XDG_CACHE_HOME:-${TMPDIR:-/tmp}/nix-dependency-graph-cache-${UID}}"

exec node "$script_dir/generate.mjs" "$repo_dir" "$script_dir/dependency-data.js"
