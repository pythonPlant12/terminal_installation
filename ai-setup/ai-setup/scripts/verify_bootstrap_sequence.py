#!/usr/bin/env python3
"""Validate required bootstrap step ordering for plugin and config safety."""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path
from typing import NoReturn, TypedDict, cast


class BootstrapStep(TypedDict):
    id: str
    marker: str


def fail(message: str) -> NoReturn:
    print(f"[FAIL] {message}")
    raise SystemExit(1)


def load_contract(path: Path) -> list[BootstrapStep]:
    try:
        data: object = json.loads(path.read_text(encoding="utf-8"))
    except FileNotFoundError as exc:
        raise SystemExit(f"[FAIL] contract file not found: {path}") from exc
    except json.JSONDecodeError as exc:
        raise SystemExit(
            f"[FAIL] invalid JSON in bootstrap order contract: {exc}"
        ) from exc

    if not isinstance(data, dict):
        fail("bootstrap order contract root must be an object")
    contract_data = cast(dict[str, object], data)

    steps = contract_data.get("steps")
    if not isinstance(steps, list) or not steps:
        fail("bootstrap order contract must contain a non-empty 'steps' array")
    raw_steps = cast(list[object], steps)

    normalized: list[BootstrapStep] = []
    for index, item in enumerate(raw_steps, start=1):
        if not isinstance(item, dict):
            fail(f"steps[{index}] must be an object")
        step_data = cast(dict[str, object], item)
        step_id_value = step_data.get("id")
        marker_value = step_data.get("marker")
        if not isinstance(step_id_value, str) or not step_id_value.strip():
            fail(f"steps[{index}] missing non-empty 'id'")
        if not isinstance(marker_value, str) or not marker_value.strip():
            fail(f"steps[{index}] missing non-empty 'marker'")
        normalized.append(
            BootstrapStep(id=step_id_value.strip(), marker=marker_value.strip())
        )

    return normalized


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    _ = parser.add_argument(
        "--contract",
        default="bootstrap-step-order.json",
        help="Path to bootstrap step ordering contract",
    )
    _ = parser.add_argument(
        "--bootstrap-script",
        default="scripts/bootstrap.zsh",
        help="Path to bootstrap orchestrator script",
    )
    args = parser.parse_args()

    contract_path = Path(str(args.contract)).resolve()
    bootstrap_path = Path(str(args.bootstrap_script)).resolve()
    if not bootstrap_path.exists():
        fail(f"bootstrap script not found: {bootstrap_path}")

    steps = load_contract(contract_path)
    content = bootstrap_path.read_text(encoding="utf-8")

    previous_position = -1
    for step in steps:
        marker = step["marker"]
        marker_occurrences = content.count(marker)
        if marker_occurrences == 0:
            fail(f"missing bootstrap marker '{marker}' for step '{step['id']}'")
        if marker_occurrences > 1:
            fail(
                f"bootstrap marker '{marker}' for step '{step['id']}' is ambiguous; found {marker_occurrences} occurrences"
            )

        position = content.find(marker)
        if position <= previous_position:
            fail(
                f"bootstrap step '{step['id']}' is out of order; marker '{marker}' appears before the prior required step"
            )
        previous_position = position

    print(f"[OK] bootstrap step order validated for {len(steps)} required steps")
    return 0


if __name__ == "__main__":
    sys.exit(main())
