#!/usr/bin/env python3
"""Check hidden-mode decoy candidate quality for bundled Imposter word packs."""

from __future__ import annotations

import argparse
import json
import re
import sys
import unicodedata
from pathlib import Path
from typing import Any


EXPECTED_PACKS = {
    "words_animals.json": "Animals",
    "words_technology.json": "Technology",
    "words_objects.json": "Objects",
    "words_people.json": "People",
    "words_movies.json": "Movies",
}
MECHANICAL_TAGS = {"easy", "medium", "hard", "pack-word"}


def load_json(path: Path) -> Any:
    with path.open(encoding="utf-8") as file:
        return json.load(file)


def normalized_tokens(value: str) -> list[str]:
    normalized = unicodedata.normalize("NFKD", value)
    normalized = normalized.encode("ascii", "ignore").decode().casefold()
    tokens: list[str] = []
    for token in re.split(r"[^a-z0-9]+", normalized):
        if not token:
            continue
        if len(token) > 4 and token.endswith("ies"):
            token = f"{token[:-3]}y"
        elif len(token) > 4 and token.endswith("es"):
            token = token[:-2]
        elif len(token) > 3 and token.endswith("s"):
            token = token[:-1]
        tokens.append(token)
    return tokens


def normalized_key(value: str) -> str:
    return " ".join(normalized_tokens(value))


def edit_distance(lhs: str, rhs: str) -> int:
    previous_row = list(range(len(rhs) + 1))
    for lhs_index, lhs_character in enumerate(lhs, 1):
        current_row = [lhs_index] + [0] * len(rhs)
        for rhs_index, rhs_character in enumerate(rhs, 1):
            current_row[rhs_index] = min(
                previous_row[rhs_index] + 1,
                current_row[rhs_index - 1] + 1,
                previous_row[rhs_index - 1] + int(lhs_character != rhs_character),
            )
        previous_row = current_row
    return previous_row[-1]


def is_near_duplicate(lhs: str, rhs: str) -> bool:
    lhs_tokens = normalized_tokens(lhs)
    rhs_tokens = normalized_tokens(rhs)
    if not lhs_tokens or not rhs_tokens:
        return False

    lhs_key = " ".join(lhs_tokens)
    rhs_key = " ".join(rhs_tokens)
    if lhs_key == rhs_key:
        return True

    lhs_set = set(lhs_tokens)
    rhs_set = set(rhs_tokens)
    if lhs_set <= rhs_set or rhs_set <= lhs_set:
        return True

    larger_count = max(len(lhs_set), len(rhs_set))
    if larger_count > 1 and len(lhs_set & rhs_set) / larger_count >= 0.67:
        return True

    shorter_length = min(len(lhs_key), len(rhs_key))
    if shorter_length < 5:
        return False

    distance = edit_distance(lhs_key, rhs_key)
    longer_length = max(len(lhs_key), len(rhs_key))
    return distance <= 1 or (
        shorter_length >= 8 and distance <= 2 and distance / longer_length <= 0.2
    )


def semantic_tags(entry: dict[str, Any]) -> set[str]:
    category = normalized_key(str(entry.get("category", "")))
    difficulty = normalized_key(str(entry.get("difficulty", "")))
    mechanical_tags = MECHANICAL_TAGS | {category, difficulty}
    tags = entry.get("tags", [])
    if not isinstance(tags, list):
        return set()
    return {
        normalized_key(tag)
        for tag in tags
        if isinstance(tag, str) and normalized_key(tag) not in mechanical_tags
    }


def load_entries(root: Path) -> tuple[list[dict[str, Any]], list[str]]:
    entries: list[dict[str, Any]] = []
    errors: list[str] = []
    for filename, expected_category in EXPECTED_PACKS.items():
        path = root / filename
        if not path.exists():
            errors.append(f"Missing word pack: {path}")
            continue
        try:
            pack = load_json(path)
        except json.JSONDecodeError as error:
            errors.append(f"{path}: invalid JSON: {error}")
            continue
        words = pack.get("words") if isinstance(pack, dict) else None
        if not isinstance(words, list):
            errors.append(f"{path.name}: words must be a list.")
            continue
        for index, entry in enumerate(words):
            if not isinstance(entry, dict):
                errors.append(f"{path.name}: words[{index}] must be an object.")
                continue
            entry = dict(entry)
            entry["packFile"] = path.name
            entry["expectedCategory"] = expected_category
            entries.append(entry)
    return entries, errors


def check_decoys(entries: list[dict[str, Any]]) -> tuple[list[str], dict[str, Any]]:
    errors: list[str] = []
    same_tier_covered = 0
    shared_tag_covered = 0
    best_shared_tag_counts: list[int] = []

    for entry in entries:
        word = entry.get("word")
        category = entry.get("category")
        difficulty = entry.get("difficulty")
        localization_key = entry.get("localizationKey", "<missing key>")
        if not all(isinstance(value, str) for value in (word, category, difficulty)):
            errors.append(f"{localization_key}: word/category/difficulty must be strings.")
            continue

        candidates = [
            candidate
            for candidate in entries
            if candidate.get("localizationKey") != localization_key
            and candidate.get("category") == category
            and candidate.get("difficulty") == difficulty
            and isinstance(candidate.get("word"), str)
            and not is_near_duplicate(str(candidate["word"]), str(word))
        ]

        if not candidates:
            errors.append(
                f"{localization_key}: no same-category same-difficulty decoy candidate."
            )
            continue

        same_tier_covered += 1
        entry_tags = semantic_tags(entry)
        best_shared_tag_count = max(
            len(entry_tags & semantic_tags(candidate)) for candidate in candidates
        )
        best_shared_tag_counts.append(best_shared_tag_count)
        if best_shared_tag_count <= 0:
            errors.append(
                f"{localization_key}: no same-tier decoy shares a semantic tag."
            )
        else:
            shared_tag_covered += 1

    average_best_shared_tags = (
        sum(best_shared_tag_counts) / len(best_shared_tag_counts)
        if best_shared_tag_counts
        else 0
    )
    summary = {
        "total_words": len(entries),
        "same_tier_covered": same_tier_covered,
        "shared_tag_covered": shared_tag_covered,
        "average_best_shared_tags": average_best_shared_tags,
    }
    return errors, summary


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Validate hidden-mode decoy candidate coverage."
    )
    parser.add_argument(
        "root",
        nargs="?",
        type=Path,
        default=Path("Imposter/Resources/WordPacks"),
        help="Directory containing words_*.json files.",
    )
    args = parser.parse_args()

    entries, errors = load_entries(args.root)
    decoy_errors, summary = check_decoys(entries)
    errors.extend(decoy_errors)

    print("Decoy quality")
    print(f"Root: {args.root}")
    print(f"Total words: {summary['total_words']}")
    print(f"Same-tier decoy coverage: {summary['same_tier_covered']}/{summary['total_words']}")
    print(f"Shared-tag decoy coverage: {summary['shared_tag_covered']}/{summary['total_words']}")
    print(f"Average best shared tags: {summary['average_best_shared_tags']:.2f}")

    if errors:
        print("Decoy quality check failed:", file=sys.stderr)
        for error in errors:
            print(f"- {error}", file=sys.stderr)
        return 1

    print("PASS: hidden-mode decoy candidate quality is acceptable.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
