# Helmi Ops for Cursor

**Status:** verified on a real Cursor Desktop install (2026-09-15):
`helmi-local` connects and Cursor's own MCP UI shows all 44 tools. This
package is for macOS Apple Silicon only.

**Privacy Policy:** https://helmicore.com/privacy · **Terms of Service:**
https://helmicore.com/terms

**Submission target:** Cursor Marketplace needs a public Git repository,
and this directory's parent (the `helmi` monorepo) is not it — submit
against [luckcyq/helmi-ops-plugins](https://github.com/luckcyq/helmi-ops-plugins)
instead, a public repo exported specifically for plugin distribution
(see that repo's own `.cursor-plugin/marketplace.json` at its root,
declaring this package's path as `helmi-ops-cursor`). This directory in
the main monorepo is the source of truth; changes here get synced there
before each release, the same way the packaged binaries already are.

## Automatic Setup & Zero-Config Execution

`mcp.json` declares `helmi-local` as `{"command": "./scripts/helmi-local",
"cwd": "${CURSOR_PLUGIN_ROOT}"}` — Cursor's own documented mechanism
(https://prod.cursor.com/docs/reference/plugins: "Cursor expands
`${CURSOR_PLUGIN_ROOT}`... in `command`, `args`, `env` values, and `cwd`").
This replaced an earlier hand-rolled self-locating `sh -c` launcher that
used the generic Agent Plugins standard's `${PLUGIN_ROOT}` — that variable
is explicitly *not* expanded by Cursor per the same docs, which is
consistent with why a real install once failed to resolve it (see
`install.sh`'s own comment for that history). **Confirmed on a real
Cursor Desktop install (2026-09-15):** after copying this package to
`~/.cursor/plugins/local/helmi-ops-cursor` and reloading, `helmi-local`
connected and Cursor's own MCP UI listed all 44 tools — `${CURSOR_PLUGIN_ROOT}`
resolves correctly, no `install.sh` step needed.

A second, separate issue surfaced on the same install: Cursor 3.20.21's
MCP UI validator discards the *entire* tool list if any single tool's
`outputSchema` isn't top-level `"type": "object"` — it first showed
"connected, 0 tools" because 5 tools had a top-level array schema. Fixed
by wrapping those 5 in `{"type": "object", "properties": {"items": <array
schema>}}` (see `runtime/internal/mcp/schema.go`) — this turned out to
be the actually-correct fix per the negotiated `protocolVersion`
`2025-06-18`'s own spec (structured content "is returned as a JSON
object"), not merely a Cursor quirk. Re-verified after this fix: 44
tools, all visible.

### Optional: Manual Offline Installation (`install.sh`)

If you are running in an isolated environment or wish to install the runtime binaries to a fixed directory (`~/.helmi/runtime/helmi-ops-cursor/`), you can optionally run:

```sh
./install.sh
```

This copies `helmi-local` and `helmi-compress-worker` to `~/.helmi/runtime/` and points `mcp.json` to the absolute binary path. Run it from the installed plugin directory.

## Sign in or reconnect Helmi Cloud

Open **Customize → MCP servers**, find **helmi-cloud**, and click
**Connect** or **Reconnect**. Cursor opens the normal Helmi OAuth sign-in and
stores/refreshes its own credentials; do not paste a bearer token into
`mcp.json`.

For Cursor CLI, run `agent mcp list` to find the installed helmi-cloud server
identifier, then run `agent mcp login <identifier>`. Both paths use the same
PKCE OAuth flow and are safe to repeat when the connection has expired.

## What's in this package today

- `helmi-local` (stdio): local device SSH, macOS Keychain, Prometheus,
  Evidence, and the loopback Local UI. Runs entirely on this machine.
- `helmi-cloud` (remote): Helmi Cloud's bounded diagnostic knowledge and
  probe-bundle resolution. Cursor Desktop authorizes it with PKCE using its
  fixed, Helmi-approved client ID and localhost callback; no client secret is
  stored in this package.

This plugin supports local Cursor Desktop sessions only. Cursor
Cloud/Background Agent use is unsupported and unverified.

## Platform support

**macOS Apple Silicon (arm64) only.** The bundled native executables are
arm64 Mach-O binaries. This package must not be installed on Intel Macs,
Windows, or Linux. `plugin/build.sh cursor` rebuilds and MCP-smoke-tests
the package; the local Cursor Desktop install also showed all 44 tools.
