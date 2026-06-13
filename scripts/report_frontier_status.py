#!/usr/bin/env python3
"""Report high-level frontier coverage for Imposter's current product slices."""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path
from typing import Any


PHASE_VIEWS = {
    "Role Reveal": Path("Imposter/Features/RoleReveal/RoleRevealView.swift"),
    "Clue Round": Path("Imposter/Features/ClueRound/ClueRoundView.swift"),
    "Discussion": Path("Imposter/Features/Discussion/DiscussionView.swift"),
    "Voting": Path("Imposter/Features/Voting/VotingView.swift"),
    "Reveal": Path("Imposter/Features/Reveal/RevealView.swift"),
    "Summary": Path("Imposter/Features/Summary/SummaryView.swift"),
}

REQUIRED_FILES = {
    "GameRules": Path("Imposter/Domain/Logic/GameRules.swift"),
    "GeneratedWordPolicy": Path("Imposter/Domain/Logic/GeneratedWordPolicy.swift"),
    "DecoyQualityChecker": Path("scripts/check_decoy_quality.py"),
    "PrivacyGuardChecker": Path("scripts/check_privacy_guards.py"),
}

CATALOG_PATH = Path("Imposter/Resources/Localizable.xcstrings")
WORD_PACK_ROOT = Path("Imposter/Resources/WordPacks")
TARGET_LOCALES = ("de", "es", "fr", "ja")
MIN_LOCALIZED_WORD_ENTRIES = 200
MIN_PHASE_STAGE_ADOPTION = 6


def read_text(path: Path) -> str:
    try:
        return path.read_text(encoding="utf-8")
    except FileNotFoundError:
        return ""


def stage_adoption() -> dict[str, bool]:
    return {
        name: "LGPhaseStage(" in read_text(path)
        for name, path in PHASE_VIEWS.items()
    }


def required_file_status() -> dict[str, bool]:
    return {name: path.exists() for name, path in REQUIRED_FILES.items()}


def source_contains(path: Path, needle: str) -> bool:
    return needle in read_text(path)


def product_guards() -> dict[str, bool]:
    return {
        "Rule summary model": source_contains(
            Path("Imposter/Domain/Logic/GameRules.swift"),
            "struct RuleSummary",
        ),
        "Rule validation": source_contains(
            Path("Imposter/Domain/Logic/GameRules.swift"),
            "static func validation",
        ),
        "Setup rule summary UI": source_contains(
            Path("Imposter/Features/Setup/PlayerSetupView.swift"),
            "ruleSummarySection",
        ),
        "Generated word policy": source_contains(
            Path("Imposter/Domain/Logic/GeneratedWordPolicy.swift"),
            "enum GeneratedWordPolicy",
        ),
        "Custom hidden decoy path": source_contains(
            Path("Imposter/Store/GameStore.swift"),
            "generatedImposterWordIfNeeded",
        ),
        "Decoy quality gate": source_contains(
            Path("scripts/verify_content.sh"),
            "scripts/check_decoy_quality.py",
        ),
        "Gyro card reduce-motion guard": source_contains(
            Path("Imposter/DesignSystem/LiquidGlass/LGComponents/LGCard.swift"),
            "private var motionPitch: Double",
        )
        and source_contains(
            Path("Imposter/DesignSystem/LiquidGlass/LGComponents/LGCard.swift"),
            "accessibilityPreferences.forceReduceMotion",
        ),
        "Gyro shimmer reduce-motion guard": source_contains(
            Path("Imposter/DesignSystem/Effects/GyroShimmerEffect.swift"),
            "private var motionPitch: Double",
        )
        and source_contains(
            Path("Imposter/DesignSystem/Effects/GyroShimmerEffect.swift"),
            "accessibilityPreferences.forceReduceMotion",
        ),
        "Image loading reduce-motion guard": source_contains(
            Path("Imposter/Features/RoleReveal/RoleCardView.swift"),
            "symbolEffect(.pulse.wholeSymbol, options: .repeating, isActive: !reduceMotion)",
        )
        and source_contains(
            Path("Imposter/Features/RoleReveal/RoleCardView.swift"),
            "guard !reduceMotion else",
        ),
        "Home starfield reduce-motion guard": source_contains(
            Path("Imposter/Features/Home/HomeView.swift"),
            "guard !reduceMotion else",
        )
        and source_contains(
            Path("Imposter/Features/Home/HomeView.swift"),
            "systemReduceMotion || accessibilityPreferences.forceReduceMotion",
        ),
        "Discussion timer reduce-motion guard": source_contains(
            Path("Imposter/Features/Discussion/DiscussionView.swift"),
            "shouldPulse",
        )
        and source_contains(
            Path("Imposter/Features/Discussion/DiscussionView.swift"),
            "systemReduceMotion || accessibilityPreferences.forceReduceMotion",
        ),
        "Role reveal private stage guard": source_contains(
            Path("Imposter/Features/RoleReveal/RoleRevealView.swift"),
            "LGPhaseStage(",
        )
        and source_contains(
            Path("Imposter/Features/RoleReveal/RoleRevealView.swift"),
            "voiceOverRunning",
        )
        and source_contains(
            Path("Imposter/Features/RoleReveal/RoleRevealView.swift"),
            "accessibilityHidden(voiceOverRunning)",
        ),
        "Privacy guard gate": source_contains(
            Path("scripts/verify_content.sh"),
            "scripts/check_privacy_guards.py",
        ),
    }


def load_json(path: Path) -> tuple[Any | None, str | None]:
    try:
        with path.open(encoding="utf-8") as file:
            return json.load(file), None
    except FileNotFoundError:
        return None, f"Missing JSON file: {path}"
    except json.JSONDecodeError as error:
        return None, f"Invalid JSON in {path}: {error}"


