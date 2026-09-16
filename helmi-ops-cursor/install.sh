#!/bin/sh
# Installs this plugin's local Runtime onto a fixed path and points this
# copy's mcp.json at it directly.
#
# Why this exists: mcp.json's primary mechanism is Cursor's own
# documented "cwd": "${CURSOR_PLUGIN_ROOT}" (Cursor expands this before
# spawning "command" — the generic Agent Plugins standard's "${PLUGIN_ROOT}"
# is explicitly NOT expanded by Cursor, confirmed at
# https://prod.cursor.com/docs/reference/plugins — an earlier "cwd":
# "${PLUGIN_ROOT}"/"." attempt using that wrong variable name was tried
# and confirmed not to work on a real install, before this fix). This
# script remains as a manual fallback — a documented mechanism can still
# regress across a Cursor version, and this has not yet been re-verified
# against a real Cursor Desktop install since switching to
# ${CURSOR_PLUGIN_ROOT}. Codex's own packaging in this repo needs no
# such workaround: its plugin loader resolves "cwd": "." against the
# plugin directory correctly, which is specific to Codex.
#
# Run this from an *installed* copy of the plugin (e.g. after copying it
# into ~/.cursor/plugins/local/helmi-ops-cursor, or after a Marketplace
# install) — never from a git checkout of this repo, since it rewrites
# mcp.json in place with a machine-specific absolute path that must never
# be committed. The check below refuses to run inside a git work tree as
# a safety net against exactly that mistake.
set -eu

DIR="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"

if git -C "$DIR" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "install.sh: refusing to run inside a git checkout ($DIR)." >&2
  echo "Copy this plugin directory to where Cursor actually loads it from first" >&2
  echo "(e.g. ~/.cursor/plugins/local/helmi-ops-cursor), then run install.sh from there." >&2
  exit 1
fi

# Deliberately not named "bin": confirmed on a real machine that a
# directory literally named ~/.helmi/bin gets a freshly-written executable
# SIGKILLed on every launch (no quarantine xattr, no Gatekeeper rejection
# recorded — some local security tooling's own heuristic against
# executables dropped in home-directory "bin" folders, a known malware
# persistence pattern). Same bytes ran fine from every other directory
# name tried, including other names under ~/.helmi/. Not chasing the exact
# tool/rule further since avoiding the trigger entirely is simpler and
# just as correct.
#
# Namespaced by plugin name (not a shared .../runtime/helmi-local) so a
# second plugin, or a second install of this one, can't silently overwrite
# a binary the other is still using.
TARGET_DIR="$HOME/.helmi/runtime/helmi-ops-cursor"
mkdir -p "$TARGET_DIR"

# Write alongside the target and rename into place rather than cp'ing
# directly onto it: `cp` is not atomic, so a client that execs
# helmi-local mid-copy (e.g. Cursor reconnecting while install.sh is
# rerun to pick up an update) could see a truncated binary. A same-
# directory `mv` is a single rename on one filesystem, so any given exec
# sees either the old file or the new one, never a partial write.
#
# helmi-compress-worker (docs/diagnostic-compression-plan.md) moves the
# same way: a running helmi-local looks for it next to its own
# os.Executable() path, which after this install is
# $TARGET_DIR/helmi-local.bin — so it must land in $TARGET_DIR too, under
# its own unmodified name (no .bin suffix — see
# runtime/internal/mcp/server.go's defaultCompressionRunner, which looks
# up that exact filename), or collect_probe's compression path silently
# reports unsupported_module on every call after a real Cursor install.
cp "$DIR/scripts/helmi-local" "$TARGET_DIR/helmi-local.new"
cp "$DIR/scripts/helmi-local.bin" "$TARGET_DIR/helmi-local.bin.new"
cp "$DIR/scripts/helmi-compress-worker" "$TARGET_DIR/helmi-compress-worker.new"
chmod +x "$TARGET_DIR/helmi-local.new" "$TARGET_DIR/helmi-compress-worker.new"
mv "$TARGET_DIR/helmi-local.bin.new" "$TARGET_DIR/helmi-local.bin"
mv "$TARGET_DIR/helmi-compress-worker.new" "$TARGET_DIR/helmi-compress-worker"
mv "$TARGET_DIR/helmi-local.new" "$TARGET_DIR/helmi-local"

python3 - "$DIR/mcp.json" "$TARGET_DIR/helmi-local" <<'PY'
import json
import pathlib
import sys

mcp_path, bin_path = pathlib.Path(sys.argv[1]), sys.argv[2]
mcp = json.loads(mcp_path.read_text())
mcp["mcpServers"]["helmi-local"]["command"] = bin_path
mcp["mcpServers"]["helmi-local"].pop("args", None)
# An absolute command needs no cwd substitution — and leaving the
# unexpanded "${CURSOR_PLUGIN_ROOT}" literal in place would break this
# override outright if that's exactly the substitution this manual
# fallback is being run to work around.
mcp["mcpServers"]["helmi-local"].pop("cwd", None)
mcp_path.write_text(json.dumps(mcp, indent=2) + "\n")
PY

echo "Installed $TARGET_DIR/helmi-local and pointed $DIR/mcp.json at it."
echo "Reload the helmi-local MCP server in Cursor (or restart Cursor) to pick it up."
