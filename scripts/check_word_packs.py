#!/usr/bin/env python3
"""Validate bundled Imposter word packs."""

from __future__ import annotations

import argparse
import json
import re
import sys
import unicodedata
from collections import Counter, defaultdict
from pathlib import Path
from typing import Any


EXPECTED_PACKS = {
    "words_animals.json": "Animals",
    "words_technology.json": "Technology",
    "words_objects.json": "Objects",
    "words_people.json": "People",
    "words_movies.json": "Movies",
}

METADATA_FILENAME = "category_metadata.json"
VALID_SAFETY_LEVELS = {"general", "review"}
VALID_DIFFICULTIES = {"easy", "medium", "hard"}
WORD_PATTERN = re.compile(r"^[\w\s&'.:!\-]+$", re.UNICODE)
ID_PATTERN = re.compile(r"^[a-z0-9]+(?:-[a-z0-9]+)*$")
LOCALIZATION_KEY_PATTERN = re.compile(r"^word\.[a-z0-9-]+\.[a-z0-9-]+$")
MECHANICAL_TAGS = {"easy", "medium", "hard", "pack-word"}

CURATED_TAG_PRIORITY_KEYS = {
    "word.animals.dog",
    "word.animals.cat",
    "word.animals.bird",
    "word.animals.fish",
    "word.animals.horse",
    "word.animals.owl",
    "word.animals.eagle",
    "word.animals.hawk",
    "word.animals.parrot",
    "word.animals.peacock",
    "word.animals.platypus",
    "word.animals.armadillo",
    "word.animals.anteater",
    "word.animals.sloth",
    "word.animals.tapir",
    "word.objects.chair",
    "word.objects.table",
    "word.objects.bed",
    "word.objects.pillow",
    "word.objects.blanket",
    "word.objects.couch",
    "word.objects.drawer",
    "word.objects.shelf",
    "word.objects.wardrobe",
    "word.objects.rug",
    "word.objects.chandelier",
    "word.objects.armoire",
    "word.objects.ottoman",
    "word.objects.credenza",
    "word.objects.chaise-lounge",
    "word.people.taylor-swift",
    "word.people.beyonce",
    "word.people.bad-bunny",
    "word.people.drake",
    "word.people.rihanna",
    "word.people.sza",
    "word.people.tyler-the-creator",
    "word.people.lana-del-rey",
    "word.people.hozier",
    "word.people.benson-boone",
    "word.people.michael-jackson",
    "word.people.prince",
    "word.people.freddie-mercury",
    "word.people.david-bowie",
    "word.people.whitney-houston",
    "word.movies.wicked",
    "word.movies.moana",
    "word.movies.deadpool",
    "word.movies.inside-out",
    "word.movies.despicable-me",
    "word.movies.chainsaw-man",
    "word.movies.dandadan",
    "word.movies.kaiju-no-8",
    "word.movies.frieren",
    "word.movies.oshi-no-ko",
    "word.movies.neon-genesis-evangelion",
    "word.movies.cowboy-bebop",
    "word.movies.spirited-away",
    "word.movies.princess-mononoke",
    "word.movies.akira",
    "word.technology.iphone-16",
    "word.technology.apple-vision-pro",
    "word.technology.airpods",
    "word.technology.macbook",
    "word.technology.ipad",
    "word.technology.marvel-rivals",
    "word.technology.black-myth-wukong",
    "word.technology.palworld",
    "word.technology.helldivers-2",
    "word.technology.baldur-s-gate-3",
    "word.technology.dark-souls",
    "word.technology.red-dead-redemption",
    "word.technology.cyberpunk-2077",
    "word.technology.the-witcher-3",
    "word.technology.world-of-warcraft",
}


def load_json(path: Path) -> Any:
    with path.open(encoding="utf-8") as file:
        return json.load(file)


def normalized_word(value: str) -> str:
    normalized = unicodedata.normalize("NFKC", value)
    return " ".join(normalized.casefold().split())