def localized_value(entry: dict[str, Any], locale: str) -> str | None:
    value = (
        entry.get("localizations", {})
        .get(locale, {})
        .get("stringUnit", {})
        .get("value")
    )
    return value if isinstance(value, str) and value else None


def load_word_pack_source_values(root: Path) -> tuple[dict[str, tuple[str, str]], list[str]]:
    source_values: dict[str, tuple[str, str]] = {}
    errors: list[str] = []

    if not root.exists():
        return source_values, [f"Word pack root is missing: {root}"]

    for path in sorted(root.glob("words_*.json")):
        pack, error = load_json(path)
        if error is not None:
            errors.append(error)
            continue

        if not isinstance(pack, dict):
            errors.append(f"{path}: expected a JSON object.")
            continue

        words = pack.get("words")
        if not isinstance(words, list):
            errors.append(f"{path}: words must be a list.")
            continue

        for index, entry in enumerate(words):
            if not isinstance(entry, dict):
                continue

            localization_key = entry.get("localizationKey")
            display_text = entry.get("displayText")
            category = entry.get("category")
            location = f"{path.name}: words[{index}]"
            if not isinstance(localization_key, str) or not localization_key:
                continue
            if not isinstance(display_text, str) or not display_text:
                continue
            if localization_key in source_values:
                errors.append(f"{location}: duplicate localizationKey {localization_key!r}.")
                continue

            category_name = category if isinstance(category, str) and category else "Unknown"
            source_values[localization_key] = (display_text, category_name)

    return source_values, errors


def localized_word_pack_coverage() -> dict[str, Any]:
    errors: list[str] = []
    catalog, error = load_json(CATALOG_PATH)
    if error is not None:
        errors.append(error)

    strings: dict[str, Any] = {}
    if isinstance(catalog, dict):
        raw_strings = catalog.get("strings", {})
        if isinstance(raw_strings, dict):
            strings = raw_strings
        else:
            errors.append(f"{CATALOG_PATH}: strings must be a dictionary.")

    source_values, word_pack_errors = load_word_pack_source_values(WORD_PACK_ROOT)
    errors.extend(word_pack_errors)

    localized_count = 0
    by_category: dict[str, dict[str, int]] = {}
    for key, (source_value, category) in source_values.items():
        category_counts = by_category.setdefault(category, {"localized": 0, "total": 0})
        category_counts["total"] += 1

        entry = strings.get(key)
        if not isinstance(entry, dict):
            continue

        has_source = localized_value(entry, "en") == source_value
        has_targets = all(localized_value(entry, locale) for locale in TARGET_LOCALES)
        if has_source and has_targets:
            localized_count += 1
            category_counts["localized"] += 1

    return {
        "localized": localized_count,
        "total": len(source_values),
        "by_category": by_category,
        "errors": errors,
    }


def print_status(
    stage: dict[str, bool],
    files: dict[str, bool],
    guards: dict[str, bool],
    word_localization: dict[str, Any],
) -> None:
    adopted = sum(stage.values())
    total = len(stage)

    print("Frontier status")
    print(f"Phase-stage adoption: {adopted}/{total}")
    for name, is_adopted in stage.items():
        marker = "yes" if is_adopted else "no"
        print(f"- {name}: {marker}")

    print("Required frontier files")
    for name, exists in files.items():
        marker = "yes" if exists else "no"
        print(f"- {name}: {marker}")

    print("Product guards")
    for name, exists in guards.items():
        marker = "yes" if exists else "no"
        print(f"- {name}: {marker}")

    print("Word-pack localization")
    localized = word_localization["localized"]
    word_total = word_localization["total"]
    print(
        f"Localized word entries: {localized}/{word_total} "
        f"(floor {MIN_LOCALIZED_WORD_ENTRIES})"
    )
    for category, counts in sorted(word_localization["by_category"].items()):
        print(f"- {category}: {counts['localized']}/{counts['total']}")
    for error in word_localization["errors"]:
        print(f"- error: {error}")


def check_status(
    stage: dict[str, bool],
    files: dict[str, bool],
    guards: dict[str, bool],
    word_localization: dict[str, Any],
) -> list[str]:
    errors: list[str] = []
    adopted = sum(stage.values())

    if adopted < MIN_PHASE_STAGE_ADOPTION:
        errors.append(
            f"Expected at least {MIN_PHASE_STAGE_ADOPTION} phase views to use "
            f"LGPhaseStage; found {adopted}."
        )

    for name, exists in files.items():
        if not exists:
            errors.append(f"Missing required frontier file: {name}.")

    for name, exists in guards.items():
        if not exists:
            errors.append(f"Missing product guard: {name}.")

    for error in word_localization["errors"]:
        errors.append(error)

    localized = word_localization["localized"]
    if localized < MIN_LOCALIZED_WORD_ENTRIES:
        errors.append(
            f"Expected at least {MIN_LOCALIZED_WORD_ENTRIES} localized word-pack "
            f"entries; found {localized}."
        )

    return errors


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--check",
        action="store_true",
        help="Fail if current frontier coverage drops below the accepted floor.",
    )
    args = parser.parse_args()

    stage = stage_adoption()
    files = required_file_status()
    guards = product_guards()
    word_localization = localized_word_pack_coverage()
    print_status(stage, files, guards, word_localization)

    if args.check:
        errors = check_status(stage, files, guards, word_localization)
        if errors:
            print("Frontier status check failed:", file=sys.stderr)
            for error in errors:
                print(f"- {error}", file=sys.stderr)
            return 1

        print("PASS: frontier status coverage is acceptable.")

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
