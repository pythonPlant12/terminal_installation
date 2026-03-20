#!/usr/bin/env python3

from __future__ import annotations

import argparse
import re
import sys
from collections.abc import Mapping
from dataclasses import dataclass
from pathlib import Path


ROOT_DIR = Path(__file__).resolve().parent.parent
DEFAULT_SOLUTIONS_PATH = ROOT_DIR / "knowledge" / "ai" / "solutions"

REQUIRED_FIELDS = [
    "schema_version",
    "module",
    "date",
    "problem_type",
    "component",
    "symptoms",
    "root_cause",
    "resolution_type",
    "severity",
    "confidence",
    "summary",
    "applies_when",
    "verification_commands",
    "evidence_paths",
    "tags",
]

CANONICAL_ORDER = [
    "schema_version",
    "module",
    "date",
    "problem_type",
    "component",
    "symptoms",
    "root_cause",
    "resolution_type",
    "severity",
    "confidence",
    "summary",
    "applies_when",
    "verification_commands",
    "evidence_paths",
    "tags",
    "avoid_when",
    "status",
    "superseded_by",
    "related_docs",
]

LIST_FIELDS = {
    "symptoms",
    "applies_when",
    "verification_commands",
    "evidence_paths",
    "tags",
    "avoid_when",
    "related_docs",
}

ENUMS = {
    "problem_type": {
        "build_error",
        "workflow_issue",
        "developer_experience",
        "documentation_gap",
        "runtime_error",
        "integration_issue",
        "test_failure",
        "security_issue",
        "performance_issue",
        "best_practice",
    },
    "component": {
        "bootstrap",
        "phase-script",
        "helper-script",
        "cli-tool",
        "opencode-config",
        "opencode-hook",
        "opencode-agent",
        "opencode-skill",
        "plugin-system",
        "ci-workflow",
        "auth-flow",
        "migration-recovery",
        "knowledge-system",
        "development-workflow",
        "documentation",
        "tooling",
        "shell-script",
        "unknown",
    },
    "root_cause": {
        "config_error",
        "missing_workflow_step",
        "dependency_ordering",
        "stale_documentation",
        "missing_tooling",
        "incomplete_setup",
        "environment_mismatch",
        "logic_error",
        "integration_contract_drift",
        "permission_gap",
        "test_gap",
        "observability_gap",
        "scope_creep",
        "version_drift",
        "unclear_ownership",
        "unknown_root_cause",
    },
    "resolution_type": {
        "code_fix",
        "config_change",
        "workflow_improvement",
        "documentation_update",
        "tooling_addition",
        "dependency_update",
        "environment_setup",
        "guardrail_addition",
        "test_fix",
        "rollback",
    },
    "severity": {"critical", "high", "medium", "low"},
    "confidence": {"high", "medium", "low"},
    "status": {"active", "superseded", "archived"},
}

PROBLEM_TYPE_TO_DIR = {
    "build_error": "build-errors",
    "workflow_issue": "workflow-issues",
    "developer_experience": "developer-experience",
    "documentation_gap": "documentation-gaps",
    "runtime_error": "runtime-errors",
    "integration_issue": "integration-issues",
    "test_failure": "test-failures",
    "security_issue": "security-issues",
    "performance_issue": "performance-issues",
    "best_practice": "best-practices",
}

DIR_TO_PROBLEM_TYPE = {value: key for key, value in PROBLEM_TYPE_TO_DIR.items()}

LEGACY_VALUE_MAP = {
    "problem_type": {
        "build-errors": "build_error",
        "workflow_documentation": "documentation_gap",
    },
    "component": {
        "development_workflow": "development-workflow",
        "bootstrap-system": "bootstrap",
        "bootstrap-installation": "bootstrap",
        "bootstrap-install": "bootstrap",
        "bootstrap-pipeline": "bootstrap",
    },
    "root_cause": {
        "fragmented_flow_visibility": "stale_documentation",
    },
    "resolution_type": {
        "documentation": "documentation_update",
    },
    "status": {
        "resolved": "active",
    },
}

