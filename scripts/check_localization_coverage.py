#!/usr/bin/env python3
"""Check focused localization coverage for Imposter's string catalog."""

from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path


DEFAULT_LOCALES = ("de", "es", "fr", "ja")

ROLE_PRIVACY_PRIORITY_KEYS = (
    "Hold to Reveal",
    "Hold to Reveal My Role",
    "Keep Holding...",
    "Player's turn to reveal their role",
    "Press and hold to see your secret role",
    "Private - Hand device to next player",
    "Role Reveal",
    "The secret word is %@. You are not the Imposter.",
    "This is a private screen. Please hand the device to the next player before revealing.",
    "You are the Imposter! Your hint is: %@.",
)

PHASE_CRITICAL_PRIORITY_KEYS = (
    "%@'s turn to give a clue.",
    "%@'s turn to vote.",
    "%lld Players",
    "Add Players",
    "Add at least %lld players",
    "Add at least %lld players to start",
    "Back",
    "Cancel",
    "Choose Word Source",
    "Choose Words",
    "Clear",
    "Clue round. Each player gives a clue about the secret word.",
    "Continue",
    "Custom",
    "Enter a Theme",
    "Enter a theme to continue",
    "Difficulty",
    "Discuss who you think is the Imposter. Don't reveal your clues or the secret word!",
    "Discussion Timer",
    "Discussion phase. Discuss who you think is the imposter.",
    "Done",
    "Game Mode",
    "Game Settings",
    "Next",
    "Pick Categories",
    "Player Color",
    "Player Name",
    "Random",
    "Reveal phase. The imposter will be revealed.",
    "Save",
    "Setup phase. Add players and configure game settings.",
    "Slide to Discuss",
    "Slide to start discussion",
    "Vote for %@",
    "Voting phase. Each player votes for who they think is the imposter.",
    "Word Source",
)

PILOT_WORD_PRIORITY_KEYS = (
    "word.animals.dog",
    "word.animals.cat",
    "word.animals.bird",
    "word.animals.fish",
    "word.animals.horse",
    "word.objects.chair",
    "word.objects.table",
    "word.objects.bed",
    "word.objects.pillow",
    "word.objects.blanket",
    "word.people.taylor-swift",
    "word.people.beyonce",
    "word.people.bad-bunny",
    "word.people.drake",
    "word.people.rihanna",
    "word.movies.wicked",
    "word.movies.moana",
    "word.movies.deadpool",
    "word.movies.inside-out",
    "word.movies.despicable-me",
    "word.technology.iphone-16",
    "word.technology.apple-vision-pro",
    "word.technology.airpods",
    "word.technology.macbook",
    "word.technology.ipad",
)

MEDIUM_WORD_PRIORITY_KEYS = (
    "word.animals.owl",
    "word.animals.eagle",
    "word.animals.hawk",
    "word.animals.parrot",
    "word.animals.peacock",
    "word.objects.couch",
    "word.objects.drawer",
    "word.objects.shelf",
    "word.objects.wardrobe",
    "word.objects.rug",
    "word.people.sza",
    "word.people.tyler-the-creator",
    "word.people.lana-del-rey",
    "word.people.hozier",
    "word.people.benson-boone",
    "word.movies.chainsaw-man",
    "word.movies.dandadan",
    "word.movies.kaiju-no-8",
    "word.movies.frieren",
    "word.movies.oshi-no-ko",
    "word.technology.marvel-rivals",
    "word.technology.black-myth-wukong",
    "word.technology.palworld",
    "word.technology.helldivers-2",
    "word.technology.baldur-s-gate-3",
)

