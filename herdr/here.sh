#!/usr/bin/env bash
# Popup entrypoint: what is reclaimable under the directory you are looking at,
# with the option to reclaim it.
#
# Uses --only-roots, which is what makes this a glance rather than a wait. A
# plain report sizes every global cache first: 69s on one machine against 0.85s
# scoped to a single project, and the popup discards the global numbers anyway.
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
# a full-home walk. With no directory to scope to there is nothing useful to say.
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

# ${cwd/#$HOME/~} silently fails to match here, so be explicit about it.
if [[ "$cwd" == "$HOME"* ]]; then disp="~${cwd#"$HOME"}"; else disp="$cwd"; fi
out=$(mktemp)
trap 'rm -f "$out"' EXIT

# dotsCircle, from github.com/simeg/bash-cli-spinners (80ms interval). A popup
# that draws nothing while it works looks broken, which is how the first version
# of this read even when the scan was quick.
frames=('⢎ ' '⠎⠁' '⠊⠑' '⠈⠱' ' ⡱' '⢀⡰' '⢄⡠' '⢆⡀')

printf '\n  \033[1mReclaimable here\033[0m  %s\n' "$disp"
printf '  %s\n' "$(printf '─%.0s' {1..62})"

"$bin" --root "$cwd" --only-roots --no-external --json >"$out" 2>/dev/null &
scan=$!
i=0
while kill -0 "$scan" 2>/dev/null; do
  printf '\r  \033[2m%s scanning…\033[0m' "${frames[$((i % 8))]}"
  i=$((i + 1))
  sleep 0.08
done
wait "$scan"
printf '\r\033[K'

summary=$(python3 "$HERDR_PLUGIN_ROOT/herdr/here.py" "$cwd" <"$out")
printf '%s\n' "$summary"

# Nothing to offer if nothing was found.
if ! printf '%s' "$summary" | grep -q 'across'; then
  echo
  read -rsn1 -p "  Press any key to close. "
  exit 0
fi

echo
read -rn1 -p "  Reclaim it? [y/N] " reply
echo
case "$reply" in
  y | Y) ;;
  *)
    echo "  Nothing deleted."
    sleep 0.6
    exit 0
    ;;
esac

printf '\n'
"$bin" --apply --root "$cwd" --only-roots --no-external 2>&1 | tail -4
echo
read -rsn1 -p "  Press any key to close. "