PATH_HINT_PREFIXES = (
    "scripts/",
    "bin/",
    "opencode/",
    "knowledge/",
    ".planning/",
    ".sisyphus/",
)


@dataclass
class LintMessage:
    level: str
    path: Path
    message: str


def discover_markdown_files(path: Path) -> list[Path]:
    if path.is_file():
        return [path]
    return sorted(path.rglob("*.md"))


def split_frontmatter(text: str) -> tuple[dict[str, object], str] | None:
    if not text.startswith("---\n"):
        return None
    end = text.find("\n---\n", 4)
    if end == -1:
        return None
    fm_text = text[4:end]
    body = text[end + 5 :]
    return parse_simple_yaml(fm_text), body


def parse_simple_yaml(text: str) -> dict[str, object]:
    data: dict[str, object] = {}
    current_key: str | None = None
    for raw in text.splitlines():
        line = raw.rstrip()
        if not line.strip():
            continue
        if line.startswith("  - ") and current_key:
            items = data.get(current_key, [])
            if not isinstance(items, list):
                items = []
            items.append(unquote(line[4:].strip()))
            data[current_key] = items
            continue
        if ":" not in line:
            current_key = None
            continue
        key, value = line.split(":", 1)
        key = key.strip()
        value = value.strip()
        if not key:
            current_key = None
            continue
        if value == "":
            data[key] = []
            current_key = key
            continue
        if value.startswith("[") and value.endswith("]"):
            data[key] = parse_inline_list(value)
            current_key = None
            continue
        if value.isdigit():
            data[key] = int(value)
            current_key = None
            continue
        data[key] = unquote(value)
        current_key = None
    return data


def parse_inline_list(value: str) -> list[str]:
    inner = value[1:-1].strip()
    if not inner:
        return []
    return [unquote(part.strip()) for part in inner.split(",") if part.strip()]


def unquote(value: str) -> str:
    if len(value) >= 2 and value[0] == value[-1] and value[0] in {'"', "'"}:
        value = value[1:-1]
    value = value.replace('\\"', '"')
    return value


def quote_if_needed(value: str) -> str:
    if value == "":
        return '""'
    if re.search(r"[:\[\],#]|^\s|\s$", value):
        escaped = value.replace('"', '\\"')
        return f'"{escaped}"'
    return value


def render_frontmatter(data: Mapping[str, object]) -> str:
    lines = ["---"]
    for key in CANONICAL_ORDER:
        if key not in data:
            continue
        value = data[key]
        if key in LIST_FIELDS:
            items = ensure_list(value)
            if not items:
                continue
            lines.append(f"{key}:")
            for item in items:
                lines.append(f"  - {quote_if_needed(str(item))}")
            continue
        if value is None:
            continue
        if isinstance(value, int):
            lines.append(f"{key}: {value}")
            continue
        lines.append(f"{key}: {quote_if_needed(str(value))}")
    lines.append("---")
    return "\n".join(lines)


def ensure_list(value: object) -> list[str]:
    if value is None:
        return []
    if isinstance(value, list):
        return [str(v).strip() for v in value if str(v).strip()]
    if isinstance(value, str):
        text = value.strip()
        if not text:
            return []
        return [text]
    return [str(value)]


def section_content(body: str, heading: str) -> str:
    pattern = re.compile(
        rf"^## {re.escape(heading)}\s*$\n(?P<content>.*?)(?=^## |\Z)", re.M | re.S
    )
    match = pattern.search(body)
    if not match:
        return ""
    return match.group("content").strip()


def infer_summary(body: str, title: str) -> str:
    problem = section_content(body, "Problem")
    if not problem:
        problem = section_content(body, "Problem Summary")
    source = problem if problem else title
    source = re.sub(r"```.*?```", " ", source, flags=re.S)
    text = re.sub(r"`([^`]+)`", r"\1", source)
    text = re.sub(r"\s+", " ", text).strip()
    sentence_match = re.match(r"^(.*?[.!?])\s", text)
    if sentence_match and len(sentence_match.group(1)) >= 40:
        text = sentence_match.group(1)
    if not text:
        return "Apply the documented fix and verify with the listed commands."
    if len(text) > 180:
        text = text[:177].rstrip() + "..."
    return text


