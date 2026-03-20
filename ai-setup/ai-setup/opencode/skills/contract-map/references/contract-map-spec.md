# Contract-Map Manifest Spec

Use this manifest to define producer and consumer contracts that must stay aligned.

## Path

Store the repository manifest at:

```text
.contract-map/contract-map.json
```

## Schema

```json
{
  "version": "1",
  "contracts": [
    {
      "name": "bridge-message-envelope-v1",
      "watch": [
        "docs/specs/bridge-message-envelope-v1*.json",
        "docs/specs/bridge-message-envelope-v1.md"
      ],
      "allow_consumer_superset": false,
      "producers": [
        {
          "name": "producer-name",
          "schema": "path/to/schema.json",
          "keys": ["type", "version", "payload"]
        }
      ],
      "consumers": [
        {
          "name": "consumer-name",
          "schema": "path/to/schema.json",
          "keys": ["type", "version", "payload"]
        }
      ]
    }
  ]
}
```

## Field Rules

- `contracts[].watch` supports glob patterns and optional regex patterns with `re:` prefix.
- `allow_consumer_superset=false` enforces exact producer/consumer key-set equality.
- `allow_consumer_superset=true` allows consumer keys to be a superset of producer keys.
- Every key listed in `keys` must exist in the actor's `schema.properties`.
- Property shapes are compared across producer and consumer for shared keys, ignoring docs-only fields like `description` and `examples`.

## Run Gate

```bash
python3 opencode/skills/contract-map/scripts/contract_map_gate.py \
  --repo-root . \
  --manifest .contract-map/contract-map.json \
  --base-ref origin/main
```
