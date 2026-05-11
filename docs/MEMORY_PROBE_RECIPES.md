# Imposter Memory Probe Recipes

This guide is the operator-facing companion to `scripts/probe_ui_memory.py`.
Use it when collecting simulator RSS and `footprint` evidence for the Imposter
UI flows.

## Source Of Truth

- Use `scripts/probe_ui_memory.py --help` as the CLI contract.
- Use manifests from `--manifest-output` for comparisons, not hand-copied
  summary text.
- Use `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer` when calling
  Xcode tools directly on this Mac.
- Treat simulator RSS as simulator evidence only. It is not a physical-device
  memory claim and it is not an Instruments allocation trace.
- Keep the warm final RSS threshold report-only until repeated final-cadence
  max-player runs agree.

## Reading Footprint Overhead

The `footprint_capture_overhead.source` field matters:

| Source | Meaning | Compare With |
| --- | --- | --- |
| `capture_events` | Every `footprint` subprocess attempt was persisted in `capture_events`. `attempt_count` is the real capture count. | Other `capture_events` rows. |
| `snapshot_index` | Older index without event history. `attempt_count` counts retained labels only. | Backcompat checks only. |
| `n/a` | Older manifest did not record source. Treat attempts as persisted snapshots. | Do not compare as true overhead. |

Do not compare `snapshot_index` or `n/a` overhead against `capture_events`
as if they measure the same thing. Older rows can still compare RSS, gates,
XCTest duration, and alignment fields that existed at the time.

## Final RSS Attribution Policy

Prefer in-run final cadence over post-exit final capture:

- Use `--footprint-final-interval-seconds` for final RSS attribution.
- Pick an interval shorter than the flow segment you are measuring.
- Use `1` second for short launch smokes.
- Use `10` seconds for the current max-player diagnostic unless you are
  specifically investigating final-sample drift.
- Treat `--footprint-capture-final` as experimental. On short launch flows the
  app process can exit before the post-exit `footprint` subprocess runs, which
  leaves the final snapshot failed with return code `66`.
- If `final_vs_final_sample` is missing, check the final snapshot return code
  and the `Footprint capture overhead comparison` failure count before using the
  run as final-RSS evidence.

## Recommended Max-Player Diagnostic

Use this when investigating peak and final RSS in the heaviest current rendered
flow. It captures exact sampled-peak attribution and a final cadence snapshot,
while keeping RSS gates in report mode.

```bash
scripts/probe_ui_memory.py \
  --replace \
  --configuration Release \
  --run-label footprint-final-cadence-release-max-player \
  --simulator-state warm-shutdown-no-erase-before-footprint-final-cadence-max-player \
  --only-testing ImposterUITests/ImposterUITests/testMaximumPlayerRenderedFlowCompletesRound \
  --result-bundle /tmp/imposter-ui-memory-probe-footprint-final-cadence-max.xcresult \
  --output-csv /tmp/imposter-ui-memory-probe-footprint-final-cadence-max.csv \
  --summary-output /tmp/imposter-ui-memory-probe-footprint-final-cadence-max.summary.txt \
  --manifest-output /tmp/imposter-ui-memory-probe-footprint-final-cadence-max.manifest.json \
  --footprint-summary-dir /tmp/imposter-ui-memory-probe-footprint-final-cadence-max-footprint \
  --footprint-peak-min-delta-mb 75 \
  --footprint-capture-sampled-peak \
  --footprint-latest-interval-seconds 30 \
  --footprint-final-interval-seconds 10 \
  --interval 1.0 \
  --warm-rss-floor-mb 100 \
  --max-warm-peak-rss-mb 380 \
  --max-warm-final-rss-mb 340 \
  --rss-gate-mode report
```

Expected artifact contract:

- CSV exists and has at least one data row.
- Summary includes `footprint capture overhead`.
- Manifest includes `footprint_capture_overhead.source: "capture_events"`.
- Manifest includes `sampled_peak_vs_sampled_peak`.
- Manifest includes `final_vs_final_sample`.
- `footprint-index.json` includes both `capture_events` and `snapshots`.
- The `.xcresult` summary reports the focused UI test as passed before the
  memory numbers are used as product evidence.

## Fast Launch Smoke

Use this after changing probe accounting or manifest shape. It is intentionally
short and can use a tight final cadence to exercise capture-event bookkeeping.

