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
