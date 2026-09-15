# Open-ended device diagnosis

Read this reference for configuration review, an operational symptom,
multi-device diagnosis, neighbor expansion, or repeated sampling. Exact
device/probe collection uses the main Skill's short path.

## Establish context

Resolve named targets with `get_device_profile`; call it concurrently for
independent exact IDs when the client supports parallel tools. Use
`list_devices` first only when a display name or host must be mapped to an ID.
Ask one concise question only when target or scope is materially ambiguous.

A concrete symptom or feature already defines the scope. For a broad request
such as “is this device abnormal?”, check `list_local_facts` for the newest
`device.feature.snapshot` observed within 72 hours. Use only
`device.feature.*` Facts sharing that snapshot's `evidence_id`; they describe
slow-changing roles/features, not current health. If absent or stale, resolve
and collect only `device.feature_summary`, whose cache TTL is three days. If
the platform does not advertise it, ask the operator to narrow the scope.

Historical Evidence and Prometheus are planning inputs only when the question
depends on them. Current-state probes are still required to establish current
health.

## Form the first-stage plan

If exact probe IDs came from the operator or trusted tool output, plan directly
from them. Otherwise, after local context is known, make one authorized
`search_network_knowledge` call for the first stage. Use the operator's original
question as the query basis, with known `platform` and `os_version`. For mixed
platforms, make one search per distinct platform context concurrently—not one
per device—and combine the results into one plan. Append fresh feature Facts
under a clear local-context label only when useful. Supply `modules` only when
their exact catalog names are known; platform and version remain hard filters
before vector retrieval.

Knowledge is bounded prose containing useful order, stopping conditions,
follow-ups, and semantic IDs—not an executable playbook. Synthesize the
smallest stage that tests the current hypothesis. If matches contain no usable
probe IDs, call `list_probe_capabilities` once and finish the plan from its
descriptions.

Show the operator a prose plan before operational collection: its goal,
selected checks, and the condition for stopping or proposing another stage.
Then proceed within the requested read-only scope. A configuration audit may
include running configuration plus the operational checks needed to validate
it; the request determines that scope.

Search knowledge again only when new Evidence materially changes the question.

## Collect the stage

For 1–6 probes on one device, use one `resolve_probe_batch` followed by one
`collect_probe_batch`. When Cloud's `resolve_probe_batch` schema advertises a
`delivery` argument and Local's `collect_probe_batch` schema advertises a
`handoff_token` argument, call `resolve_probe_batch` with
`delivery: "handoff"` and pass its short `handoff_token` straight to
`collect_probe_batch`'s own `handoff_token` argument, unread and unmodified —
do not decode it, and do not fall back to reconstructing bundles by hand.
Otherwise use the default inline form and pass each returned probe object to
`collect_probe_batch` unchanged. A batch stops on its first failure; later
entries are unexecuted. Report that distinction and decide from the evidence
whether a second focused stage is needed. Do not automatically retry a
stopped batch — on a `handoff unavailable` failure, resolve the same stage
again with a fresh `resolve_probe_batch` call and collect once more, at most
once per stage; that is the only sanctioned automatic recovery. If the retry
also fails, stop and report it — never loop resolve/collect.

Empty or whitespace-only successful output is inconclusive unless that probe's
documented result gives empty output a specific meaning. Report it as empty
Evidence, without inferring health or configuration state.

Devices named by the operator are already in scope. Adding another device
requires approval that names it and explains why. For several devices, reuse a
bundle only when platform, probe ID, parameters, and current diagnostic stage
are identical; issue independent Local collection calls concurrently and let
Local enforce its SSH limit.

## Configuration history

For an explicit baseline request, call `capture_baseline` on successful
configuration Evidence. Use `diff_config_snapshots` only with two identified
snapshot IDs; a newly captured snapshot is not a prior known-good baseline.

## Follow a discovered neighbor

Neighbor-discovery Evidence may identify another device worth checking:

1. Match it against `list_devices`; never contact an unregistered address.
2. For a match, ask only for approval to add that device to this investigation,
   citing the Evidence. Local handles any later SSH elicitation separately.
3. Without a match, offer to open Device Manager. After the operator adds it,
   call `list_devices` again before using it.

## Compare changing readings

For counters, loss, flaps, or intermittent reachability, take a small number of
operator-visible readings with `force_refresh: true`, spaced far enough apart
to show a meaningful trend. Compare each reading's summary, digest, and Facts,
and cite its Evidence. Recurring observation belongs in a monitoring workflow.

For a nonzero exit or permission error, report the exact failure and affected
probe. A command explicitly reporting an unconfigured service or unsupported
syntax is device-side Evidence, distinct from an SSH transport failure.
Do not infer STP root or primary-node role from asymmetric synchronization
counters alone; report the counts as observations unless a role-specific probe
establishes that conclusion.