HARD_WORD_PRIORITY_KEYS = (
    "word.animals.platypus",
    "word.animals.armadillo",
    "word.animals.anteater",
    "word.animals.sloth",
    "word.animals.tapir",
    "word.objects.chandelier",
    "word.objects.armoire",
    "word.objects.ottoman",
    "word.objects.credenza",
    "word.objects.chaise-lounge",
    "word.people.michael-jackson",
    "word.people.prince",
    "word.people.freddie-mercury",
    "word.people.david-bowie",
    "word.people.whitney-houston",
    "word.movies.neon-genesis-evangelion",
    "word.movies.cowboy-bebop",
    "word.movies.spirited-away",
    "word.movies.princess-mononoke",
    "word.movies.akira",
    "word.technology.dark-souls",
    "word.technology.red-dead-redemption",
    "word.technology.cyberpunk-2077",
    "word.technology.the-witcher-3",
    "word.technology.world-of-warcraft",
)

WORD_PRIORITY_KEYS = (
    PILOT_WORD_PRIORITY_KEYS
    + MEDIUM_WORD_PRIORITY_KEYS
    + HARD_WORD_PRIORITY_KEYS
)

PRIORITY_KEYS = (
    ROLE_PRIVACY_PRIORITY_KEYS
    + PHASE_CRITICAL_PRIORITY_KEYS
    + WORD_PRIORITY_KEYS
)


PLACEHOLDER_PATTERN = re.compile(
    r"%(?:(?P<position>\d+)\$)?(?P<kind>@|lld|ld|d|f|s)"
)


def load_catalog(path: Path) -> dict:
    with path.open(encoding="utf-8") as file:
        return json.load(file)


def load_word_pack_source_values(root: Path) -> tuple[dict[str, str], list[str]]:
    source_values: dict[str, str] = {}
    errors: list[str] = []

    if not root.exists():
        return source_values, [f"Word pack root is missing: {root}"]

    for path in sorted(root.glob("words_*.json")):
        try:
            with path.open(encoding="utf-8") as file:
                pack = json.load(file)
        except json.JSONDecodeError as error:
            errors.append(f"{path}: invalid JSON: {error}")
            continue

        if not isinstance(pack, dict):
            errors.append(f"{path}: expected a JSON object.")
            continue

        words = pack.get("words")
        if not isinstance(words, list):
            errors.append(f"{path}: words must be a list.")
            continue

        for index, entry in enumerate(words):
            location = f"{path.name}: words[{index}]"
            if not isinstance(entry, dict):
                errors.append(f"{location}: expected an object.")
                continue

            localization_key = entry.get("localizationKey")
            display_text = entry.get("displayText")
            if not isinstance(localization_key, str) or not localization_key:
                continue
            if not isinstance(display_text, str) or not display_text:
                continue
            if localization_key in source_values:
                errors.append(f"{location}: duplicate localizationKey {localization_key!r}.")
                continue

            source_values[localization_key] = display_text

    return source_values, errors


def localized_value(entry: dict, locale: str) -> str | None:
    value = (
        entry.get("localizations", {})
        .get(locale, {})
        .get("stringUnit", {})
        .get("value")
    )
    return value if isinstance(value, str) and value else None


def placeholder_kinds(value: str) -> tuple[str, ...]:
    return tuple(match.group("kind") for match in PLACEHOLDER_PATTERN.finditer(value))


def coverage_count(strings: dict, locale: str) -> int:
    return sum(1 for entry in strings.values() if localized_value(entry, locale))


def check_pilot_word_pack_alignment(
    strings: dict,
    word_pack_root: Path,
) -> tuple[list[str], int]:
    errors: list[str] = []
    source_values, word_pack_errors = load_word_pack_source_values(word_pack_root)
    errors.extend(word_pack_errors)

    pilot_word_pack_matches = 0
    for key in WORD_PRIORITY_KEYS:
        source_value = source_values.get(key)
        if source_value is None:
            errors.append(f"Word priority key is missing from word packs: {key}")
            continue

        pilot_word_pack_matches += 1
        entry = strings.get(key)
        if not isinstance(entry, dict):
            continue

        english_value = localized_value(entry, "en")
        if english_value is None:
            errors.append(f"en is missing pilot word source localization: {key}")
        elif english_value != source_value:
            errors.append(
                f"en source mismatch for {key!r}: expected {source_value!r}, "
                f"got {english_value!r}."
            )

    return errors, pilot_word_pack_matches


