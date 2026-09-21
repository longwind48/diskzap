#!/usr/bin/env bash
# Register diskzap's herdr keybinding.
#
# herdr's plugin v1 has no runtime key registration — [[keys.command]] lives in
# the user's own config.toml — so a plugin that wants a key has to ask for one.
# This prints what it would do and changes nothing unless you pass --yes.
set -euo pipefail

KEY="${DISKZAP_HERDR_KEY:-prefix+shift+z}"
PLUGIN_ID="longwind48.diskzap"
ACTION="$PLUGIN_ID.here"
APPLY=0

for arg in "$@"; do
  case "$arg" in
    -y|--yes) APPLY=1 ;;
    -h|--help)
      cat <<USAGE
usage: bash install.sh [--yes]

Adds a herdr keybinding for diskzap's "reclaimable here" popup.

  --yes     actually write the config (default: print and exit)

env:
  DISKZAP_HERDR_KEY   override the key combo (default: $KEY)
USAGE
      exit 0 ;;
    *) echo "unknown argument: $arg" >&2; exit 2 ;;
  esac
done

herdr_bin="${HERDR_BIN_PATH:-$(command -v herdr || true)}"
if [ -z "$herdr_bin" ]; then
  echo "error: herdr not found on PATH. Install herdr first: https://herdr.dev" >&2
  exit 1
fi

case "$(uname -s)" in
  Darwin|Linux) config="$HOME/.config/herdr/config.toml" ;;
  *) config="${APPDATA:-$HOME}/herdr/config.toml" ;;
esac

block() {
  cat <<EOF
[[keys.command]]
key = "$KEY"
type = "plugin_action"
command = "$ACTION"
description = "reclaimable space in this directory"
EOF
}

echo "==> Plugin:   $PLUGIN_ID"
echo "==> Keybinding ($KEY -> the reclaimable-here popup) in $config:"
echo
block | sed 's/^/    /'
echo

# Idempotency: key off the action name rather than the key combo, so re-running
# after someone has rebound it does not add a second block for the same action.
if [ -f "$config" ] && grep -q "$ACTION" "$config"; then
  echo "==> Already registered — nothing to do."
  exit 0
fi

if [ -f "$config" ] && grep -q "\"$KEY\"" "$config"; then
  echo "warning: $KEY is already bound to something else in $config."
  echo "         Set DISKZAP_HERDR_KEY to pick another, or edit the file yourself."
  echo
fi

if [ "$APPLY" -eq 0 ]; then
  echo "==> Dry run. Re-run with --yes to apply."
  exit 0
fi

if [ -f "$config" ]; then
  backup="$config.bak.$(date +%s)"
  cp "$config" "$backup"
  printf '\n%s\n' "$(block)" >> "$config"
  echo "==> Added to $config (backup: $backup)"
else
  mkdir -p "$(dirname "$config")"
  block > "$config"
  echo "==> Created $config"
fi

if "$herdr_bin" server reload-config >/dev/null 2>&1; then
  echo "==> Reloaded the running herdr server. Press $KEY to try it."
else
  echo "==> No running herdr server to reload; the binding applies next start."
fi
