# Visualization and Evidence

Read this reference when the user requests a topology, the device-management
page, the Evidence viewer, or local-history cleanup.

`open_device_manager` and `open_evidence` are safe to call without asking
first — each only starts a local loopback page and opens the browser to it;
neither ever contacts a device, Prometheus, or Helmi Cloud. Creating or
linking a stored visualization does not open a browser either.

Helmi is not a full monitoring product and has no standing Dashboard: there
is no tool that auto-generates a per-device overview. Produce a chart or
topology only when the current question actually calls for one, on demand.

## Assistant-drawn topology

When a topology answers the current question better than text, call
`create_topology_visualization` after reading the relevant local Evidence or
Facts. Submit exact observed or explicitly user-provided nodes and edges, and
attach every relevant Evidence ID that exists. Never infer a link or submit
HTML, SVG, scripts, or unbounded graph data.

The tool stores the bounded drawing locally and returns a `visualization_url`;
include it as a Markdown link. On a host with MCP Apps (SEP-1865) support,
the same drawing also renders inline in the conversation — the link still
works identically everywhere else. Treat the drawing as an interpretation of
Evidence, not independently reverified topology.

## Evidence viewer and cleanup

Call `open_evidence` when the operator asks to open a stored record, or
whenever pointing them at it is useful — no confirmation needed first. Raw
SSH or Prometheus output stays in the viewer and must not be copied into
model context.

There is no MCP deletion tool for local history. If the user asks to clear
Evidence or saved visualizations, explain that the Evidence tab's local UI
performs the permanent cleanup and ask before opening the local page. Do not
claim anything was deleted merely because the page opened; the operator still
chooses the age window and confirms the action in the UI.
