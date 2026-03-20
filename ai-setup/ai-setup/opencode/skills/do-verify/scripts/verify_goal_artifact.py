#!/usr/bin/env python3
"""Deterministic goal-backward gate for markdown ticket/task artifacts.

This gate enforces that the supplied artifact has an Acceptance Criteria section
with checklist items and that all checklist items are checked.
"""

from __future__ import annotations

import argparse
import re
from pathlib import Path
from typing import cast


HEADING_RE = re.compile(r"^(#{1,6})\s+(.+?)\s*$")
CHECKBOX_RE = re.compile(r"^\s*-\s*\[(?P<state>[ xX])\]\s+(?P<text>.+?)\s*$")
TARGET_SECTIONS = {"acceptance criteria", "success criteria", "checklist"}
REPO_ROOT = Path(__file__).resolve().parents[4]


def normalize_heading(raw: str) -> str:
    return " ".join(raw.strip().lower().split())


def extract_section(lines: list[str]) -> tuple[list[str], str] | None:
    headings: list[tuple[int, int, str, str]] = []
    for index, line in enumerate(lines):
        match = HEADING_RE.match(line)
        if not match:
            continue
        level = len(match.group(1))
        heading_raw = match.group(2).strip()
        headings.append((index, level, normalize_heading(heading_raw), heading_raw))

    for i, (start_index, level, normalized, heading_raw) in enumerate(headings):
        if normalized not in TARGET_SECTIONS:
            continue
        end_index = len(lines)
        for next_index in range(i + 1, len(headings)):
            candidate_index, candidate_level, _, _ = headings[next_index]
            if candidate_level <= level:
                end_index = candidate_index
                break
        return (lines[start_index + 1 : end_index], heading_raw)
    return None


def collect_checkboxes(lines: list[str]) -> tuple[list[str], list[str]]:
    checked: list[str] = []
    unchecked: list[str] = []

    for raw_line in lines:
        match = CHECKBOX_RE.match(raw_line)
        if not match:
            continue
        text = match.group("text").strip()
        if match.group("state").lower() == "x":
            checked.append(text)
        else:
            unchecked.append(text)

    return checked, unchecked


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    _ = parser.add_argument(
        "--artifact", required=True, help="Path to markdown goal artifact"
    )
    args: argparse.Namespace = parser.parse_args()

    requested = Path(cast(str, args.artifact))
    if requested.is_absolute():
        artifact = requested.resolve()
    else:
        artifact = (Path.cwd() / requested).resolve()

    try:
        _ = artifact.relative_to(REPO_ROOT)
    except ValueError:
        print(f"[FAIL] goal artifact must be inside repository root: {REPO_ROOT}")
        return 1

    if not artifact.exists():
        print(f"[FAIL] goal artifact not found: {artifact}")
        return 1

    if not artifact.is_file():
        print(f"[FAIL] goal artifact is not a file: {artifact}")
        return 1

    if artifact.suffix.lower() != ".md":
        print(f"[FAIL] goal artifact must be markdown (.md): {artifact}")
        return 1

    try:
        text = artifact.read_text(encoding="utf-8")
    except OSError as exc:
        print(f"[FAIL] could not read goal artifact: {artifact} ({exc})")
        return 1
    lines = text.splitlines()

    section = extract_section(lines)
    if section is None:
        print(
            "[FAIL] goal artifact is missing a required section: Acceptance Criteria / Success Criteria / Checklist"
        )
        return 1

    section_lines, section_name = section
    checked, unchecked = collect_checkboxes(section_lines)

    if not checked and not unchecked:
        print(
            f"[FAIL] section '{section_name}' in {artifact} has no checklist items (- [ ] / - [x])"
        )
        return 1

    if unchecked:
        print(
            f"[FAIL] {len(unchecked)} unchecked goal criteria in {artifact} (section: {section_name})"
        )
        for item in unchecked:
            print(f"  - [ ] {item}")
        return 1

    print(
        f"[PASS] goal artifact gate: {len(checked)} criteria checked in {artifact} (section: {section_name})"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
