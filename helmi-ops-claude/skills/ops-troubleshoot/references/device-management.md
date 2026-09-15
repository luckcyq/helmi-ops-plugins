# Device management

Read this reference only for first use or when adding, updating, disabling, or
deleting a local device descriptor.

## Add or first configure

Adding a device requires a friendly name, management host or existing SSH
alias, and an exact Helmi catalog platform ID chosen by the operator. Do not
infer or translate a vendor name into a platform ID. If it is missing, ask the
operator to provide it or select it in Device Manager. Never ask for a password
or private key; credentials stay on the user's machine.

If the operator already supplied the exact descriptor and explicitly asked to
save it, call `save_device` without a duplicate confirmation. Otherwise ask
only for missing or ambiguous fields. Saving inventory does not authorize
collection; do not contact the device until requested.

If the user prefers the local UI, ask before `open_device_manager` because it
starts a loopback-only page and opens a browser. Opening it does not contact a
device or change local state; edits and credential saves in the page are
separate user actions.

For a device's first run, offer this sequence:

1. Add the device.
2. Discover that platform's capabilities with `list_probe_capabilities`.
3. From those advertised IDs, choose the narrow probe that verifies system
   identity/access and the narrow probe that summarizes interface state.

The two checks form one ordered diagnostic stage: resolve them with
`resolve_probe_batch` and collect them with `collect_probe_batch`. Put the
identity/access check first, so Local stops before the interface check if basic
access fails. One approval and aggregate result avoid an extra model round; use
separate calls only when the operator asks to inspect the first result first.

## Inspect or update

- Use `list_devices` to show local inventory without connecting.
- Reusing an ID with `save_device` updates that descriptor. Resolve any
  ambiguous target or changed field; an explicit, exact update request needs no
  duplicate confirmation.
- Use `enabled: false` when the device should remain in local history but no
  longer be active.
- Before `delete_device`, show the exact descriptor and obtain explicit
  confirmation. Deletion affects only local inventory and may be refused when
  configuration snapshots preserve Evidence history; disable it instead.

Prometheus bindings and credentials remain local. When monitoring is not
configured, offer the Prometheus tab in Device Manager rather than asking the
user to paste credentials into chat.