def check_catalog(
    catalog: dict,
    locales: tuple[str, ...],
    min_translated_per_locale: int,
    word_pack_root: Path,
) -> list[str]:
    errors: list[str] = []
    strings = catalog.get("strings", {})
    if not isinstance(strings, dict):
        return ["Catalog is missing a strings dictionary."]

    source_language = catalog.get("sourceLanguage")
    if source_language != "en":
        errors.append(f"Expected sourceLanguage 'en', got {source_language!r}.")

    for locale in locales:
        translated = coverage_count(strings, locale)
        if translated < min_translated_per_locale:
            errors.append(
                f"{locale} has {translated} translated strings; expected at least "
                f"{min_translated_per_locale}."
            )

    for key in PRIORITY_KEYS:
        entry = strings.get(key)
        if not isinstance(entry, dict):
            errors.append(f"Priority key is missing: {key}")
            continue

        source_placeholders = placeholder_kinds(key)
        for locale in locales:
            value = localized_value(entry, locale)
            if value is None:
                errors.append(f"{locale} is missing priority localization: {key}")
                continue

            translated_placeholders = placeholder_kinds(value)
            if translated_placeholders != source_placeholders:
                errors.append(
                    f"{locale} placeholder mismatch for {key!r}: "
                    f"expected {source_placeholders}, got {translated_placeholders}."
                )

    for key, entry in strings.items():
        if not isinstance(entry, dict):
            errors.append(f"String entry is not an object: {key}")
            continue

        source_placeholders = placeholder_kinds(key)
        for locale in locales:
            value = localized_value(entry, locale)
            if value is None:
                continue

            translated_placeholders = placeholder_kinds(value)
            if translated_placeholders != source_placeholders:
                errors.append(
                    f"{locale} placeholder mismatch for {key!r}: "
                    f"expected {source_placeholders}, got {translated_placeholders}."
                )

    word_pack_errors, _ = check_pilot_word_pack_alignment(strings, word_pack_root)
    errors.extend(word_pack_errors)

    return errors


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Validate focused localization coverage for Localizable.xcstrings."
    )
    parser.add_argument(
        "catalog",
        nargs="?",
        type=Path,
        default=Path("Imposter/Resources/Localizable.xcstrings"),
    )
    parser.add_argument(
        "--locale",
        action="append",
        dest="locales",
        help="Locale to require. Repeatable. Defaults to de/es/fr/ja.",
    )
    parser.add_argument(
        "--min-translated-per-locale",
        type=int,
        default=375,
        help="Minimum translated string count required for each target locale.",
    )
    parser.add_argument(
        "--word-pack-root",
        type=Path,
        default=Path("Imposter/Resources/WordPacks"),
        help="Directory containing words_*.json files for pilot key alignment.",
    )
    args = parser.parse_args()

    locales = tuple(args.locales or DEFAULT_LOCALES)
    catalog = load_catalog(args.catalog)
    strings = catalog.get("strings", {})
    errors = check_catalog(
        catalog,
        locales,
        args.min_translated_per_locale,
        args.word_pack_root,
    )
    pilot_word_pack_matches = (
        check_pilot_word_pack_alignment(strings, args.word_pack_root)[1]
        if isinstance(strings, dict)
        else 0
    )

    print("Localization coverage")
    print(f"Catalog: {args.catalog}")
    print(f"Source language: {catalog.get('sourceLanguage')}")
    print(f"Total strings: {len(strings) if isinstance(strings, dict) else 'n/a'}")
    print(f"Priority keys: {len(PRIORITY_KEYS)}")
    print(
        f"Word priority keys in word packs: "
        f"{pilot_word_pack_matches}/{len(WORD_PRIORITY_KEYS)}"
    )
    for locale in locales:
        translated = coverage_count(strings, locale) if isinstance(strings, dict) else 0
        print(f"{locale}: {translated} translated strings")

    if errors:
        print("Localization coverage check failed:", file=sys.stderr)
        for error in errors:
            print(f"- {error}", file=sys.stderr)
        return 1

    print("PASS: focused localization coverage is acceptable.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
