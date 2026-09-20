# Helmi Ops for Codex

**Platform: macOS Apple Silicon (arm64) only.** The bundled native
executables will not run on Intel Macs, Windows, or Linux.

**Status:** verified through a real Codex personal-marketplace install and
live OAuth connection, on Apple Silicon.

**Privacy Policy:** https://helmicore.com/privacy · **Terms of Service:**
https://helmicore.com/terms

## Installing

Point Codex at this package's directory directly — no marketplace
manifest is needed on this harness, unlike Claude Code (see
`../helmi-ops-claude/README.md`). Rebuild and verify the packaged binary
before any release with:

```sh
plugin/build.sh codex
```

## What's in this package today

- `helmi-local` (stdio): local device SSH, macOS Keychain, Prometheus,
  Evidence, and the loopback Local UI. Runs entirely on this machine.
- `helmi-cloud` (remote): Helmi Cloud's bounded diagnostic knowledge and
  probe-bundle resolution. **Note:** unlike the Claude Code and Cursor
  packages, this package's `.mcp.json` declares `helmi-cloud` with no
  `oauth` block. This is likely intentional, not a gap: Cloud's
  `cloud/app/api/oauth.py` has a dedicated trusted-client entry for Codex
  (`_codex_desktop_client`) using a self-describing client-id-metadata
  document (`client_id_metadata_document_supported: true`,
  `client_id = "https://chatgpt.com/oauth/codex/client.json"`) rather than
  the fixed `clientId`/local-callback-port pair Claude Code and Cursor
  declare up front — a different OAuth discovery model, not a missing one.
  Verified end to end on a real Codex install (2026-09-15): the Connect
  flow completed OAuth and a live `helmi-cloud` `list_probe_capabilities`
  call for `cisco_ios` returned 47 probes.

## Platform support

**macOS Apple Silicon (arm64) only.** The runtime keeps device
credentials in the macOS Keychain and drives macOS's own OpenSSH, so
Intel Macs, Windows, and Linux are unsupported.

`plugin/build.sh codex` rebuilds and MCP-smoke-tests this package before
release, on the machine doing the release.
