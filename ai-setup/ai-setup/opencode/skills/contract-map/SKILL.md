---
name: contract-map
description: Enforce producer/consumer contract-map alignment and schema validation for every config-affecting PR. Use when reviewing or implementing changes to config files, schema files, message envelopes, integration boundaries, or contract manifests.
input: PR with config-affecting changes and a contract-map manifest (.contract-map/contract-map.json)
output: Pass/fail gate result with actionable diffs for missing keys, schema errors, and property-shape mismatches
category: code-quality
---

# Contract Map

Enforce a blocking contract gate before merge for any config-affecting pull request.

## Runbook

1. Collect PR changed files.
2. Classify whether the PR is config-affecting.
3. Run the contract-map gate script.
4. Fail the review if producer and consumer key sets drift or schemas fail validation.
5. Return actionable diffs: missing keys, schema path errors, and property-shape mismatches.

## Gate Command

```bash
python3 opencode/skills/contract-map/scripts/contract_map_gate.py \
  --repo-root . \
  --manifest .contract-map/contract-map.json \
  --base-ref origin/main
```

Use explicit changed files when running outside a PR branch:

```bash
python3 opencode/skills/contract-map/scripts/contract_map_gate.py \
  --repo-root . \
  --manifest .contract-map/contract-map.json \
  --changed-file opencode/opencode.jsonc \
  --changed-file docs/specs/bridge-message-envelope-v1.schema.json
```

## Expected Behavior

- Exit `0`: no config-affecting changes or all contract checks passed.
- Exit `1`: config-affecting changes found and at least one blocking contract/schema check failed.

## References

- [Manifest specification](references/contract-map-spec.md)
- [Example manifest](references/contract-map.example.json)