def infer_symptoms(body: str) -> list[str]:
    content = section_content(body, "Symptoms")
    if not content:
        return []
    items = []
    for line in content.splitlines():
        stripped = line.strip()
        if stripped.startswith("- "):
            items.append(stripped[2:].strip())
    return items


def extract_title(body: str, path: Path) -> str:
    for line in body.splitlines():
        if line.startswith("# "):
            return line[2:].strip()
    return path.stem.replace("-", " ").strip().title()


def extract_commands(body: str) -> list[str]:
    commands: list[str] = []
    for match in re.finditer(r"```bash\n(.*?)```", body, re.S):
        block = match.group(1)
        for line in block.splitlines():
            normalized = normalize_command_line(line)
            if normalized:
                commands.append(normalized)
    return unique_trimmed(commands)[:5]


def normalize_command_line(line: str) -> str:
    allowed_starts = {
        "./bootstrap.zsh",
        "ai-setup-doctor",
        "zsh",
        "bash",
        "node",
        "python3",
        "python",
        "git",
        "npm",
        "bun",
        "bunx",
        "brew",
        "mise",
        "opencode",
        "jq",
        "grep",
        "cat",
        "rsync",
        "security",
    }
    skip_prefixes = (
        "→",
        "✅",
        "❌",
        "FAIL:",
        "CAUSE:",
        "NEXT:",
        "Using ",
        "Installing ",
    )
    stripped = line.strip()
    if not stripped or stripped.startswith("#"):
        return ""
    if stripped.startswith(skip_prefixes):
        return ""
    if stripped.startswith("$ "):
        stripped = stripped[2:].strip()
    if " #" in stripped:
        stripped = stripped.split(" #", 1)[0].rstrip()
    token = stripped.split()[0]
    if token.endswith(".sh"):
        return stripped
    if token in allowed_starts:
        return stripped
    if token.startswith("CI=") and " " in stripped:
        return stripped
    return ""


def extract_paths(body: str) -> list[str]:
    paths: list[str] = []
    for match in re.finditer(r"`([^`]+)`", body):
        token = match.group(1).strip()
        if looks_like_repo_path(token):
            paths.append(token)
    return unique_trimmed(paths)[:10]


def extract_related_docs(body: str) -> list[str]:
    links: list[str] = []
    for match in re.finditer(r"\[[^\]]+\]\(([^)]+)\)", body):
        href = match.group(1).strip()
        if href.startswith("http://") or href.startswith("https://"):
            continue
        links.append(href)
    return unique_trimmed(links)[:10]


def unique_trimmed(values: list[str]) -> list[str]:
    seen: set[str] = set()
    output: list[str] = []
    for value in values:
        item = value.strip()
        if not item or item in seen:
            continue
        seen.add(item)
        output.append(item)
    return output


def looks_like_repo_path(value: str) -> bool:
    if value.startswith("-"):
        return False
    if "/--" in value:
        return False
    if value.startswith(PATH_HINT_PREFIXES):
        return True
    if value in {"Brewfile", "mise.toml", "bootstrap.zsh"}:
        return True
    return bool(re.match(r"^[A-Za-z0-9._-]+/[A-Za-z0-9._/-]+$", value))


def normalize_enum(field: str, value: str | None) -> str | None:
    if value is None:
        return None
    normalized = LEGACY_VALUE_MAP.get(field, {}).get(value, value)
    if field in ENUMS and normalized not in ENUMS[field]:
        return None
    return normalized


def normalize_problem_type(value: str | None, path: Path) -> str:
    if value:
        mapped = LEGACY_VALUE_MAP.get("problem_type", {}).get(value, value)
        if mapped in ENUMS["problem_type"]:
            return mapped
    parent = path.parent.name
    if parent in DIR_TO_PROBLEM_TYPE:
        return DIR_TO_PROBLEM_TYPE[parent]
    return "workflow_issue"


def normalize_component(value: str | None) -> str:
    mapped = normalize_enum("component", value)
    if mapped:
        return mapped
    return "unknown"


