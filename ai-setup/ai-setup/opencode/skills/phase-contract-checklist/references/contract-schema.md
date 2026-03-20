# Phase Contract Schema

Use a repository-root `phase-contracts.json` file with this shape:

```json
{
  "phases": [
    {
      "id": "08",
      "label": "atlassian-login",
      "script": "scripts/phases/08-atlassian-login.zsh",
      "inputs": [
        "ATLAS_EMAIL",
        "keychain:atlassian-session"
      ],
      "outputs": [
        "keychain:atlassian-session"
      ],
      "side_effects": [
        "writes_keychain",
        "network_auth"
      ],
      "must_run_after": [
        "07"
      ],
      "behavior_markers": [
        "security find-generic-password",
        "opencode-atlassian-login"
      ]
    }
  ]
}
```

## Field Rules

- `id`: required, two-digit string.
- `label`: required, lowercase kebab-case.
- `script`: required, repository-relative path to phase script.
- `inputs`: required non-empty string list.
- `outputs`: required non-empty string list.
- `side_effects`: required non-empty string list.
- `must_run_after`: required list of phase ids (empty list is allowed for first phase).
- `behavior_markers`: optional list of tokens expected in script content.

## Script Annotation Contract

Each phase file must declare:

```bash
# PHASE_ID: 08
# PHASE_LABEL: atlassian-login
```

The verifier compares these annotations with `id` and `label` to detect drift.
