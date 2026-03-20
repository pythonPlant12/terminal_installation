# YAML Frontmatter Schema (v2)

Primary schema: `opencode/skills/do-compound/schema.yaml`

## Required fields

- `schema_version` (must be `2`)
- `module`
- `date` (`YYYY-MM-DD`)
- `problem_type`
- `component`
- `symptoms` (1-5)
- `root_cause`
- `resolution_type`
- `severity`
- `confidence`
- `summary`
- `applies_when` (1-5)
- `verification_commands` (1-5)
- `evidence_paths` (1-10)
- `tags` (2-10)

## Optional fields

- `avoid_when`
- `status` (`active|superseded|archived`)
- `superseded_by`
- `related_docs`

## Category mapping

- `build_error` -> `knowledge/ai/solutions/build-errors/`
- `workflow_issue` -> `knowledge/ai/solutions/workflow-issues/`
- `developer_experience` -> `knowledge/ai/solutions/developer-experience/`
- `documentation_gap` -> `knowledge/ai/solutions/documentation-gaps/`
- `runtime_error` -> `knowledge/ai/solutions/runtime-errors/`
- `integration_issue` -> `knowledge/ai/solutions/integration-issues/`
- `test_failure` -> `knowledge/ai/solutions/test-failures/`
- `security_issue` -> `knowledge/ai/solutions/security-issues/`
- `performance_issue` -> `knowledge/ai/solutions/performance-issues/`
- `best_practice` -> `knowledge/ai/solutions/best-practices/`

## Legacy normalization

- `problem_type: build-errors` -> `build_error`
- `problem_type: workflow_documentation` -> `documentation_gap`
- `component: development_workflow` -> `development-workflow`
- `component: bootstrap-system` -> `bootstrap`
- `component: bootstrap-installation` -> `bootstrap`
- `root_cause: fragmented_flow_visibility` -> `stale_documentation`
- `resolution_type: documentation` -> `documentation_update`

## Linting

Use:

```bash
python3 scripts/knowledge-solutions-v2.py lint --path knowledge/ai/solutions --strict
```

For migration:

```bash
python3 scripts/knowledge-solutions-v2.py migrate --path knowledge/ai/solutions --write
```