def normalize_root_cause(value: str | None) -> str:
    mapped = normalize_enum("root_cause", value)
    if mapped:
        return mapped
    return "unknown_root_cause"


def normalize_resolution_type(value: str | None) -> str:
    mapped = normalize_enum("resolution_type", value)
    if mapped:
        return mapped
    return "workflow_improvement"


def normalize_severity(value: str | None) -> str:
    if value in ENUMS["severity"]:
        return value
    return "medium"


def normalize_confidence(
    value: str | None, commands: list[str], paths: list[str]
) -> str:
    if value in ENUMS["confidence"]:
        return value
    if commands and paths:
        return "high"
    return "medium"


def normalize_status(value: str | None) -> str:
    mapped = normalize_enum("status", value)
    if mapped:
        return mapped
    return "active"


def normalize_module(value: object, path: Path) -> str:
    text = str(value).strip() if value is not None else ""
    if text:
        return text
    if path.parent.name == "build-errors":
        return "Bootstrap Pipeline"
    if path.parent.name == "developer-experience":
        return "Developer Experience"
    return "Development Workflow"


def normalize_date(frontmatter: dict[str, object]) -> str:
    date = str(frontmatter.get("date", "")).strip()
    if re.match(r"^\d{4}-\d{2}-\d{2}$", date):
        return date
    legacy = str(frontmatter.get("date_documented", "")).strip()
    if re.match(r"^\d{4}-\d{2}-\d{2}$", legacy):
        return legacy
    return "1970-01-01"


def normalize_tags(value: object, fallback: list[str]) -> list[str]:
    tags = ensure_list(value)
    tags = [sanitize_tag(tag) for tag in tags]
    tags = [tag for tag in tags if tag]
    if len(tags) < 2:
        for item in fallback:
            sanitized = sanitize_tag(item)
            if sanitized and sanitized not in tags:
                tags.append(sanitized)
            if len(tags) >= 2:
                break
    return unique_trimmed(tags)[:10]


def sanitize_tag(tag: str) -> str:
    value = tag.strip().lower().replace(" ", "-")
    value = re.sub(r"[^a-z0-9_-]", "", value)
    value = value.strip("-")
    return value


def find_markdown_h1_index(lines: list[str]) -> int | None:
    in_code = False
    for index, line in enumerate(lines):
        if line.startswith("```"):
            in_code = not in_code
            continue
        if in_code:
            continue
        if line.startswith("# "):
            return index
    return None


def find_markdown_heading_index(lines: list[str], heading: str) -> int | None:
    in_code = False
    target = heading.strip()
    for index, line in enumerate(lines):
        if line.startswith("```"):
            in_code = not in_code
            continue
        if in_code:
            continue
        if line.strip() == target:
            return index
    return None


def find_next_h2_index(lines: list[str], start: int) -> int:
    in_code = False
    for index in range(start, len(lines)):
        line = lines[index]
        if line.startswith("```"):
            in_code = not in_code
            continue
        if in_code:
            continue
        if line.startswith("## "):
            return index
    return len(lines)


