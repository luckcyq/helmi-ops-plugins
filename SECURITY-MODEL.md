# Helmi Ops — Security Model

This document collects, in one place, the security-relevant properties of
all three Helmi Ops packages (`helmi-ops` for Codex, `helmi-ops-claude` for
Claude Code, `helmi-ops-cursor` for Cursor Desktop). Each package's own
README describes installation and platform-specific behavior; this file is
the single reference for how the underlying `helmi-local` Runtime and
`helmi-cloud` service actually enforce safety, so a reviewer does not have
to reconstruct it from Skill prose and source comments scattered across the
codebase.

## 1. What actually runs, and where

- **`helmi-local`** is a local stdio MCP server. It runs only as a
  subprocess of the installed chat client (Codex/Claude Code/Cursor),
  for the lifetime of that client's session. It has network access to
  whatever the operator's own machine can reach (typically the operator's
  own internal network) and to the operator's macOS Keychain for stored
  device credentials.
- **`helmi-cloud`** is a remote, OAuth-protected MCP server. Its declared
  OAuth scope is `helmi:read`. It resolves diagnostic knowledge and issues
  signed probe bundles; it does not have — and cannot obtain — inbound
  network access to an operator's private infrastructure. Cloud never
  reaches into a customer's network; only the customer's own `helmi-local`
  (or, for scheduled monitoring, the separate `helmi-agent` unattended
  service — see §5) ever makes an outbound connection to a device.
- No third-party service (Jira, ServiceNow, Slack, a CMDB, etc.) is bundled
  into either component. If a Skill uses one, the operator configures it as
  its own separate, independently-credentialed MCP server; Helmi never
  receives or stores that service's token.

## 2. Every SSH probe is Cloud-signed; the caller can't choose the command

`collect_probe` and `collect_probe_batch` never accept a command, a config
payload, or an access level as a tool argument — that's a deliberate schema
omission, not an oversight. The only way to run an SSH probe is to pass a
bundle Helmi Cloud already signed via `resolve_probe`/`resolve_probe_batch`.
Local verifies that signature (Ed25519) before anything runs; the actual
command, its access level, and its config all come from the verified bundle
Execution, never from caller input. A chat client — and, by extension,
whatever LLM is driving it — chooses *which* probe to request and *on which
device*, never *what shell command actually executes*.

The production build only trusts the real production signing key
(`runtime/internal/probe/keys_production.go`, gated behind `-tags
production`); an explicit test
(`TestKeysProductionNeverTrustsTheDevKey`) prevents the development key from
ever being added to that trust set. `plugin/build.sh`'s `claude`/`codex`/
`cursor` targets all build the packaged binary with `-tags production`, so
every binary actually shipped in these three packages verifies against the
real key, not a development one.

## 3. First SSH use requires explicit, client-bound approval

Before the *first* uncached SSH read to a given device endpoint, Local
requests approval via MCP elicitation and stores it locally for later
tasks. Changing that device's host or platform requires approval again.
**No tool argument can bypass this** — a client without elicitation support
gets `error_code: CLIENT_ELICITATION_UNSUPPORTED` and no SSH command runs
at all, rather than silently skipping the approval step.

This is a client-side UX affordance, not the actual safety boundary: a
Skill's "ask before calling `collect_probe`" instruction is prose a given
model/harness may or may not follow, and elicitation support itself varies
by client. The property that's actually enforced regardless of client,
model, or whether a confirmation prompt fired is `policy.Evaluate` (Local's
own command allowlist) plus signed-bundle verification (§2) — both run
inside `runtime/` on every `collect_probe`/`collect_probe_batch` call, with
no path around them.

## 4. Local data stays local, and is bounded/redacted before storage

- SSH output and Prometheus reads are stored as local Evidence — capped
  (64 KiB full output; grep/range reads capped at 8 KiB) and redacted
  before persistence.
- `save_device`/`list_http_connections` never store or expose credentials
  or bearer tokens; `list_monitoring_profiles` "exposes no bearer token and
  makes no network request."
- MCP tool `annotations` (`readOnlyHint`/`destructiveHint`) are set on all
  44 `helmi-local` tools, so a host's own confirmation UI (and a reviewer
  reading `tools/list`) can see which tools are pure local reads, which
  reach an external system, and which are irreversible (`delete_device`,
  and the `cancel_*` tools) without having to read every tool's prose
  description.

## 5. Scheduled/unattended monitoring ("Watch") is a separate component

Recurring Watch checks are not evaluated by Cloud reaching into a private
network, and they do not depend on a chat session being open. They run via
`helmi-agent` (`runtime/cmd/helmi-agent`) — a distinct binary from
`helmi-local`, installed as a **systemd service on a Linux host the
operator controls** via Cloud's own `install.sh` (which hard-gates on
`uname -s = Linux`). `helmi-agent` polls devices/Prometheus on its own
ticker, evaluates breach/recovery locally, and reports observations to
Cloud over an outbound connection only. This is entirely independent of,
and not bundled with, any of the three chat-client plugin packages
documented here.

## 6. What is confirmed today, and what is not

**Confirmed by direct testing** (see `helmi-ops-claude/README.md` for full
detail and dates): a real Claude Code CLI install resolves
`${CLAUDE_PLUGIN_ROOT}` correctly, `helmi-local` tools return real local
data with no device contacted where documented as read-only, and
`helmi-cloud`'s OAuth flow (authorization, a live tool call, and refresh
across a full restart) works end-to-end.

**Not yet independently confirmed for every harness:**
- Whether `helmi-local` could be loaded under a chat client's own
  cloud/remote/sandboxed execution mode (as opposed to running on the
  operator's own machine) has been explicitly investigated and excluded
  only for Cursor Cloud Agents (`docs/plugin-packaging.md`'s "Cursor Cloud
  Agent Exclusion" section — itself flagged there as "believed, not
  confirmed" pending a real Cloud subagent test). This is not a
  hypothetical concern for Claude Code either: Claude Code's own
  September 2026 changelog documents "cloud sessions and remote control
  functionality," and a Claude Code session can concretely run inside
  Anthropic's own cloud infrastructure rather than on the operator's
  machine. If a plugin install happens inside such a cloud session,
  `helmi-local` would be spawned there instead of on the operator's own
  network — at minimum non-functional (no route to the operator's real
  devices), and worth excluding the same way Cursor's Cloud Agents are,
  once a way to test it exists. This has not yet been investigated for
  Claude Code (or for Codex's own equivalent mode, if any exists) the way
  it has for Cursor. Until confirmed, treat this as an open, concrete risk
  for those two clients, not a guarantee it can't happen.
- `helmi-cloud`'s OAuth implementation has been exercised end-to-end
  against Claude Code specifically, not against every possible MCP client
  OAuth implementation in the abstract.
