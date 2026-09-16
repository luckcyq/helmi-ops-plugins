# Helmi Ops for Cursor

**Status:** package structure and manifests are submission-ready; not yet
submitted, and not yet installed through a real Cursor Marketplace flow.
See [`docs/plugin-packaging.md`](../../docs/plugin-packaging.md) for the
full plan and its current, honestly-tracked open items, and
[`../SECURITY-MODEL.md`](../SECURITY-MODEL.md) for how `helmi-local`/
`helmi-cloud` actually enforce safety across all three packages.

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
`install.sh`'s own comment for that history). **This fix has not yet been
re-verified against a real Cursor Desktop install** — `plugin/build.sh
cursor`'s automated launch test only simulates the documented behavior
(`cd` into the plugin directory, then run the declared relative command),
which is not proof Cursor's own substitution behaves identically on a
real install.

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

## Platform Support

- **macOS:** the package tracked in this directory. Verified via
  `plugin/build.sh cursor` (rebuild + real MCP smoke test, plus an
  automated launch test and an `install.sh` backwards-compatibility
  test) on every change.
- **Windows (amd64):** a separate package, built and smoke-tested by
  `.github/workflows/release.yml`'s `build-windows` job, not tracked in
  this directory, and **not installable through Cursor Marketplace** —
  Marketplace installs straight from this directory's own git-tracked
  `mcp.json`/`scripts/helmi-local`, which are POSIX-only; there is no
  per-platform selection at the Marketplace level (see
  `../helmi-ops-claude/README.md`'s equivalent note on why Claude Code
  has the identical constraint). The Windows package is a manual
  zip-and-run distribution outside Marketplace, using `mcp.windows.json`
  (referencing `helmi-local.exe` directly, no POSIX shebang launcher)
  and `install.ps1` (a plain PowerShell port of `install.sh`'s design).
  Confirmed 2026-09-15: `helmi-local.exe`/`helmi-compress-worker.exe`
  compile on a real `windows-latest` runner and pass the same real
  MCP/protocol smoke tests as the macOS build. `install.ps1`'s own logic
  (git-checkout safety guard, atomic install, `mcp.json` rewrite) was
  tested end to end with PowerShell Core, but **not on a real Windows
  machine, and not against a real Cursor install** — nothing has
  confirmed Cursor for Windows can actually discover and launch this
  package yet. Treat Windows support as CI-verified, not field-verified.
- **Linux:** not packaged from this directory; see
  `.github/workflows/release.yml`'s `build-linux` job. Same Marketplace
  constraint as Windows applies in reverse for Linux users going through
  Marketplace rather than the manual zip — POSIX `scripts/helmi-local`
  itself works fine on Linux, this has just never been tested there.