def ensure_agent_card(body: str, frontmatter: Mapping[str, object]) -> str:
    existing_card = re.search(r"^## Agent Card\s*$", body, re.M)
    if existing_card:
        lines = body.splitlines()
        heading_index = find_markdown_h1_index(lines)
        if heading_index is None:
            module_name = (
                str(frontmatter.get("module", "Knowledge Note")).strip()
                or "Knowledge Note"
            )
            lines = [f"# Troubleshooting: {module_name}", ""] + lines
            heading_index = 0

        card_start = find_markdown_heading_index(lines, "## Agent Card")
        if card_start is None:
            body = "\n".join(lines)
        else:
            card_end = find_next_h2_index(lines, card_start + 1)
            desired_start = heading_index + 2
            if card_start <= desired_start + 2:
                return "\n".join(lines).strip() + "\n"

            block = lines[card_start:card_end]
            remaining = lines[:card_start] + lines[card_end:]
            while (
                desired_start < len(remaining)
                and remaining[desired_start].strip() != ""
            ):
                desired_start += 1
            insert_lines = [""] + block + [""]
            rewritten = (
                remaining[:desired_start] + insert_lines + remaining[desired_start:]
            )
            return "\n".join(rewritten).strip() + "\n"
    commands = ensure_list(frontmatter.get("verification_commands"))
    command_text = (
        "; ".join(f"`{cmd}`" for cmd in commands[:2])
        if commands
        else "`ai-setup-doctor --json`"
    )
    applies = ensure_list(frontmatter.get("applies_when"))
    avoid = ensure_list(frontmatter.get("avoid_when"))
    summary = str(frontmatter.get("summary", "Apply the documented fix.")).strip()
    card_lines = [
        "## Agent Card",
        "",
        f"- Use when: {applies[0] if applies else 'Symptoms match this note.'}",
        f"- Core fix: {summary}",
        f"- Avoid when: {avoid[0] if avoid else 'The failure pattern does not match.'}",
        f"- Verify with: {command_text}",
        "",
    ]
    lines = body.splitlines()
    heading_index = find_markdown_h1_index(lines)
    if heading_index is None:
        module_name = (
            str(frontmatter.get("module", "Knowledge Note")).strip() or "Knowledge Note"
        )
        lines = [f"# Troubleshooting: {module_name}", ""] + lines
        heading_index = 0
    insert_at = heading_index + 1
    while insert_at < len(lines) and lines[insert_at].strip() == "":
        insert_at += 1
    return (
        "\n".join(lines[:insert_at] + [""] + card_lines + lines[insert_at:]).strip()
        + "\n"
    )


def ensure_verification_section(body: str, commands: list[str]) -> str:
    if re.search(r"^## Verification\s*$", body, re.M):
        return body
    if not commands:
        return body
    section = ["", "## Verification", ""]
    for command in commands[:3]:
        section.append(f"- `{command}` -> confirm expected behavior")
    return body.rstrip() + "\n" + "\n".join(section) + "\n"


def migrate_document(path: Path, write: bool) -> tuple[bool, list[LintMessage]]:
    text = path.read_text(encoding="utf-8")
    split = split_frontmatter(text)
    if split is None:
        msg = LintMessage("error", path, "missing YAML frontmatter")
        return False, [msg]

    frontmatter, body = split
    title = extract_title(body, path)
    symptoms = ensure_list(frontmatter.get("symptoms"))
    if not symptoms:
        symptoms = infer_symptoms(body)

    commands = [
        normalized
        for normalized in (
            normalize_command_line(cmd)
            for cmd in ensure_list(frontmatter.get("verification_commands"))
        )
        if normalized
    ]
    if not commands:
        commands = extract_commands(body)
    if not commands:
        commands = ["ai-setup-doctor --json"]

    paths = [
        candidate
        for candidate in ensure_list(frontmatter.get("evidence_paths"))
        if looks_like_repo_path(candidate)
    ]
    if not paths:
        paths = extract_paths(body)
    if not paths and frontmatter.get("affected_file"):
        paths = [str(frontmatter["affected_file"])]
    if not paths:
        paths = [str(path.relative_to(ROOT_DIR))]

    related_docs = ensure_list(frontmatter.get("related_docs"))
    if not related_docs:
        related_docs = extract_related_docs(body)

    problem_type = normalize_problem_type(
        str(frontmatter.get("problem_type", "")).strip() or None, path
    )
    component = normalize_component(
        str(frontmatter.get("component", "")).strip() or None
    )
    inferred_summary = infer_summary(body, title)
    existing_summary = str(frontmatter.get("summary", "")).strip()
    if (
        existing_summary
        and 40 <= len(existing_summary) <= 220
        and not existing_summary.endswith("...")
    ):
        summary_value = existing_summary
    else:
        summary_value = inferred_summary

    normalized = {
        "schema_version": 2,
        "module": normalize_module(frontmatter.get("module"), path),
        "date": normalize_date(frontmatter),
        "problem_type": problem_type,
        "component": component,
        "symptoms": symptoms[:5]
        if symptoms
        else ["Issue details are documented in this note."],
        "root_cause": normalize_root_cause(
            str(frontmatter.get("root_cause", "")).strip() or None
        ),
        "resolution_type": normalize_resolution_type(
            str(frontmatter.get("resolution_type", "")).strip() or None
        ),
        "severity": normalize_severity(
            str(frontmatter.get("severity", "")).strip() or None
        ),
        "confidence": normalize_confidence(
            str(frontmatter.get("confidence", "")).strip() or None,
            commands,
            paths,
        ),
        "summary": summary_value,
        "applies_when": ensure_list(frontmatter.get("applies_when"))[:5]
        or symptoms[:3],
        "verification_commands": commands[:5],
        "evidence_paths": paths[:10],
        "tags": normalize_tags(
            frontmatter.get("tags"),
            [
                problem_type,
                component,
                normalize_module(frontmatter.get("module"), path),
            ],
        ),
        "avoid_when": ensure_list(frontmatter.get("avoid_when"))[:5],
        "status": normalize_status(str(frontmatter.get("status", "")).strip() or None),
        "related_docs": related_docs[:10],
    }

    if normalized["root_cause"] == "unknown_root_cause":
        tags_lower = {tag.lower() for tag in ensure_list(normalized["tags"])}
        if "dependency-ordering" in tags_lower:
            normalized["root_cause"] = "dependency_ordering"
        elif "config" in tags_lower or "config-sync" in tags_lower:
            normalized["root_cause"] = "config_error"

    if normalized["status"] == "superseded" and not frontmatter.get("superseded_by"):
        normalized["status"] = "active"

    if frontmatter.get("superseded_by"):
        normalized["superseded_by"] = str(frontmatter["superseded_by"]).strip()

    body = ensure_agent_card(body, normalized)
    body = ensure_verification_section(
        body, ensure_list(normalized["verification_commands"])
    )

    rendered = render_frontmatter(normalized) + "\n\n" + body.strip() + "\n"
    changed = rendered != text
    if changed and write:
        path.write_text(rendered, encoding="utf-8")
    return changed, []


