#!/usr/bin/env bash
set -euo pipefail

python3 -m json.tool Imposter/Resources/Localizable.xcstrings >/tmp/imposter-localizable-json-check.json
python3 -m py_compile \
  scripts/check_localization_coverage.py \
  scripts/check_word_packs.py \
  scripts/check_decoy_quality.py \
  scripts/check_privacy_guards.py \
  scripts/report_frontier_status.py \
  scripts/check_launch_metric.py \
  scripts/probe_ui_memory.py

scripts/check_localization_coverage.py
scripts/check_word_packs.py
scripts/check_decoy_quality.py
scripts/check_privacy_guards.py
scripts/report_frontier_status.py --check
