# Helmi Ops for Claude Code

**Status:** local testing only — not published to a Marketplace. See
[`docs/plugin-packaging.md`](../../docs/plugin-packaging.md) for the shared
packaging history and open items across all three plugin packages (Codex,
Cursor, Claude Code), and [`../SECURITY-MODEL.md`](../SECURITY-MODEL.md)
for how `helmi-local`/`helmi-cloud` actually enforce safety across all
three.

**Privacy Policy:** https://helmicore.com/privacy · **Terms of Service:**
https://helmicore.com/terms. (Not declared in `plugin.json` — confirmed via
`claude plugin validate` that `privacyPolicy`/`termsOfService`/`icon` are not
real fields in Claude Code's plugin manifest schema; it ignores them at load
time, so they live here instead, where a reviewer or user actually reads
them.)

## Installing

Claude Code's plugin discovery is marketplace-based on both the CLI and the
desktop app's Code tab — unlike Codex/Cursor, you cannot just point either
surface at a bare plugin directory. This package's own directory doubles as
a single-plugin marketplace via `.claude-plugin/marketplace.json` (its one
entry's `source` is `"."`, the marketplace root itself), so no separate
marketplace repo or `plugins/` subdirectory is needed.

In the desktop app's Code tab (or the CLI — the same `/plugin` slash
commands work in both):

```
/plugin marketplace add /absolute/path/to/helmi/plugin/helmi-ops-claude
/plugin install helmi-ops@helmi-ops-claude
```

Use the absolute path to this directory on your machine. After installing,
reload the Code tab / restart Claude Code so it picks up the new MCP
servers, then check that `helmi-local`'s tools (e.g. `list_devices`,
`collect_probe`) appear.

No `install.sh` step is needed here, unlike the Cursor package. Claude Code's
plugin manifest supports `${CLAUDE_PLUGIN_ROOT}` as a substitution variable
directly inside an MCP server's `command` field
(`.mcp.json`'s `helmi-local` entry uses it), so the stdio server resolves to
this plugin's real install directory without any relative-path workaround.
This is a real, documented difference from both other packages: Codex's own
loader resolves a `cwd: "."` override correctly (its own package uses that),
and Cursor resolves neither relative `command` nor `cwd` at all (see
`plugin/helmi-ops-cursor/install.sh` for that workaround). `${CLAUDE_PLUGIN_ROOT}`
is per Anthropic's own plugin reference docs, and is now also empirically
confirmed, not just documented: installed via `/plugin marketplace add`
and `/plugin install` on a real Claude Code CLI session (2026-09-15),
`list_devices` was called through `plugin:helmi-ops:helmi-local` and
returned this machine's real configured device inventory with no device
actually contacted — the substitution resolves correctly with no
`install.sh`-style workaround needed on this harness.

## OAuth Compatibility: Restricted Registration Endpoint & Static Client Support

`helmi-cloud`'s `.mcp.json` entry declares `oauth.clientId: "helmi-ops-claude"` and `oauth.callbackPort: 8788`. In addition, Helmi Cloud's OAuth server implements an RFC 7591 Dynamic Client Registration (`/api/v1/oauth/register`) endpoint.

The endpoint returns the pre-approved `helmi-ops-claude` public client only for the configured loopback callback at port 8788. It is compatible with that declared static-client flow, but it is not general dynamic client registration.

**Confirmed end-to-end on a real Claude Code CLI session (2026-09-15):**
`/mcp` authorization succeeded ("Connected to plugin:helmi-ops:helmi-cloud"),
a live `helmi-cloud` tool call (`list_probe_capabilities` for `cisco_ios`)
returned real data, and after fully exiting and restarting the CLI session
a second `helmi-cloud` tool call worked with no re-authorization prompt —
the stored refresh token is picked up correctly across a restart on this
harness.

## Try it

Three reproducible use cases against your own configured devices (add one
first via `save_device`, or through `open_device_manager`, if you have
none yet). These are example prompts to type in chat, not a canned
transcript — what you see back depends on your own inventory. Example IPs
below use RFC 5737's reserved documentation ranges
(`192.0.2.0/24`/`198.51.100.0/24`) — substitute your own device's `id`.

**1. Device health check** (pure local read, no device contacted):
```
List my devices, then show me the full profile for device "core-sw1"
(host 192.0.2.10).
```
Expect `list_devices` then `get_device_profile` — both read only the
locally stored, non-secret descriptor; `reachability` reflects the last
collection, not a fresh probe.

**2. Read-only configuration audit** (contacts the device over SSH):
```
Pull the running configuration from core-sw1 and check it against the
last saved baseline.
```
Expect a Cloud-resolved `config.running` probe via `collect_probe`. Before
the first SSH read to that device, Claude Code should pause for your
elicitation approval — if it doesn't pause and the SSH call still
succeeds, something is wrong; approval bypass is not supposed to be
possible (see `../SECURITY-MODEL.md` §3). Approve it, then ask to
`capture_baseline` and later `diff_config_snapshots` once you have two
snapshots to compare.

**3. Prometheus alert analysis** (contacts your configured Prometheus, if
any):
```
Is my Prometheus for core-sw1 healthy, and are there any active alerts?
```
Expect `get_prometheus_status` then `list_prometheus_alerts`, both scoped
to that device's saved monitoring binding — never a legacy fallback URL,
and an explicit error (not a silent skip) if the device has no binding.

## What's in this package today

- `helmi-local` (stdio): local device SSH, macOS Keychain, Prometheus,
  Evidence, and the loopback Local UI. Runs entirely on this machine.
- `helmi-cloud` (remote, OAuth): Helmi Cloud's bounded diagnostic knowledge
  and probe-bundle resolution. See the known-risk section above before
  relying on this in a given Claude Code version.

This plugin does not address whether `helmi-local` runs safely under any
Claude Code cloud/remote execution mode — that boundary has not been
investigated for this harness (see the Cursor package's own equivalent,
still-unconfirmed caveat in `docs/plugin-packaging.md`).
