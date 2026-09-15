# Helmi Ops for Cursor

**Status:** local testing only — not published to a Marketplace. See
[`docs/plugin-packaging.md`](../../docs/plugin-packaging.md) for the full
plan and its current, honestly-tracked open items, and
[`../SECURITY-MODEL.md`](../SECURITY-MODEL.md) for how `helmi-local`/
`helmi-cloud` actually enforce safety across all three packages.

## Automatic Setup & Zero-Config Execution

The package includes an experimental launcher which attempts to resolve the plugin installation directory via `${PLUGIN_ROOT}`. This variable is not yet verified as a Cursor Marketplace runtime contract, so Marketplace one-click installation remains an open release requirement. Do not claim automatic local-runtime startup until it has passed an installed-Marketplace test.

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

This plugin never runs `helmi-local` under a Cursor Cloud/Background
Agent — that boundary and its verification status are documented in the
plan doc, not enforced by anything in this package alone.
