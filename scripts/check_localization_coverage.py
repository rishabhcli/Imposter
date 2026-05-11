#!/usr/bin/env python3
"""Check focused localization coverage for Imposter's string catalog."""

from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path


DEFAULT_LOCALES = ("de", "es", "fr", "ja")

PRIORITY_KEYS = (
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


PLACEHOLDER_PATTERN = re.compile(
    r"%(?:(?P<position>\d+)\$)?(?P<kind>@|lld|ld|d|f|s)"
)


def load_catalog(path: Path) -> dict:
    with path.open(encoding="utf-8") as file:
        return json.load(file)


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


def check_catalog(
    catalog: dict,
    locales: tuple[str, ...],
    min_translated_per_locale: int,
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
        default=40,
        help="Minimum translated string count required for each target locale.",
    )
    args = parser.parse_args()

    locales = tuple(args.locales or DEFAULT_LOCALES)
    catalog = load_catalog(args.catalog)
    strings = catalog.get("strings", {})
    errors = check_catalog(catalog, locales, args.min_translated_per_locale)

    print("Localization coverage")
    print(f"Catalog: {args.catalog}")
    print(f"Source language: {catalog.get('sourceLanguage')}")
    print(f"Total strings: {len(strings) if isinstance(strings, dict) else 'n/a'}")
    print(f"Priority keys: {len(PRIORITY_KEYS)}")
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