def lint_document(path: Path, strict: bool) -> list[LintMessage]:
    messages: list[LintMessage] = []
    text = path.read_text(encoding="utf-8")
    split = split_frontmatter(text)
    if split is None:
        return [LintMessage("error", path, "missing YAML frontmatter")]

    frontmatter, body = split

    for field in REQUIRED_FIELDS:
        if field not in frontmatter:
            messages.append(
                LintMessage("error", path, f"missing required field: {field}")
            )

    schema_version = frontmatter.get("schema_version")
    if schema_version != 2:
        messages.append(LintMessage("error", path, "schema_version must be 2"))

    date = str(frontmatter.get("date", ""))
    if date and not re.match(r"^\d{4}-\d{2}-\d{2}$", date):
        messages.append(LintMessage("error", path, "date must match YYYY-MM-DD"))

    for enum_field, allowed in ENUMS.items():
        value = frontmatter.get(enum_field)
        if value is None:
            continue
        if str(value) not in allowed:
            messages.append(
                LintMessage(
                    "error",
                    path,
                    f"invalid {enum_field}: {value} (allowed: {', '.join(sorted(allowed))})",
                )
            )

    for list_field in LIST_FIELDS:
        if list_field not in frontmatter:
            continue
        values = ensure_list(frontmatter.get(list_field))
        if (
            list_field
            in {
                "symptoms",
                "applies_when",
                "verification_commands",
                "evidence_paths",
                "tags",
            }
            and not values
        ):
            messages.append(
                LintMessage("error", path, f"{list_field} must not be empty")
            )

    problem_type = str(frontmatter.get("problem_type", ""))
    expected_dir = PROBLEM_TYPE_TO_DIR.get(problem_type)
    if expected_dir and path.parent.name != expected_dir:
        messages.append(
            LintMessage(
                "error",
                path,
                f"directory mismatch: problem_type={problem_type} expects {expected_dir}",
            )
        )

    if not re.search(r"^## Agent Card\s*$", body, re.M):
        messages.append(LintMessage("error", path, "missing ## Agent Card section"))

    evidence_paths = ensure_list(frontmatter.get("evidence_paths"))
    for evidence_path in evidence_paths:
        if (
            evidence_path.startswith("/")
            or evidence_path.startswith("http://")
            or evidence_path.startswith("https://")
        ):
            messages.append(
                LintMessage(
                    "error",
                    path,
                    f"evidence_paths must be repo-relative: {evidence_path}",
                )
            )

    related_docs = ensure_list(frontmatter.get("related_docs"))
    for rel in related_docs:
        candidates: list[Path] = []
        if rel.startswith("knowledge/"):
            candidates.append((ROOT_DIR / rel).resolve())
        else:
            candidates.append((path.parent / rel).resolve())
            candidates.append((DEFAULT_SOLUTIONS_PATH / rel).resolve())
        target_exists = any(candidate.exists() for candidate in candidates)
        if strict and not target_exists:
            messages.append(
                LintMessage("error", path, f"related_docs target not found: {rel}")
            )
        elif not target_exists:
            messages.append(
                LintMessage("warn", path, f"related_docs target not found: {rel}")
            )

    line_count = text.count("\n") + 1
    if line_count > 220:
        level = "warn"
        messages.append(
            LintMessage(
                level, path, f"doc too long ({line_count} lines; target <= 220)"
            )
        )

    return messages


