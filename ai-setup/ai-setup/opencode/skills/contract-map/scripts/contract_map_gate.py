#!/usr/bin/env python3
"""Contract-map gate: key alignment + schema checks for config-affecting PRs."""

from __future__ import annotations

import argparse
import fnmatch
import json
import subprocess
from pathlib import Path
from typing import Any

DOC_FIELDS = {
    "description",
    "title",
    "$comment",
    "examples",
    "example",
    "default",
    "deprecated",
    "readOnly",
    "writeOnly",
}

CONFIG_GLOBS = [
    "*.json",
    "*.jsonc",
    "*.yaml",
    "*.yml",
    "*.toml",
    "*.ini",
    "*.conf",
    "*.properties",
    "Brewfile",
    "mise.toml",
    "opencode/*.jsonc",
    "docs/specs/*.json",
    "docs/specs/*.yaml",
    "docs/specs/*.yml",
]


def run_command(args: list[str], cwd: Path) -> tuple[int, str, str]:
    proc = subprocess.run(
        args,
        cwd=str(cwd),
        capture_output=True,
        text=True,
        check=False,
    )
    return proc.returncode, proc.stdout.strip(), proc.stderr.strip()


def normalize(path: str) -> str:
    return path.replace("\\", "/").lstrip("./")


def is_config_affecting(path: str) -> bool:
    clean = normalize(path)
    base = clean.split("/")[-1]

    if any(fnmatch.fnmatch(clean, pat) for pat in CONFIG_GLOBS):
        return True
    if "/config/" in f"/{clean}/" or clean.startswith("config/"):
        return True
    if "schema" in base and base.endswith((".json", ".yaml", ".yml")):
        return True
    return False


def detect_changed_files(repo_root: Path, base_ref: str, head_ref: str) -> list[str]:
    code, _, _ = run_command(["git", "rev-parse", "--verify", base_ref], repo_root)
    if code != 0:
        base_ref = "HEAD~1"

    code, out, err = run_command(
        ["git", "diff", "--name-only", f"{base_ref}...{head_ref}"], repo_root
    )
    if code != 0:
        raise RuntimeError(f"failed to resolve changed files: {err or out}")

    return [normalize(line) for line in out.splitlines() if line.strip()]


def load_json_file(path: Path) -> Any:
    with path.open("r", encoding="utf-8") as handle:
        return json.load(handle)


def normalize_schema_shape(node: Any) -> Any:
    if isinstance(node, dict):
        cleaned = {}
        for key in sorted(node):
            if key in DOC_FIELDS:
                continue
            cleaned[key] = normalize_schema_shape(node[key])
        return cleaned
    if isinstance(node, list):
        return [normalize_schema_shape(item) for item in node]
    return node


def watch_match(pattern: str, changed_files: list[str]) -> bool:
    if pattern.startswith("re:"):
        import re

        regex = re.compile(pattern[3:])
        return any(regex.search(path) for path in changed_files)
    return any(fnmatch.fnmatch(path, pattern) for path in changed_files)


def validate_actor(
    actor: dict[str, Any],
    role: str,
    contract_name: str,
    repo_root: Path,
    errors: list[str],
) -> dict[str, Any] | None:
    actor_name = actor.get("name", "<unnamed>")
    context = f"{contract_name}:{role}:{actor_name}"

    keys = actor.get("keys")
    schema_rel = actor.get("schema")

    if not isinstance(keys, list) or not keys or not all(isinstance(k, str) and k for k in keys):
        errors.append(f"{context}: keys must be a non-empty string array")
        return None

    if len(set(keys)) != len(keys):
        errors.append(f"{context}: keys contains duplicates")
        return None

    if not isinstance(schema_rel, str) or not schema_rel.strip():
        errors.append(f"{context}: schema must be a non-empty path")
        return None

    schema_path = (repo_root / schema_rel).resolve()
    if not schema_path.exists():
        errors.append(f"{context}: schema file not found: {schema_rel}")
        return None

    try:
        schema = load_json_file(schema_path)
    except json.JSONDecodeError as exc:
        errors.append(f"{context}: schema is not valid JSON: {schema_rel} ({exc})")
        return None
    except OSError as exc:
        errors.append(f"{context}: unable to read schema {schema_rel}: {exc}")
        return None

    if not isinstance(schema, dict):
        errors.append(f"{context}: schema root must be an object")
        return None

    properties = schema.get("properties")
    if schema.get("type") != "object" or not isinstance(properties, dict):
        errors.append(
            f"{context}: schema must define type=object and properties object"
        )
        return None

    missing = [key for key in keys if key not in properties]
    if missing:
        errors.append(
            f"{context}: keys missing from schema.properties: {', '.join(sorted(missing))}"
        )

    required = schema.get("required", [])
    if not isinstance(required, list):
        errors.append(f"{context}: schema.required must be an array when present")

    return {
        "name": actor_name,
        "keys": set(keys),
        "properties": properties,
        "schema": schema_rel,
    }


