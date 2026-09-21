#!/usr/bin/env bash
# Popup entrypoint: what is reclaimable *under the directory you are looking at*.
#
# Read-only on purpose. This is a glance you summon with one key while working,
# so it should never be one keystroke away from deleting a build you are still
# using. The `report` pane is the entrypoint that can apply.
set -o pipefail

bin="$HERDR_PLUGIN_ROOT/target/release/diskzap"
[[ -x "$bin" ]] || bin="$(command -v diskzap)"
if [[ ! -x "$bin" ]]; then
  echo
  echo "  diskzap binary not found."
  echo "  Build it: cd $HERDR_PLUGIN_ROOT && cargo build --release"
  echo
  read -rsn1 -p "  Press any key to close. "
  exit 1
fi

# herdr hands us the focused pane's cwd, which is the directory the human is
# actually looking at. Fall back to the workspace's.
#
# Deliberately NOT falling back to $HOME: that turns a one-keystroke glance into
# a full-home walk that takes long enough to look broken. With no directory to
# scope to there is nothing useful to say, so say that instead.
cwd=$(printf '%s' "${HERDR_PLUGIN_CONTEXT_JSON:-}" | python3 -c '
import json, sys
try:
    c = json.load(sys.stdin)
except Exception:
    c = {}
print(c.get("focused_pane_cwd") or c.get("workspace_cwd") or "")
' 2>/dev/null)

if [[ -z "$cwd" || ! -d "$cwd" ]]; then
  echo
  echo "  No directory in context, so there's nothing to scope a scan to."
  echo "  Open the full report instead:"
  echo "    herdr plugin pane open --plugin $HERDR_PLUGIN_ID --entrypoint report"
  echo
  read -rsn1 -p "  Press any key to close. "
  exit 0
fi

# --no-external keeps docker prune and brew cleanup out of a read-only glance.
"$bin" --root "$cwd" --no-external --json 2>/dev/null \
  | python3 "$HERDR_PLUGIN_ROOT/herdr/here.py" "$cwd"

echo
read -rsn1 -p "  Press any key to close. "
