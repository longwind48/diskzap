#!/usr/bin/env bash
# Action entrypoint: opens the report pane. Actions only write to the plugin
# log, so the action's whole job is to hand off to the pane, which a human
# can actually read and answer.
set -o pipefail
exec "${HERDR_BIN_PATH:-herdr}" plugin pane open \
  --plugin "$HERDR_PLUGIN_ID" --entrypoint report