def run_migrate(path: Path, write: bool) -> int:
    files = discover_markdown_files(path)
    changed = 0
    errors = 0
    for file_path in files:
        did_change, messages = migrate_document(file_path, write=write)
        for message in messages:
            print(format_message(message))
            if message.level == "error":
                errors += 1
        if did_change:
            changed += 1
            prefix = "updated" if write else "would-update"
            print(f"{prefix}: {file_path.relative_to(ROOT_DIR)}")
    print(
        f"migrate-summary: files={len(files)} changed={changed} errors={errors} write={str(write).lower()}"
    )
    return 1 if errors else 0


def run_lint(path: Path, strict: bool) -> int:
    files = discover_markdown_files(path)
    error_count = 0
    warn_count = 0
    for file_path in files:
        messages = lint_document(file_path, strict=strict)
        for message in messages:
            print(format_message(message))
            if message.level == "error":
                error_count += 1
            elif message.level == "warn":
                warn_count += 1
        if not messages:
            print(f"ok: {file_path.relative_to(ROOT_DIR)}")
    print(
        "lint-summary: "
        f"files={len(files)} errors={error_count} warnings={warn_count} strict={str(strict).lower()}"
    )
    return 1 if error_count else 0


def format_message(message: LintMessage) -> str:
    return f"{message.level}: {message.path.relative_to(ROOT_DIR)}: {message.message}"


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        prog="knowledge-solutions-v2",
        description="Lint and migrate knowledge solution docs",
    )
    subparsers = parser.add_subparsers(dest="command", required=True)

    lint_parser = subparsers.add_parser("lint", help="Validate solution docs")
    lint_parser.add_argument(
        "--path", default=str(DEFAULT_SOLUTIONS_PATH), help="File or directory to lint"
    )
    lint_parser.add_argument(
        "--strict", action="store_true", help="Treat warnings as higher-severity checks"
    )

    migrate_parser = subparsers.add_parser(
        "migrate", help="Normalize docs to schema v2"
    )
    migrate_parser.add_argument(
        "--path",
        default=str(DEFAULT_SOLUTIONS_PATH),
        help="File or directory to migrate",
    )
    migrate_parser.add_argument(
        "--write", action="store_true", help="Write changes in place"
    )

    return parser.parse_args()


def main() -> int:
    args = parse_args()
    target = Path(args.path)
    if not target.is_absolute():
        target = (ROOT_DIR / target).resolve()
    if not target.exists():
        print(f"error: path not found: {target}", file=sys.stderr)
        return 2

    if args.command == "lint":
        return run_lint(target, strict=bool(args.strict))
    if args.command == "migrate":
        return run_migrate(target, write=bool(args.write))
    print("error: unsupported command", file=sys.stderr)
    return 2


if __name__ == "__main__":
    raise SystemExit(main())