def compare_alignment(
    contract: dict[str, Any], repo_root: Path, changed_files: list[str], errors: list[str]
) -> bool:
    name = contract.get("name", "<unnamed-contract>")
    watch_patterns = contract.get("watch", [])

    if watch_patterns:
        if not isinstance(watch_patterns, list) or not all(
            isinstance(item, str) and item for item in watch_patterns
        ):
            errors.append(f"{name}: watch must be a list of non-empty strings")
            return True

        if not any(watch_match(pattern, changed_files) for pattern in watch_patterns):
            return False

    producers = contract.get("producers")
    consumers = contract.get("consumers")

    if not isinstance(producers, list) or not producers:
        errors.append(f"{name}: producers must be a non-empty array")
        return True
    if not isinstance(consumers, list) or not consumers:
        errors.append(f"{name}: consumers must be a non-empty array")
        return True

    checked_producers = [
        validate_actor(actor, "producer", name, repo_root, errors) for actor in producers
    ]
    checked_consumers = [
        validate_actor(actor, "consumer", name, repo_root, errors) for actor in consumers
    ]

    checked_producers = [actor for actor in checked_producers if actor is not None]
    checked_consumers = [actor for actor in checked_consumers if actor is not None]

    if not checked_producers or not checked_consumers:
        return True

    producer_keys = checked_producers[0]["keys"]
    consumer_keys = checked_consumers[0]["keys"]

    for actor in checked_producers[1:]:
        if actor["keys"] != producer_keys:
            errors.append(
                f"{name}: producer key drift between {checked_producers[0]['name']} and {actor['name']}"
            )

    for actor in checked_consumers[1:]:
        if actor["keys"] != consumer_keys:
            errors.append(
                f"{name}: consumer key drift between {checked_consumers[0]['name']} and {actor['name']}"
            )

    allow_superset = bool(contract.get("allow_consumer_superset", False))
    if allow_superset:
        if not producer_keys.issubset(consumer_keys):
            missing = sorted(producer_keys - consumer_keys)
            errors.append(
                f"{name}: consumer keys must include producer keys, missing: {', '.join(missing)}"
            )
    else:
        if producer_keys != consumer_keys:
            missing_in_consumer = sorted(producer_keys - consumer_keys)
            missing_in_producer = sorted(consumer_keys - producer_keys)
            if missing_in_consumer:
                errors.append(
                    f"{name}: keys produced but not consumed: {', '.join(missing_in_consumer)}"
                )
            if missing_in_producer:
                errors.append(
                    f"{name}: keys consumed but not produced: {', '.join(missing_in_producer)}"
                )

    lead_producer = checked_producers[0]
    lead_consumer = checked_consumers[0]
    shared = sorted(producer_keys & consumer_keys)
    for key in shared:
        producer_shape = normalize_schema_shape(lead_producer["properties"].get(key))
        consumer_shape = normalize_schema_shape(lead_consumer["properties"].get(key))
        if producer_shape != consumer_shape:
            errors.append(
                f"{name}: schema property mismatch for '{key}' between "
                f"{lead_producer['name']} ({lead_producer['schema']}) and "
                f"{lead_consumer['name']} ({lead_consumer['schema']})"
            )

    return True


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--repo-root", default=".", help="repository root")
    parser.add_argument(
        "--manifest",
        default=".contract-map/contract-map.json",
        help="path to contract map manifest",
    )
    parser.add_argument("--base-ref", default="origin/main", help="base git ref")
    parser.add_argument("--head-ref", default="HEAD", help="head git ref")
    parser.add_argument(
        "--changed-file",
        action="append",
        default=[],
        help="explicit changed file (repeatable)",
    )
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    repo_root = Path(args.repo_root).resolve()

    if args.changed_file:
        changed_files = [normalize(path) for path in args.changed_file if path.strip()]
    else:
        try:
            changed_files = detect_changed_files(repo_root, args.base_ref, args.head_ref)
        except RuntimeError as exc:
            print(f"FAIL: {exc}")
            return 1

    if not changed_files:
        print("PASS: no changed files detected")
        return 0

    config_files = [path for path in changed_files if is_config_affecting(path)]
    if not config_files:
        print("PASS: no config-affecting changes detected")
        return 0

    print("Config-affecting files:")
    for path in config_files:
        print(f"- {path}")

    manifest_path = (repo_root / args.manifest).resolve()
    if not manifest_path.exists():
        print(
            "FAIL: config-affecting changes detected but manifest is missing: "
            f"{manifest_path}"
        )
        return 1

    try:
        manifest = load_json_file(manifest_path)
    except json.JSONDecodeError as exc:
        print(f"FAIL: manifest is not valid JSON: {manifest_path} ({exc})")
        return 1
    except OSError as exc:
        print(f"FAIL: unable to read manifest {manifest_path}: {exc}")
        return 1

    if not isinstance(manifest, dict):
        print("FAIL: manifest root must be an object")
        return 1

    contracts = manifest.get("contracts")
    if not isinstance(contracts, list) or not contracts:
        print("FAIL: manifest.contracts must be a non-empty array")
        return 1

    errors: list[str] = []
    checked_contracts = 0
    for contract in contracts:
        if not isinstance(contract, dict):
            errors.append("contract entry must be an object")
            continue

        checked = compare_alignment(contract, repo_root, config_files, errors)
        if checked:
            checked_contracts += 1

    if checked_contracts == 0:
        print(
            "FAIL: config-affecting changes detected but no contract matched. "
            "Update contracts[].watch patterns or add a contract for these files."
        )
        return 1

    if errors:
        print("FAIL: contract-map gate failed")
        for err in errors:
            print(f"- {err}")
        return 1

    print(f"PASS: {checked_contracts} contract(s) validated")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