def validate_pack(
    path: Path,
    expected_category: str,
    min_words_per_pack: int,
    seen_words: dict[str, list[tuple[str, str]]],
    seen_ids: dict[str, str],
    seen_localization_keys: dict[str, str],
) -> list[str]:
    errors: list[str] = []

    try:
        pack = load_json(path)
    except json.JSONDecodeError as error:
        return [f"{path}: invalid JSON: {error}"]

    if not isinstance(pack, dict):
        return [f"{path}: expected a JSON object."]

    category = pack.get("category")
    if category != expected_category:
        errors.append(
            f"{path.name}: category {category!r} does not match expected "
            f"{expected_category!r}."
        )

    words = pack.get("words")
    if not isinstance(words, list):
        return errors + [f"{path.name}: words must be a list."]

    if len(words) < min_words_per_pack:
        errors.append(
            f"{path.name}: has {len(words)} words; expected at least "
            f"{min_words_per_pack}."
        )

    difficulty_counts: Counter[str] = Counter()
    local_words: set[str] = set()

    for index, entry in enumerate(words):
        location = f"{path.name}: words[{index}]"
        if not isinstance(entry, dict):
            errors.append(f"{location}: expected an object.")
            continue

        word = entry.get("word")
        word_id = entry.get("id")
        display_text = entry.get("displayText")
        entry_category = entry.get("category")
        difficulty = entry.get("difficulty")
        tags = entry.get("tags")
        localization_key = entry.get("localizationKey")
        safety = entry.get("safety")

        if not isinstance(word_id, str) or not ID_PATTERN.match(word_id):
            errors.append(f"{location}: id must be a kebab-case string.")
        elif word_id in seen_ids:
            errors.append(f"{location}: id duplicates {seen_ids[word_id]}: {word_id!r}.")
        else:
            seen_ids[word_id] = location

        if not isinstance(display_text, str) or not display_text.strip():
            errors.append(f"{location}: displayText must be a non-empty string.")

        if entry_category != expected_category:
            errors.append(
                f"{location}: category {entry_category!r} does not match pack "
                f"category {expected_category!r}."
            )

        if not isinstance(word, str) or not word.strip():
            errors.append(f"{location}: word must be a non-empty string.")
            continue

        if isinstance(display_text, str) and display_text.strip() and display_text != word:
            errors.append(f"{location}: displayText must match word during this schema phase.")

        if word != word.strip():
            errors.append(f"{location}: word has leading or trailing whitespace.")

        if len(word.strip()) < 2:
            errors.append(f"{location}: word is too short: {word!r}.")

        if not WORD_PATTERN.match(word):
            errors.append(f"{location}: word contains unsupported characters: {word!r}.")

        normalized = normalized_word(word)
        if normalized in local_words:
            errors.append(f"{location}: duplicate word within pack: {word!r}.")
        local_words.add(normalized)
        seen_words[normalized].append((path.name, word))

        if difficulty not in VALID_DIFFICULTIES:
            errors.append(
                f"{location}: difficulty {difficulty!r} must be one of "
                f"{sorted(VALID_DIFFICULTIES)}."
            )
        else:
            difficulty_counts[difficulty] += 1

        errors.extend(validate_tags(tags, location))

        if not isinstance(localization_key, str) or not LOCALIZATION_KEY_PATTERN.match(localization_key):
            errors.append(f"{location}: localizationKey must look like word.category.slug.")
        elif localization_key in seen_localization_keys:
            errors.append(
                f"{location}: localizationKey duplicates "
                f"{seen_localization_keys[localization_key]}: {localization_key!r}."
            )
        else:
            seen_localization_keys[localization_key] = location

        errors.extend(
            validate_semantic_tags(
                tags,
                location,
                expected_category,
                difficulty if isinstance(difficulty, str) else None,
            )
        )

        if not isinstance(safety, dict):
            errors.append(f"{location}: safety must be an object.")
        else:
            safety_level = safety.get("level")
            if safety_level not in VALID_SAFETY_LEVELS:
                errors.append(
                    f"{location}: safety.level {safety_level!r} must be one of "
                    f"{sorted(VALID_SAFETY_LEVELS)}."
                )

    missing_difficulties = VALID_DIFFICULTIES - set(difficulty_counts)
    if missing_difficulties:
        errors.append(
            f"{path.name}: missing difficulty tier(s): {sorted(missing_difficulties)}."
        )

    return errors


def validate_semantic_tags(
    tags: Any,
    location: str,
    category: str,
    difficulty: str | None,
) -> list[str]:
    errors: list[str] = []
    if not isinstance(tags, list):
        return errors

    mechanical_tags = MECHANICAL_TAGS | {normalized_word(category)}
    if difficulty is not None:
        mechanical_tags.add(normalized_word(difficulty))

    semantic_tags = [
        tag
        for tag in tags
        if isinstance(tag, str) and normalized_word(tag) not in mechanical_tags
    ]

    if len(tags) < 4:
        errors.append(f"{location}: word must have at least 4 tags.")
    if len(semantic_tags) < 2:
        errors.append(
            f"{location}: word must have at least 2 non-mechanical tags."
        )

    return errors


def validate_tags(tags: Any, location: str) -> list[str]:
    errors: list[str] = []
    if not isinstance(tags, list) or not tags:
        return [f"{location}: tags must be a non-empty list."]

    normalized_tags: set[str] = set()
    for tag_index, tag in enumerate(tags):
        tag_location = f"{location}: tags[{tag_index}]"
        if not isinstance(tag, str) or not tag.strip():
            errors.append(f"{tag_location}: tag must be a non-empty string.")
            continue
        normalized_tag = normalized_word(tag)
        if normalized_tag in normalized_tags:
            errors.append(f"{tag_location}: duplicate tag {tag!r}.")
        normalized_tags.add(normalized_tag)

    return errors


