#!/usr/bin/env python3
"""Validate phase contracts and fail on drift between contract and phase files."""

from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path
from typing import cast


ID_RE = re.compile(r"^\d{2}$")
LABEL_RE = re.compile(r"^[a-z0-9]+(?:-[a-z0-9]+)*$")


def load_contracts(path: Path) -> dict[str, object]:
    try:
        data = json.loads(path.read_text(encoding="utf-8"))
    except FileNotFoundError:
        fail(f"contracts file not found: {path}")
    except json.JSONDecodeError as exc:
        fail(f"invalid JSON in contracts file: {exc}")
    if not isinstance(data, dict):
        fail(f"contracts file must be a JSON object: {path}")
    return data


def fail(message: str) -> None:
    print(f"[FAIL] {message}")
    raise SystemExit(1)


def read_annotation(content: str, key: str) -> str | None:
    pattern = re.compile(rf"^\s*#\s*{re.escape(key)}:\s*(.+?)\s*$", re.MULTILINE)
    match = pattern.search(content)
    return match.group(1).strip() if match else None


def require_non_empty_list(
    phase: dict[str, object], field: str, errors: list[str], label: str
) -> None:
    value = phase.get(field)
    if not isinstance(value, list) or not all(
        isinstance(item, str) and item.strip() for item in value
    ):
        errors.append(f"{label}: '{field}' must be a list of non-empty strings")
        return
    if field in {"inputs", "outputs", "side_effects"} and not value:
        errors.append(f"{label}: '{field}' must not be empty")


def main() -> int:
    parser = argparse.ArgumentParser(description="Validate phase contract checklist")
    parser.add_argument(
        "--contracts",
        default="phase-contracts.json",
        help="Path to phase contracts JSON file",
    )
    args = parser.parse_args()

    contracts_path = Path(cast(str, args.contracts)).resolve()
    repo_root = Path.cwd()
    data = load_contracts(contracts_path)
    raw_phases = data.get("phases")
    if not isinstance(raw_phases, list) or not raw_phases:
        fail("contracts must include a non-empty 'phases' array")
    assert isinstance(raw_phases, list)

    errors: list[str] = []
    phases: list[dict[str, object]] = []
    for idx, raw_phase in enumerate(cast(list[object], raw_phases), start=1):
        if not isinstance(raw_phase, dict):
            errors.append(f"phase[{idx}] must be an object")
            continue
        normalized_phase = {
            str(key): value
            for key, value in cast(dict[object, object], raw_phase).items()
            if isinstance(key, str)
        }
        phases.append(normalized_phase)

    seen_ids: set[str] = set()
    seen_labels: set[str] = set()
    seen_scripts: set[str] = set()
    phase_ids: set[str] = set()

    for idx, phase in enumerate(phases, start=1):
        phase_id = phase.get("id")
        label = phase.get("label")
        script = phase.get("script")
        phase_ref = f"phase[{idx}]"
        if isinstance(phase_id, str):
            phase_ref = phase_id
            phase_ids.add(phase_id)

        if not isinstance(phase_id, str) or not ID_RE.match(phase_id):
            errors.append(f"{phase_ref}: 'id' must be a two-digit string")
        elif phase_id in seen_ids:
            errors.append(f"{phase_ref}: duplicate id '{phase_id}'")
        else:
            seen_ids.add(phase_id)

        if not isinstance(label, str) or not LABEL_RE.match(label):
            errors.append(f"{phase_ref}: 'label' must be kebab-case")
        elif label in seen_labels:
            errors.append(f"{phase_ref}: duplicate label '{label}'")
        else:
            seen_labels.add(label)

        if not isinstance(script, str) or not script.strip():
            errors.append(f"{phase_ref}: 'script' must be a non-empty string")
            continue
        if script in seen_scripts:
            errors.append(f"{phase_ref}: duplicate script '{script}'")
        else:
            seen_scripts.add(script)

        require_non_empty_list(phase, "inputs", errors, phase_ref)
        require_non_empty_list(phase, "outputs", errors, phase_ref)
        require_non_empty_list(phase, "side_effects", errors, phase_ref)
        must_run_after = phase.get("must_run_after")
        if not isinstance(must_run_after, list) or not all(
            isinstance(item, str) and ID_RE.match(item) for item in must_run_after
        ):
            errors.append(
                f"{phase_ref}: 'must_run_after' must be a list of two-digit ids"
            )
        behavior_markers = phase.get("behavior_markers", [])
        if not isinstance(behavior_markers, list) or not all(
            isinstance(item, str) and item.strip() for item in behavior_markers
        ):
            errors.append(
                f"{phase_ref}: 'behavior_markers' must be a list of non-empty strings"
            )

    for phase in phases:
        phase_id = phase.get("id")
        label = phase.get("label")
        script = phase.get("script")
        if not (
            isinstance(phase_id, str)
            and isinstance(label, str)
            and isinstance(script, str)
        ):
            continue

        script_path = (repo_root / script).resolve()
        if not script_path.exists():
            errors.append(f"{phase_id}: script not found '{script}'")
            continue

        base = script_path.name
        expected_stem = f"{phase_id}-{label}"
        if not (base == f"{expected_stem}.zsh" or base == f"{expected_stem}.sh"):
            errors.append(
                f"{phase_id}: filename '{base}' must match '{expected_stem}.zsh' or '{expected_stem}.sh'"
            )

        content = script_path.read_text()
        ann_id = read_annotation(content, "PHASE_ID")
        ann_label = read_annotation(content, "PHASE_LABEL")
        if ann_id is None:
            errors.append(f"{phase_id}: missing '# PHASE_ID:' annotation in '{script}'")
        elif ann_id != phase_id:
            errors.append(
                f"{phase_id}: PHASE_ID annotation '{ann_id}' does not match contract id"
            )
        if ann_label is None:
            errors.append(
                f"{phase_id}: missing '# PHASE_LABEL:' annotation in '{script}'"
            )
        elif ann_label != label:
            errors.append(
                f"{phase_id}: PHASE_LABEL annotation '{ann_label}' does not match contract label"
            )

        behavior_markers = phase.get("behavior_markers")
        if not isinstance(behavior_markers, list):
            behavior_markers = []

        for marker in behavior_markers:
            if marker not in content:
                errors.append(
                    f"{phase_id}: behavior marker '{marker}' not found in '{script}'"
                )

        must_run_after = phase.get("must_run_after")
        if not isinstance(must_run_after, list):
            must_run_after = []

        for dep in must_run_after:
            if dep not in phase_ids:
                errors.append(
                    f"{phase_id}: dependency '{dep}' in must_run_after does not exist"
                )
                continue
            if dep >= phase_id:
                errors.append(
                    f"{phase_id}: dependency '{dep}' must be numerically lower than phase id"
                )

    if errors:
        print("[FAIL] phase contract validation failed")
        for item in errors:
            print(f" - {item}")
        return 1

    print("[OK] phase contract validation passed")
    return 0


if __name__ == "__main__":
    sys.exit(main())
