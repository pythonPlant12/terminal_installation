#!/usr/bin/env python3
"""Validate repo todo files against the documented file-todos contract."""

from __future__ import annotations

import argparse
import ast
import re
import sys
from pathlib import Path
from typing import TypeAlias, cast


FILENAME_RE = re.compile(
    r"^(?P<issue_id>\d{3})-(?P<status>pending|ready|complete)-(?P<priority>p[123])-(?P<slug>[a-z0-9]+(?:-[a-z0-9]+)*)\.md$"
)
HEADING_RE = re.compile(r"^##\s+(.+?)\s*$", re.MULTILINE)
REQUIRED_FRONTMATTER = {"status", "priority", "issue_id", "tags", "dependencies"}
VALID_STATUSES = {"pending", "ready", "complete"}
VALID_PRIORITIES = {"p1", "p2", "p3"}
REQUIRED_SECTIONS = {
    "Problem Statement",
    "Findings",
    "Proposed Solutions",
    "Recommended Action",
    "Acceptance Criteria",
    "Work Log",
}

FrontmatterValue: TypeAlias = str | list[str]
Frontmatter: TypeAlias = dict[str, FrontmatterValue]


def fail(message: str) -> None:
    raise SystemExit(f"[FAIL] {message}")


def parse_frontmatter(path: Path, text: str) -> Frontmatter:
    lines = text.splitlines()
    if len(lines) < 3 or lines[0].strip() != "---":
        fail(f"{path}: missing YAML frontmatter opening fence")

    closing_index = None
    for idx, raw_line in enumerate(lines[1:], start=1):
        if raw_line.strip() == "---":
            closing_index = idx
            break
    if closing_index is None:
        fail(f"{path}: missing YAML frontmatter closing fence")

    frontmatter: Frontmatter = {}
    for raw_line in lines[1:closing_index]:
        line = raw_line.strip()
        if not line:
            continue
        if ":" not in line:
            fail(f"{path}: invalid frontmatter line '{raw_line}'")
        key, raw_value = line.split(":", 1)
        key = key.strip()
        value = raw_value.strip()
        if not key:
            fail(f"{path}: empty frontmatter key")
        frontmatter[key] = parse_scalar(value)

    return frontmatter


def parse_scalar(value: str) -> FrontmatterValue:
    if not value:
        return ""
    if value.startswith("["):
        try:
            parsed = ast.literal_eval(value)
        except (SyntaxError, ValueError) as exc:
            raise SystemExit(
                f"[FAIL] invalid list literal in frontmatter: {value}"
            ) from exc
        if not isinstance(parsed, list):
            fail(f"frontmatter value is not a list: {value}")
        if not all(isinstance(item, str) for item in parsed):
            fail(f"frontmatter list must contain only strings: {value}")
        return [item for item in parsed if isinstance(item, str)]
    if value.startswith(('"', "'")):
        try:
            parsed = ast.literal_eval(value)
        except (SyntaxError, ValueError) as exc:
            raise SystemExit(
                f"[FAIL] invalid quoted frontmatter value: {value}"
            ) from exc
        if not isinstance(parsed, str):
            fail(f"frontmatter quoted value must decode to string: {value}")
        return parsed
    return value


def validate_file(path: Path) -> list[str]:
    errors: list[str] = []
    match = FILENAME_RE.match(path.name)
    if not match:
        errors.append(
            "filename must match {issue_id}-{status}-{priority}-{description}.md with kebab-case description"
        )
        return errors

    text = path.read_text(encoding="utf-8")
    try:
        frontmatter = parse_frontmatter(path, text)
    except SystemExit as exc:
        errors.append(str(exc).replace("[FAIL] ", ""))
        return errors

    missing = REQUIRED_FRONTMATTER - frontmatter.keys()
    if missing:
        errors.append(
            f"missing required frontmatter keys: {', '.join(sorted(missing))}"
        )

    status = frontmatter.get("status")
    if status not in VALID_STATUSES:
        errors.append(f"status must be one of {', '.join(sorted(VALID_STATUSES))}")
    elif status != match.group("status"):
        errors.append("status in frontmatter must match filename")

    priority = frontmatter.get("priority")
    if priority not in VALID_PRIORITIES:
        errors.append(f"priority must be one of {', '.join(sorted(VALID_PRIORITIES))}")
    elif priority != match.group("priority"):
        errors.append("priority in frontmatter must match filename")

    issue_id = frontmatter.get("issue_id")
    if not isinstance(issue_id, str) or not re.fullmatch(r"\d{3}", issue_id):
        errors.append("issue_id must be a three-digit string")
    elif issue_id != match.group("issue_id"):
        errors.append("issue_id in frontmatter must match filename")

    for list_key in ("tags", "dependencies"):
        if list_key in frontmatter and not isinstance(frontmatter[list_key], list):
            errors.append(f"{list_key} must be a list of strings")

    headings = set(HEADING_RE.findall(text))
    missing_sections = REQUIRED_SECTIONS - headings
    if missing_sections:
        errors.append(
            f"missing required sections: {', '.join(sorted(missing_sections))}"
        )

    return errors


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--todos-dir", default="todos", help="Path to repo todo directory"
    )
    args = parser.parse_args()

    todos_dir = Path(cast(str, args.todos_dir)).resolve()
    if not todos_dir.exists():
        print("[OK] todos directory not present; nothing to validate")
        return 0

    if not todos_dir.is_dir():
        fail(f"todos path is not a directory: {todos_dir}")

    todo_files = sorted(
        path for path in todos_dir.glob("*.md") if path.name not in {"README.md"}
    )
    if not todo_files:
        print("[OK] no todo markdown files to validate")
        return 0

    failures: list[tuple[Path, list[str]]] = []
    for path in todo_files:
        errors = validate_file(path)
        if errors:
            failures.append((path, errors))

    if failures:
        print("[FAIL] todo validation failed")
        for path, errors in failures:
            print(f" - {path.relative_to(todos_dir.parent)}")
            for error in errors:
                print(f"   - {error}")
        return 1

    print(f"[OK] validated {len(todo_files)} todo file(s)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