```bash
scripts/probe_ui_memory.py \
  --replace \
  --configuration Release \
  --run-label footprint-final-cadence-launch-smoke \
  --simulator-state warm-shutdown-no-erase-before-footprint-final-cadence-smoke \
  --only-testing ImposterUITests/ImposterUITests/testLaunchShowsHomeScreen \
  --result-bundle /tmp/imposter-ui-memory-probe-footprint-final-cadence-smoke.xcresult \
  --output-csv /tmp/imposter-ui-memory-probe-footprint-final-cadence-smoke.csv \
  --summary-output /tmp/imposter-ui-memory-probe-footprint-final-cadence-smoke.summary.txt \
  --manifest-output /tmp/imposter-ui-memory-probe-footprint-final-cadence-smoke.manifest.json \
  --footprint-summary-dir /tmp/imposter-ui-memory-probe-footprint-final-cadence-smoke-footprint \
  --footprint-peak-min-delta-mb 25 \
  --footprint-capture-sampled-peak \
  --footprint-latest-interval-seconds 30 \
  --footprint-final-interval-seconds 1 \
  --interval 0.5 \
  --warm-rss-floor-mb 1 \
  --max-warm-peak-rss-mb 380 \
  --max-warm-final-rss-mb 340 \
  --rss-gate-mode report
```

This smoke is useful for script shape, not max-player memory policy. Do not use
its RSS values as evidence for the full game flow.

## Backcompat Reanalysis

Use this for older CSV plus footprint-index artifacts. The output should keep
old runs readable and mark weaker overhead as `snapshot_index`.

```bash
scripts/probe_ui_memory.py \
  --analyze-csv /tmp/imposter-ui-memory-probe-footprint-sampled-peak-overhead-max.csv \
  --result-bundle /tmp/imposter-ui-memory-probe-footprint-sampled-peak-overhead-max.xcresult \
  --run-label footprint-final-cadence-backcompat-reanalysis \
  --simulator-state warm-shutdown-no-erase-before-footprint-sampled-peak-overhead-max-player \
  --configuration Release \
  --only-testing ImposterUITests/ImposterUITests/testMaximumPlayerRenderedFlowCompletesRound \
  --footprint-summary-dir /tmp/imposter-ui-memory-probe-footprint-sampled-peak-overhead-max-footprint \
  --summary-output /tmp/imposter-footprint-final-cadence-backcompat-reanalysis.txt \
  --manifest-output /tmp/imposter-footprint-final-cadence-backcompat-reanalysis.manifest.json \
  --warm-rss-floor-mb 100 \
  --max-warm-peak-rss-mb 380 \
  --max-warm-final-rss-mb 340 \
  --rss-gate-mode report
```

## Structured Comparison

Prefer manifest comparison because it carries run labels, simulator notes,
threshold policy, alignment, overhead source, and XCTest result paths.

```bash
scripts/probe_ui_memory.py \
  --compare-manifest \
  /tmp/imposter-ui-memory-probe-footprint-final-cadence-max.manifest.json \
  /tmp/imposter-ui-memory-probe-footprint-final-cadence-smoke.manifest.json \
  /tmp/imposter-ui-memory-probe-footprint-sampled-peak-overhead-max.manifest.json \
  /tmp/imposter-ui-memory-probe-footprint-overhead-smoke.manifest.json \
  /tmp/imposter-footprint-final-cadence-backcompat-reanalysis.manifest.json \
  --run-label footprint-final-cadence-comparison \
  --summary-output /tmp/imposter-footprint-final-cadence-comparison.txt
```

Review these comparison tables before writing a ledger entry:

- `RSS gate comparison`
- `Footprint alignment comparison`
- `Footprint capture overhead comparison`
- `XCTest result comparison`

## Interpreting Alignment

- `sampled_peak_vs_sampled_peak`: should be `+0.000 MB`, `+0.000s` when
  `--footprint-capture-sampled-peak` is working.
- `peak_vs_sampled_peak`: shows whether the delta-based persisted `peak`
  snapshot drifted from the true sampled peak.
- `latest_vs_final_sample`: useful for coarse late-run attribution, but can be
  stale when the latest interval is large.
- `final_vs_final_sample`: use this for final RSS attribution when
  `--footprint-final-interval-seconds` or `--footprint-capture-final` is active.

## Ledger Checklist

Every memory-probe ledger entry should include:

- Exact command.
- Exit code.
- CSV, summary, manifest, and footprint index paths plus line counts.
- `Samples`, PID set, first/peak/final RSS.
- Warm peak and warm final gate status.
- `footprint_capture_overhead.source`, attempts, persisted snapshots, total,
  mean, and max duration.
- Peak, sampled-peak, latest, and final alignment where present.
- `.xcresult` summary and focused test duration.
- Remaining risk that keeps simulator RSS distinct from physical-device memory
  and allocation-family evidence.
