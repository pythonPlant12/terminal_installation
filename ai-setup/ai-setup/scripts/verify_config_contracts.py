#!/usr/bin/env python3
"""Validate actual repo config files against local contract schemas."""

from __future__ import annotations

import json
import re
import sys
from pathlib import Path


TYPE_NAMES = {
    "string": str,
    "boolean": bool,
    "object": dict,
    "array": list,
}


def fail(message: str) -> None:
    print(f"[FAIL] {message}")
    raise SystemExit(1)


def load_json(path: Path, *, allow_jsonc: bool = False) -> object:
    text = path.read_text(encoding="utf-8")
    if allow_jsonc:
        text = strip_jsonc(text)
    try:
        return json.loads(text)
    except json.JSONDecodeError as exc:
        fail(f"invalid JSON in {path}: {exc}")
    return None


def strip_jsonc(text: str) -> str:
    without_comments = re.sub(r"(?<!:)//[^\n]*", "", text)
    return re.sub(r",(\s*[}\]])", r"\1", without_comments)


def validate_value(
    value: object, schema: dict[str, object], context: str, errors: list[str]
) -> None:
    expected_type = schema.get("type")
    if isinstance(expected_type, str):
        expected_python = TYPE_NAMES.get(expected_type)
        if expected_python is None:
            errors.append(f"{context}: unsupported schema type '{expected_type}'")
            return
        if not isinstance(value, expected_python):
            errors.append(f"{context}: expected {expected_type}")
            return

    if isinstance(value, dict):
        properties = schema.get("properties")
        if isinstance(properties, dict):
            required = schema.get("required", [])
            if isinstance(required, list):
                for key in required:
                    if isinstance(key, str) and key not in value:
                        errors.append(f"{context}: missing required key '{key}'")

            for key, property_schema in properties.items():
                if key not in value or not isinstance(key, str):
                    continue
                if not isinstance(property_schema, dict):
                    continue
                validate_value(value[key], property_schema, f"{context}.{key}", errors)

    if isinstance(value, list):
        item_schema = schema.get("items")
        if isinstance(item_schema, dict):
            for index, item in enumerate(value):
                validate_value(item, item_schema, f"{context}[{index}]", errors)


def main() -> int:
    checks = [
        (
            Path("opencode/opencode.jsonc"),
            Path("docs/specs/opencode-runtime-config-v1.schema.json"),
            True,
        ),
        (
            Path("opencode/oh-my-opencode.json"),
            Path("docs/specs/omo-agent-routing-config-v1.schema.json"),
            False,
        ),
    ]

    errors: list[str] = []
    for config_path, schema_path, allow_jsonc in checks:
        if not config_path.exists():
            errors.append(f"missing config file: {config_path}")
            continue
        if not schema_path.exists():
            errors.append(f"missing schema file: {schema_path}")
            continue

        config = load_json(config_path, allow_jsonc=allow_jsonc)
        schema = load_json(schema_path)
        if not isinstance(config, dict):
            errors.append(f"{config_path}: root must be an object")
            continue
        if not isinstance(schema, dict):
            errors.append(f"{schema_path}: root must be an object")
            continue
        validate_value(config, schema, str(config_path), errors)

    if errors:
        print("[FAIL] config contract validation failed")
        for error in errors:
            print(f" - {error}")
        return 1

    print(f"[OK] validated {len(checks)} repo config contract surface(s)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
