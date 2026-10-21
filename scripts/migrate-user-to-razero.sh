#!/usr/bin/env bash
# Run as root on a separate TTY after logging out both users.
set -euo pipefail

if [[ $EUID != 0 ]]; then
  echo 'Run this from a root TTY.' >&2
  exit 1
fi

migration_system=${1:?Pass the already built NixOS system path}
[[ $migration_system == /nix/store/*-nixos-system-* ]]
[[ -x $migration_system/bin/switch-to-configuration ]]
[[ $(id -u nix) == 1000 && $(id -u razero) == 1001 ]]
[[ $(getent passwd nix | cut -d: -f6) == /home/nix ]]
[[ $(getent passwd razero | cut -d: -f6) == /home/razero ]]
if getent passwd razero-trial >/dev/null; then
  echo 'razero-trial already exists; inspect the account state first.' >&2
  exit 1
fi
if pgrep -a -u 1000,1001; then
  echo 'Both users must log out and all their processes must stop first.' >&2
  exit 1
fi

umask 077
migration_backup=$(mktemp -d /root/razero-migration.XXXXXXXX)
cp -a /etc/passwd /etc/shadow /etc/group "$migration_backup/"
if [[ -e /etc/gshadow ]]; then
  cp -a /etc/gshadow "$migration_backup/"
fi
cp -a /var/lib/nixos "$migration_backup/nixos-state"
readlink -f /run/current-system > "$migration_backup/previous-system"
printf '%s\n' "$migration_backup" > /root/razero-migration-latest
echo "Backup: $migration_backup"

usermod -l razero-trial razero
if ! usermod -l razero nix; then
  usermod -l razero razero-trial
  echo 'Original login names restored; migration stopped.' >&2
  exit 1
fi

# Change the system generation as nixos-rebuild switch would, then activate it.
# If activation fails, keep the account backups and report the recovery location.
if ! nix-env -p /nix/var/nix/profiles/system --set "$migration_system" ||
   ! "$migration_system/bin/switch-to-configuration" switch; then
  echo "Activation failed. Stay logged in as root; backup: $migration_backup" >&2
  exit 1
fi

[[ $(id -u razero) == 1000 && $(id -u razero-trial) == 1001 ]]
[[ $(getent passwd razero | cut -d: -f6) == /home/nix ]]
systemctl is-active home-manager-razero.service
getent passwd razero razero-trial
echo 'Migration applied. Test razero login and sudo before removing razero-trial.'