def validate_all(root: Path, min_words_per_pack: int) -> tuple[list[str], dict[str, Any]]:
    errors: list[str] = []
    seen_words: dict[str, list[tuple[str, str]]] = defaultdict(list)
    seen_ids: dict[str, str] = {}
    seen_localization_keys: dict[str, str] = {}

    for filename, expected_category in EXPECTED_PACKS.items():
        path = root / filename
        if not path.exists():
            errors.append(f"Missing word pack: {path}")
            continue
        errors.extend(
            validate_pack(
                path,
                expected_category,
                min_words_per_pack,
                seen_words,
                seen_ids,
                seen_localization_keys,
            )
        )

    errors.extend(validate_metadata(root / METADATA_FILENAME))

    allowed_json_files = set(EXPECTED_PACKS) | {METADATA_FILENAME}
    extra_packs = sorted(path.name for path in root.glob("*.json") if path.name not in allowed_json_files)
    for filename in extra_packs:
        errors.append(f"Unexpected word pack file: {filename}")

    duplicates = {
        word: locations
        for word, locations in seen_words.items()
        if len(locations) > 1
    }
    for word, locations in sorted(duplicates.items()):
        formatted = ", ".join(f"{filename}:{display}" for filename, display in locations)
        errors.append(f"Duplicate word across packs {word!r}: {formatted}")

    summary = {
        "expected_packs": len(EXPECTED_PACKS),
        "total_words": sum(len(locations) for locations in seen_words.values()),
        "unique_words": len(seen_words),
        "duplicates": len(duplicates),
        "metadata_categories": len(EXPECTED_PACKS),
        "schema_ids": len(seen_ids),
        "localization_keys": len(seen_localization_keys),
        "curated_tag_priority_keys": len(CURATED_TAG_PRIORITY_KEYS),
        "semantic_tag_checked_words": sum(len(locations) for locations in seen_words.values()),
    }

    return errors, summary


def validate_metadata(path: Path) -> list[str]:
    errors: list[str] = []
    if not path.exists():
        return [f"Missing category metadata: {path}"]

    try:
        metadata = load_json(path)
    except json.JSONDecodeError as error:
        return [f"{path}: invalid JSON: {error}"]

    if not isinstance(metadata, dict):
        return [f"{path.name}: expected a JSON object."]

    if metadata.get("version") != 1:
        errors.append(f"{path.name}: version must be 1.")

    categories = metadata.get("categories")
    if not isinstance(categories, list):
        return errors + [f"{path.name}: categories must be a list."]

    expected_categories = set(EXPECTED_PACKS.values())
    seen_categories: set[str] = set()

    for index, entry in enumerate(categories):
        location = f"{path.name}: categories[{index}]"
        if not isinstance(entry, dict):
            errors.append(f"{location}: expected an object.")
            continue

        category = entry.get("category")
        if category not in expected_categories:
            errors.append(f"{location}: unknown category {category!r}.")
        elif category in seen_categories:
            errors.append(f"{location}: duplicate category {category!r}.")
        else:
            seen_categories.add(category)

        icon = entry.get("iconSystemName")
        if not isinstance(icon, str) or not icon.strip():
            errors.append(f"{location}: iconSystemName must be a non-empty string.")

        safety = entry.get("safety")
        if safety not in VALID_SAFETY_LEVELS:
            errors.append(
                f"{location}: safety {safety!r} must be one of "
                f"{sorted(VALID_SAFETY_LEVELS)}."
            )

        for key in ("partyEnergy", "ambiguity", "imageSuitability"):
            value = entry.get(key)
            if not isinstance(value, int) or not 1 <= value <= 5:
                errors.append(f"{location}: {key} must be an integer from 1 to 5.")

        errors.extend(validate_tags(entry.get("tags"), location))

    missing_categories = expected_categories - seen_categories
    if missing_categories:
        errors.append(f"{path.name}: missing metadata for {sorted(missing_categories)}.")

    return errors


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Validate Imposter bundled word packs."
    )
    parser.add_argument(
        "root",
        nargs="?",
        type=Path,
        default=Path("Imposter/Resources/WordPacks"),
        help="Directory containing words_*.json files.",
    )
    parser.add_argument(
        "--min-words-per-pack",
        type=int,
        default=100,
        help="Minimum number of words required in each pack.",
    )
    args = parser.parse_args()

    errors, summary = validate_all(args.root, args.min_words_per_pack)

    print("Word pack integrity")
    print(f"Root: {args.root}")
    print(f"Expected packs: {summary['expected_packs']}")
    print(f"Total words: {summary['total_words']}")
    print(f"Unique words: {summary['unique_words']}")
    print(f"Duplicate normalized words: {summary['duplicates']}")
    print(f"Metadata categories: {summary['metadata_categories']}")
    print(f"Schema IDs: {summary['schema_ids']}")
    print(f"Localization keys: {summary['localization_keys']}")
    print(f"Curated tag priority keys: {summary['curated_tag_priority_keys']}")
    print(f"Semantic tag checked words: {summary['semantic_tag_checked_words']}")
    print(f"Minimum words per pack: {args.min_words_per_pack}")

    if errors:
        print("Word pack check failed:", file=sys.stderr)
        for error in errors:
            print(f"- {error}", file=sys.stderr)
        return 1

    print("PASS: word packs are structurally sound.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
