# Helmi Ops for Codex

**Status:** local testing only — not published to a Marketplace. The
release *process* below is approved and implemented (see
[`docs/plugin-packaging.md`](../../docs/plugin-packaging.md) for the
shared packaging history and open items across all three plugin packages),
but no real external Codex Marketplace install has been done yet. See
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
  This has not been exercised end-to-end against a real Codex install the
  way the Claude Code flow has (see `../SECURITY-MODEL.md` §6), so treat
  it as "plausibly by design, not yet empirically confirmed."

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
