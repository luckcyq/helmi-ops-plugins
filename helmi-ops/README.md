# Helmi Ops for Codex

**Status:** verified through a real Codex personal-marketplace install and
live OAuth connection; not yet submitted for public review. See
[`../SECURITY-MODEL.md`](../SECURITY-MODEL.md) for how `helmi-local`/
`helmi-cloud` actually enforce safety across all three packages.

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

## Platform Support

- **macOS (Apple Silicon / arm64):** the package tracked in this
  directory. Verified via `plugin/build.sh codex` (rebuild + real MCP
  smoke test) on every change.
- **Windows (amd64):** built and smoke-tested by `.github/workflows/
  release.yml`'s `build-windows` job — `helmi-local.exe` and
  `helmi-compress-worker.exe` compile on a real `windows-latest` runner
  and pass the same real MCP initialize/tools-list and compress-worker
  protocol checks as the macOS build (confirmed 2026-09-15, after fixing
  two real bugs this job's own runs caught: a Windows-only
  `syscall.Close` type mismatch, and `helmi-local` silently shipping a
  non-functional `go-sqlite3` stub because it was built with
  `CGO_ENABLED=0`). **What is NOT yet confirmed:** a real Codex install
  on an actual Windows machine — the smoke test proves the binary itself
  runs and speaks MCP correctly, not that Codex's Windows client can
  discover, launch, and use this package end to end. Treat Windows
  support as CI-verified, not field-verified, until someone actually
  installs it in real Codex on Windows.
- **Linux:** not packaged from this directory; see
  `.github/workflows/release.yml`'s `build-linux` job, which packages
  `helmi-ops` for linux-amd64 separately (also gained a real smoke test
  alongside the Windows work, after which the exact same `CGO_ENABLED=0`
  mistake was found and fixed there too).

**What is actually submitted for public review is this directory as-is**
(macOS Apple Silicon binaries only). Do not describe the submission as
covering Windows, Linux, or Intel Mac — those are separate zip
distributions outside whatever install path a Codex Marketplace/plugin
directory listing uses, and none of that has been confirmed to support
per-platform binary selection the way this note might otherwise imply.
