#!/usr/bin/env bash
# Pane entrypoint: report first, delete only after an explicit y.
# ponytail: no -u — macOS ships bash 3.2, where "${arr[@]}" on an empty array
# is an unbound-variable error.
set -o pipefail

bin="$HERDR_PLUGIN_ROOT/target/release/diskzap"
if [[ ! -x "$bin" ]]; then
  bin="$(command -v diskzap)"
fi
if [[ ! -x "$bin" ]]; then
  echo "diskzap binary not found." >&2
  echo "Build it: cd $HERDR_PLUGIN_ROOT && cargo build --release" >&2
  read -rsn1 -p "Press any key to close. "
  exit 1
fi

# Optional scan roots for build artifacts, one path per line. diskzap never
# walks a directory you did not name, so with no config this reports package
# caches and Docker only.
roots=()
conf="$HERDR_PLUGIN_CONFIG_DIR/roots"
if [[ -f "$conf" ]]; then
  while IFS= read -r line || [[ -n "$line" ]]; do
    case "$line" in ''|'#'*) continue ;; esac
    roots+=(--root "${line/#\~/$HOME}")
  done < "$conf"
fi

"$bin" "${roots[@]}"
status=$?
if [[ $status -ne 0 ]]; then
  read -rsn1 -p "diskzap exited $status. Press any key to close. "
  exit $status
fi

echo
read -rn1 -p "Delete the above? [y/N] " reply
echo
case "$reply" in
  y|Y) ;;
  *) echo "Nothing deleted."; sleep 1; exit 0 ;;
esac

"$bin" --apply "${roots[@]}"
echo
read -rsn1 -p "Press any key to close. "
