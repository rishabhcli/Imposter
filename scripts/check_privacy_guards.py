#!/usr/bin/env python3
"""Check source-level pass-and-play privacy guards."""

from __future__ import annotations

import argparse
import sys
from pathlib import Path


ROLE_REVEAL_PATH = Path("Imposter/Features/RoleReveal/RoleRevealView.swift")
ROLE_CARD_PATH = Path("Imposter/Features/RoleReveal/RoleCardView.swift")

ROLE_STAGE_FORBIDDEN_TOKENS = (
    "secretWord",
    "imposterHint",
    "imposterWord",
    "roleForCurrentPlayer",
    "isCurrentPlayerImposter",
    ".imposter",
    ".hiddenImposter",
    "RoleCardView",
)


def read_text(path: Path) -> str:
    try:
        return path.read_text(encoding="utf-8")
    except FileNotFoundError:
        return ""


def extract_braced_block(source: str, signature: str) -> str | None:
    start = source.find(signature)
    if start < 0:
        return None

    brace_start = source.find("{", start)
    if brace_start < 0:
        return None

    depth = 0
    for index in range(brace_start, len(source)):
        character = source[index]
        if character == "{":
            depth += 1
        elif character == "}":
            depth -= 1
            if depth == 0:
                return source[brace_start + 1 : index]

    return None


def contains_all(source: str, needles: tuple[str, ...]) -> bool:
    return all(needle in source for needle in needles)


def check_role_stage(role_reveal: str) -> tuple[list[str], dict[str, bool]]:
    errors: list[str] = []
    status: dict[str, bool] = {}

    title = extract_braced_block(role_reveal, "private var roleStageTitle")
    subtitle = extract_braced_block(role_reveal, "private var roleStageSubtitle")
    icon = extract_braced_block(role_reveal, "private var roleStageIcon")

    for name, block in (
        ("roleStageTitle", title),
        ("roleStageSubtitle", subtitle),
        ("roleStageIcon", icon),
    ):
        if block is None:
            errors.append(f"Missing Role Reveal stage block: {name}.")
            continue

        forbidden = [token for token in ROLE_STAGE_FORBIDDEN_TOKENS if token in block]
        if forbidden:
            errors.append(
                f"{name} references secret role/word state: {', '.join(forbidden)}."
            )

    status["stage_blocks_present"] = all(block is not None for block in (title, subtitle, icon))
    status["stage_header_avoids_secret_state"] = not any(
        block is not None and any(token in block for token in ROLE_STAGE_FORBIDDEN_TOKENS)
        for block in (title, subtitle, icon)
    )

    if title is not None:
        has_voiceover_branch = "if voiceOverRunning" in title
        generic_before_name = (
            title.find("voiceOverRunning") >= 0
            and title.find("currentPlayer.name") >= 0
            and title.find("voiceOverRunning") < title.find("currentPlayer.name")
        )
        if not has_voiceover_branch:
            errors.append("roleStageTitle must keep a generic VoiceOver branch.")
        if not generic_before_name:
            errors.append(
                "roleStageTitle must check VoiceOver before constructing the visual player-name title."
            )
        status["stage_voiceover_generic_title"] = has_voiceover_branch and generic_before_name
    else:
        status["stage_voiceover_generic_title"] = False

    return errors, status


def check_handoff_privacy(role_reveal: str) -> tuple[list[str], dict[str, bool]]:
    errors: list[str] = []
    status: dict[str, bool] = {}
    pass_prompt = extract_braced_block(role_reveal, "private var passDevicePrompt")

    if pass_prompt is None:
        errors.append("Missing passDevicePrompt.")
        return errors, {"handoff_prompt_present": False}

    checks = {
        "handoff_prompt_present": True,
        "player_name_hidden_from_voiceover": ".accessibilityHidden(voiceOverRunning)" in pass_prompt,
        "handoff_voiceover_label_is_generic": "accessibilityLabel(voiceOverRunning ?" in pass_prompt,
        "role_reveal_requires_hold_button": "HoldToRevealButton(" in pass_prompt,
        "private_voiceover_indicator": "Private - Hand device to next player" in pass_prompt,
    }
    status.update(checks)

    for name, passed in checks.items():
        if not passed:
            errors.append(f"Role Reveal handoff privacy check failed: {name}.")

    if "Color.clear" not in role_reveal or "isTransitioning" not in role_reveal:
        errors.append("Role Reveal must keep a blank transition state between players.")
        status["blank_transition_between_players"] = False
    else:
        status["blank_transition_between_players"] = True

    return errors, status


def check_role_card_privacy(role_card: str) -> tuple[list[str], dict[str, bool]]:
    errors: list[str] = []
    status: dict[str, bool] = {}

    checks = {
        "card_content_hidden_from_voiceover": contains_all(
            role_card,
            (
                "cardContent",
                ".accessibilityHidden(true)",
                "privateRoleCardAccessibilityLabel",
            ),
        ),
        "sensitive_text_privacy_marked": role_card.count(".privacySensitive()") >= 3,
        "sensitive_text_speech_hidden": role_card.count('accessibilityLabel("Sensitive') >= 3,
        "private_card_accessibility_hint": "Sensitive role details are shown visually and hidden from spoken feedback" in role_card,
        "hidden_imposter_title_masked": 'case .hiddenImposter: return "INFORMED"' in role_card,
        "hidden_imposter_color_masked": "case .hiddenImposter: return LGColors.success" in role_card,
    }
    status.update(checks)

    for name, passed in checks.items():
        if not passed:
            errors.append(f"Role card privacy check failed: {name}.")

    return errors, status


def print_status(status: dict[str, bool]) -> None:
    print("Pass-and-play privacy guards")
    for name, passed in status.items():
        marker = "yes" if passed else "no"
        print(f"- {name}: {marker}")


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--role-reveal",
        type=Path,
        default=ROLE_REVEAL_PATH,
        help="Path to RoleRevealView.swift.",
    )
    parser.add_argument(
        "--role-card",
        type=Path,
        default=ROLE_CARD_PATH,
        help="Path to RoleCardView.swift.",
    )
    args = parser.parse_args()

    role_reveal = read_text(args.role_reveal)
    role_card = read_text(args.role_card)
    errors: list[str] = []
    status: dict[str, bool] = {}

    if not role_reveal:
        errors.append(f"Missing or empty Role Reveal file: {args.role_reveal}")
    if not role_card:
        errors.append(f"Missing or empty Role Card file: {args.role_card}")

    stage_errors, stage_status = check_role_stage(role_reveal)
    handoff_errors, handoff_status = check_handoff_privacy(role_reveal)
    card_errors, card_status = check_role_card_privacy(role_card)
    errors.extend(stage_errors)
    errors.extend(handoff_errors)
    errors.extend(card_errors)
    status.update(stage_status)
    status.update(handoff_status)
    status.update(card_status)

    print_status(status)

    if errors:
        print("Privacy guard check failed:", file=sys.stderr)
        for error in errors:
            print(f"- {error}", file=sys.stderr)
        return 1

    print("PASS: pass-and-play privacy guards are intact.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
