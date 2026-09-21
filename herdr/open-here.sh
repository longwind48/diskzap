#!/usr/bin/env bash
# Action entrypoint: opens the popup. Actions only write to the plugin log, so
# the action's whole job is to hand off to a surface a human can read.
set -o pipefail
exec "${HERDR_BIN_PATH:-herdr}" plugin pane open \
  --plugin "$HERDR_PLUGIN_ID" --entrypoint here
