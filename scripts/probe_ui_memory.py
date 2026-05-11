#!/usr/bin/env python3
"""Run a focused UI test while sampling simulator app RSS on the host."""

from __future__ import annotations

import argparse
import csv
import json
import os
import re
import select
import shutil
import subprocess
import sys
import time
from dataclasses import dataclass
from pathlib import Path


@dataclass(frozen=True)
class Sample:
    elapsed_seconds: float
    pid: int
    rss_mb: float
    command: str


@dataclass(frozen=True)
class RssGate:
    label: str
    actual_mb: float
    threshold_mb: float

    @property
    def passed(self) -> bool:
        return self.actual_mb <= self.threshold_mb


@dataclass(frozen=True)
class SampleStats:
    sample_count: int
    first_elapsed_seconds: float
    last_elapsed_seconds: float
    first_rss_mb: float
    last_rss_mb: float
    min_rss_mb: float
    peak_rss_mb: float
    last_minus_first_mb: float
    peak_minus_first_mb: float
    pids: tuple[int, ...]


@dataclass(frozen=True)
class XcresultStats:
    result: str
    total_tests: int
    passed_tests: int
    failed_tests: int
    skipped_tests: int
    bundle_duration_seconds: float | None
    test_case_count: int
    test_case_duration_seconds: float | None
    device_name: str | None
    xcode_elapsed_seconds: float | None


@dataclass(frozen=True)
class ComparisonMetadata:
    run_label: str | None
    simulator_state: str | None


@dataclass(frozen=True)
class VmmapSnapshot:
    label: str
    elapsed_seconds: float
    pid: int
    rss_mb: float
    path: Path | None
    returncode: int | None
    error: str | None = None


@dataclass(frozen=True)
class FootprintSnapshot:
    label: str
    elapsed_seconds: float
    pid: int
    rss_mb: float
    text_path: Path | None
    json_path: Path | None
    returncode: int | None
    duration_seconds: float | None = None
    error: str | None = None


@dataclass(frozen=True)
class FootprintIndexData:
    snapshots: list[FootprintSnapshot]
    capture_events: list[FootprintSnapshot] | None = None


@dataclass(frozen=True)
class FootprintCategory:
    name: str
    dirty_bytes: int
    clean_bytes: int
    swapped_bytes: int
    regions: int


@dataclass(frozen=True)
class FootprintProcessSummary:
    name: str
    pid: int
    footprint_bytes: int
    phys_footprint_bytes: int | None
    categories: tuple[FootprintCategory, ...]


def ps_rows() -> list[tuple[int, float, str]]:
    completed = subprocess.run(
        ["ps", "-axo", "pid=,rss=,args="],
        check=True,
        text=True,
        capture_output=True,
    )
    rows: list[tuple[int, float, str]] = []

    for line in completed.stdout.splitlines():
        parts = line.strip().split(maxsplit=2)
        if len(parts) < 3:
            continue

        try:
            pid = int(parts[0])
            rss_mb = int(parts[1]) / 1024
        except ValueError:
            continue

        rows.append((pid, rss_mb, parts[2]))

    return rows


def find_app_processes(app_executable: str) -> list[tuple[int, float, str]]:
    app_bundle_fragment = f"/{app_executable}.app/{app_executable}"
    matches: list[tuple[int, float, str]] = []

    for pid, rss_mb, command in ps_rows():
        if app_bundle_fragment not in command:
            continue
        if "UITests" in command or "xctrunner" in command:
            continue
        matches.append((pid, rss_mb, command))

    return matches


def write_samples(output_csv: Path, samples: list[Sample]) -> None:
    output_csv.parent.mkdir(parents=True, exist_ok=True)
    with output_csv.open("w", newline="", encoding="utf-8") as csv_file:
        writer = csv.DictWriter(
            csv_file,
            fieldnames=["elapsed_seconds", "pid", "rss_mb", "command"],
        )
        writer.writeheader()
        for sample in samples:
            writer.writerow(
                {
                    "elapsed_seconds": f"{sample.elapsed_seconds:.3f}",
                    "pid": sample.pid,
                    "rss_mb": f"{sample.rss_mb:.3f}",
                    "command": sample.command,
                }
            )


def read_samples(input_csv: Path) -> list[Sample]:
    with input_csv.open(newline="", encoding="utf-8") as csv_file:
        reader = csv.DictReader(csv_file)
        samples: list[Sample] = []
        for row in reader:
            try:
                samples.append(
                    Sample(
                        elapsed_seconds=float(row["elapsed_seconds"]),
                        pid=int(row["pid"]),
                        rss_mb=float(row["rss_mb"]),
                        command=row["command"],
                    )
                )
            except (KeyError, TypeError, ValueError) as error:
                raise ValueError(f"Invalid RSS CSV row: {row}") from error
        return samples


def rss_summary_lines(title: str, samples: list[Sample]) -> list[str]:
    stats = sample_stats(samples)

    return [
        title,
        f"Samples: {stats.sample_count}",
        f"PIDs: {', '.join(str(pid) for pid in stats.pids)}",
        f"First elapsed: {stats.first_elapsed_seconds:.3f} seconds",
        f"Last elapsed: {stats.last_elapsed_seconds:.3f} seconds",
        f"First RSS: {stats.first_rss_mb:.3f} MB",
        f"Last RSS: {stats.last_rss_mb:.3f} MB",
        f"Min RSS: {stats.min_rss_mb:.3f} MB",
        f"Peak RSS: {stats.peak_rss_mb:.3f} MB",
        f"Last-minus-first RSS: {stats.last_minus_first_mb:.3f} MB",
        f"Peak-minus-first RSS: {stats.peak_minus_first_mb:.3f} MB",
    ]


def sample_stats(samples: list[Sample]) -> SampleStats:
    rss_values = [sample.rss_mb for sample in samples]
    first = samples[0].rss_mb
    last = samples[-1].rss_mb
    peak = max(rss_values)
    minimum = min(rss_values)

    return SampleStats(
        sample_count=len(samples),
        first_elapsed_seconds=samples[0].elapsed_seconds,
        last_elapsed_seconds=samples[-1].elapsed_seconds,
        first_rss_mb=first,
        last_rss_mb=last,
        min_rss_mb=minimum,
        peak_rss_mb=peak,
        last_minus_first_mb=last - first,
        peak_minus_first_mb=peak - first,
        pids=tuple(sorted({sample.pid for sample in samples})),
    )


def warm_samples(
    samples: list[Sample],
    warm_rss_floor_mb: float,
) -> tuple[int, list[Sample]]:
    for index, sample in enumerate(samples):
        if sample.rss_mb >= warm_rss_floor_mb:
            return index, samples[index:]
    return len(samples), []


def summarize(samples: list[Sample], warm_rss_floor_mb: float | None = None) -> str:
    if not samples:
        return "No matching app-process RSS samples were captured."

    lines = rss_summary_lines("UI memory probe summary", samples)

    if warm_rss_floor_mb is not None:
        start_index, warmed_samples = warm_samples(samples, warm_rss_floor_mb)
        lines.append("")
        lines.append(f"Warm-start RSS floor: {warm_rss_floor_mb:.3f} MB")
        if warmed_samples:
            lines.append(
                f"Warm-start sample index: {start_index + 1} of {len(samples)}"
            )
            lines.extend(
                rss_summary_lines("Warm-start memory probe summary", warmed_samples)
            )
        else:
            lines.append("No samples met or exceeded the warm-start RSS floor.")

    return "\n".join(lines)


def validate_gate_args(args: argparse.Namespace) -> str | None:
    has_warm_gate = (
        args.max_warm_peak_rss_mb is not None
        or args.max_warm_final_rss_mb is not None
    )
    if has_warm_gate and args.warm_rss_floor_mb is None:
        return "--warm-rss-floor-mb is required when using warm RSS gates"
    return None


def rss_gates(samples: list[Sample], args: argparse.Namespace) -> list[RssGate]:
    gates: list[RssGate] = []
    if samples and args.max_rss_mb is not None:
        gates.append(
            RssGate(
                label="Raw peak RSS",
                actual_mb=max(sample.rss_mb for sample in samples),
                threshold_mb=args.max_rss_mb,
            )
        )

    if not samples or args.warm_rss_floor_mb is None:
        return gates

    _, warmed_samples = warm_samples(samples, args.warm_rss_floor_mb)
    if not warmed_samples:
        return gates

    if args.max_warm_peak_rss_mb is not None:
        gates.append(
            RssGate(
                label="Warm-start peak RSS",
                actual_mb=max(sample.rss_mb for sample in warmed_samples),
                threshold_mb=args.max_warm_peak_rss_mb,
            )
        )
    if args.max_warm_final_rss_mb is not None:
        gates.append(
            RssGate(
                label="Warm-start final RSS",
                actual_mb=warmed_samples[-1].rss_mb,
                threshold_mb=args.max_warm_final_rss_mb,
            )
        )

    return gates


def gate_summary(samples: list[Sample], args: argparse.Namespace) -> str:
    gates = rss_gates(samples, args)
    has_warm_gate = (
        args.max_warm_peak_rss_mb is not None
        or args.max_warm_final_rss_mb is not None
    )

    if not gates and not has_warm_gate:
        return ""

    lines = [
        "RSS gate summary",
        f"Mode: {args.rss_gate_mode}",
    ]

    if has_warm_gate and args.warm_rss_floor_mb is not None:
        start_index, warmed_samples = warm_samples(samples, args.warm_rss_floor_mb)
        if warmed_samples:
            lines.append(
                f"Warm-start gate sample index: {start_index + 1} of {len(samples)}"
            )
        else:
            lines.append("Warm-start gates skipped: no samples met the RSS floor.")

    for gate in gates:
        status = "PASS" if gate.passed else "FAIL"
        if args.rss_gate_mode == "report" and not gate.passed:
            status = "REPORT-FAIL"
        lines.append(
            f"{gate.label}: {status} "
            f"({gate.actual_mb:.3f} MB <= {gate.threshold_mb:.3f} MB)"
        )

    return "\n".join(lines)


def vmmap_available() -> bool:
    return shutil.which("vmmap") is not None


def footprint_available() -> bool:
    return shutil.which("footprint") is not None


def bytes_to_mb(value: int | float | None) -> float | None:
    if value is None:
        return None
    return float(value) / (1024 * 1024)


def format_mb(value: int | float | None) -> str:
    converted = bytes_to_mb(value)
    if converted is None:
        return "n/a"
    return f"{converted:.3f} MB"


def write_vmmap_snapshot(
    output_dir: Path,
    label: str,
    sample: Sample,
    timeout_seconds: float,
) -> VmmapSnapshot:
    output_dir.mkdir(parents=True, exist_ok=True)
    output_path = output_dir / f"{label}.vmmap-summary.txt"
    command = ["vmmap", "-summary", str(sample.pid)]

    try:
        completed = subprocess.run(
            command,
            text=True,
            capture_output=True,
            timeout=timeout_seconds,
        )
    except (OSError, subprocess.TimeoutExpired) as error:
        output_path.write_text(
            "$ " + " ".join(command) + "\n\n" + str(error) + "\n",
            encoding="utf-8",
        )
        return VmmapSnapshot(
            label=label,
            elapsed_seconds=sample.elapsed_seconds,
            pid=sample.pid,
            rss_mb=sample.rss_mb,
            path=output_path,
            returncode=None,
            error=str(error),
        )

    output_path.write_text(
        "$ " + " ".join(command) + "\n\n" + completed.stdout + completed.stderr,
        encoding="utf-8",
    )

    return VmmapSnapshot(
        label=label,
        elapsed_seconds=sample.elapsed_seconds,
        pid=sample.pid,
        rss_mb=sample.rss_mb,
        path=output_path,
        returncode=completed.returncode,
        error=completed.stderr.strip() if completed.returncode != 0 else None,
    )


def write_vmmap_index(
    output_dir: Path | None,
    snapshots: list[VmmapSnapshot],
) -> Path | None:
    if output_dir is None or not snapshots:
        return None

    output_dir.mkdir(parents=True, exist_ok=True)
    index_path = output_dir / "vmmap-index.json"
    payload = {
        "schema": "imposter.vmmap_summary_index",
        "schema_version": 1,
        "snapshots": [
            {
                "label": snapshot.label,
                "elapsed_seconds": snapshot.elapsed_seconds,
                "pid": snapshot.pid,
                "rss_mb": snapshot.rss_mb,
                "path": artifact_string(snapshot.path),
                "returncode": snapshot.returncode,
                "error": snapshot.error,
            }
            for snapshot in snapshots
        ],
    }
    index_path.write_text(
        json.dumps(payload, indent=2, sort_keys=True) + "\n",
        encoding="utf-8",
    )
    return index_path


def write_footprint_snapshot(
    output_dir: Path,
    label: str,
    sample: Sample,
    timeout_seconds: float,
) -> FootprintSnapshot:
    output_dir.mkdir(parents=True, exist_ok=True)
    text_path = output_dir / f"{label}.footprint-summary.txt"
    json_path = output_dir / f"{label}.footprint.json"
    command = [
        "footprint",
        "--format",
        "bytes",
        "-j",
        str(json_path),
        "-p",
        str(sample.pid),
    ]

    started = time.monotonic()
    try:
        completed = subprocess.run(
            command,
            text=True,
            capture_output=True,
            timeout=timeout_seconds,
        )
    except (OSError, subprocess.TimeoutExpired) as error:
        duration_seconds = time.monotonic() - started
        text_path.write_text(
            "$ " + " ".join(command) + "\n\n" + str(error) + "\n",
            encoding="utf-8",
        )
        return FootprintSnapshot(
            label=label,
            elapsed_seconds=sample.elapsed_seconds,
            pid=sample.pid,
            rss_mb=sample.rss_mb,
            text_path=text_path,
            json_path=json_path if json_path.exists() else None,
            returncode=None,
            duration_seconds=duration_seconds,
            error=str(error),
        )

    duration_seconds = time.monotonic() - started
    text_path.write_text(
        "$ " + " ".join(command) + "\n\n" + completed.stdout + completed.stderr,
        encoding="utf-8",
    )

    return FootprintSnapshot(
        label=label,
        elapsed_seconds=sample.elapsed_seconds,
        pid=sample.pid,
        rss_mb=sample.rss_mb,
        text_path=text_path,
        json_path=json_path if json_path.exists() else None,
        returncode=completed.returncode,
        duration_seconds=duration_seconds,
        error=completed.stderr.strip() if completed.returncode != 0 else None,
    )


def read_footprint_process_summary(
    json_path: Path | None,
    top_category_count: int,
) -> FootprintProcessSummary | None:
    if json_path is None or not json_path.exists():
        return None

    payload = json.loads(json_path.read_text(encoding="utf-8"))
    processes = payload.get("processes", [])
    if not processes or not isinstance(processes[0], dict):
        return None

    process = processes[0]
    categories: list[FootprintCategory] = []
    for name, values in process.get("categories", {}).items():
        if not isinstance(values, dict):
            continue
        categories.append(
            FootprintCategory(
                name=name,
                dirty_bytes=int(values.get("dirty", 0)),
                clean_bytes=int(values.get("clean", 0)),
                swapped_bytes=int(values.get("swapped", 0)),
                regions=int(values.get("regions", 0)),
            )
        )

    categories.sort(key=lambda category: category.dirty_bytes, reverse=True)
    auxiliary = process.get("auxiliary", {})
    phys_footprint = (
        int(auxiliary["phys_footprint"])
        if isinstance(auxiliary, dict) and "phys_footprint" in auxiliary
        else None
    )

    return FootprintProcessSummary(
        name=str(process.get("name", "unknown")),
        pid=int(process.get("pid", 0)),
        footprint_bytes=int(process.get("footprint", 0)),
        phys_footprint_bytes=phys_footprint,
        categories=tuple(categories[:top_category_count]),
    )


def footprint_process_summary_lines(
    snapshot: FootprintSnapshot,
    top_category_count: int,
) -> list[str]:
    try:
        process = read_footprint_process_summary(
            snapshot.json_path,
            top_category_count,
        )
    except (OSError, json.JSONDecodeError, TypeError, ValueError) as error:
        return [f"  footprint category parse failed: {error}"]

    if process is None:
        return []

    lines = [
        f"  process: {process.name} pid={process.pid} "
        f"footprint={format_mb(process.footprint_bytes)} "
        f"physical={format_mb(process.phys_footprint_bytes)}",
    ]
    if process.categories:
        lines.append(f"  top dirty categories ({len(process.categories)}):")
        for category in process.categories:
            lines.append(
                f"    {category.name}: dirty={format_mb(category.dirty_bytes)}, "
                f"clean={format_mb(category.clean_bytes)}, "
                f"swapped={format_mb(category.swapped_bytes)}, "
                f"regions={category.regions}"
            )
    return lines


def footprint_alignment_lines(
    samples: list[Sample],
    snapshots: list[FootprintSnapshot],
) -> list[str]:
    alignment = footprint_alignment(samples, snapshots)
    if not alignment:
        return []

    lines = ["footprint alignment"]
    peak = alignment.get("peak_vs_sampled_peak")
    if peak is not None:
        lines.append(
            "  peak vs sampled peak: "
            f"snapshot_rss={peak['snapshot_rss_mb']:.3f} MB, "
            f"sampled_peak_rss={peak['sampled_peak_rss_mb']:.3f} MB, "
            f"rss_delta={format_delta(peak['rss_delta_mb'])} MB, "
            f"elapsed_delta={format_delta(peak['elapsed_delta_seconds'])}s"
        )
    sampled_peak = alignment.get("sampled_peak_vs_sampled_peak")
    if sampled_peak is not None:
        lines.append(
            "  sampled_peak vs sampled peak: "
            f"snapshot_rss={sampled_peak['snapshot_rss_mb']:.3f} MB, "
            f"sampled_peak_rss={sampled_peak['sampled_peak_rss_mb']:.3f} MB, "
            f"rss_delta={format_delta(sampled_peak['rss_delta_mb'])} MB, "
            f"elapsed_delta={format_delta(sampled_peak['elapsed_delta_seconds'])}s"
        )
    latest = alignment.get("latest_vs_final_sample")
    if latest is not None:
        lines.append(
            "  latest vs final sample: "
            f"snapshot_elapsed={latest['snapshot_elapsed_seconds']:.3f}s, "
            f"final_elapsed={latest['final_elapsed_seconds']:.3f}s, "
            f"elapsed_delta={format_delta(latest['elapsed_delta_seconds'])}s, "
            f"snapshot_rss={latest['snapshot_rss_mb']:.3f} MB, "
            f"final_rss={latest['final_rss_mb']:.3f} MB, "
            f"rss_delta={format_delta(latest['rss_delta_mb'])} MB"
        )
    final = alignment.get("final_vs_final_sample")
    if final is not None:
        lines.append(
            "  final vs final sample: "
            f"snapshot_elapsed={final['snapshot_elapsed_seconds']:.3f}s, "
            f"final_elapsed={final['final_elapsed_seconds']:.3f}s, "
            f"elapsed_delta={format_delta(final['elapsed_delta_seconds'])}s, "
            f"snapshot_rss={final['snapshot_rss_mb']:.3f} MB, "
            f"final_rss={final['final_rss_mb']:.3f} MB, "
            f"rss_delta={format_delta(final['rss_delta_mb'])} MB"
        )
    return lines


def footprint_alignment(
    samples: list[Sample],
    snapshots: list[FootprintSnapshot],
) -> dict[str, dict[str, float]]:
    if not samples:
        return {}

    captured = {
        snapshot.label: snapshot
        for snapshot in snapshots
        if snapshot.returncode == 0
    }
    peak_snapshot = captured.get("peak")
    sampled_peak_snapshot = captured.get("sampled_peak")
    latest_snapshot = captured.get("latest")
    final_snapshot = captured.get("final")
    if (
        peak_snapshot is None
        and sampled_peak_snapshot is None
        and latest_snapshot is None
        and final_snapshot is None
    ):
        return {}

    alignment: dict[str, dict[str, float]] = {}
    sampled_peak = max(samples, key=lambda sample: sample.rss_mb)
    if peak_snapshot is not None:
        alignment["peak_vs_sampled_peak"] = {
            "snapshot_elapsed_seconds": peak_snapshot.elapsed_seconds,
            "sampled_peak_elapsed_seconds": sampled_peak.elapsed_seconds,
            "elapsed_delta_seconds": (
                sampled_peak.elapsed_seconds - peak_snapshot.elapsed_seconds
            ),
            "snapshot_rss_mb": peak_snapshot.rss_mb,
            "sampled_peak_rss_mb": sampled_peak.rss_mb,
            "rss_delta_mb": sampled_peak.rss_mb - peak_snapshot.rss_mb,
        }
    if sampled_peak_snapshot is not None:
        alignment["sampled_peak_vs_sampled_peak"] = {
            "snapshot_elapsed_seconds": sampled_peak_snapshot.elapsed_seconds,
            "sampled_peak_elapsed_seconds": sampled_peak.elapsed_seconds,
            "elapsed_delta_seconds": (
                sampled_peak.elapsed_seconds - sampled_peak_snapshot.elapsed_seconds
            ),
            "snapshot_rss_mb": sampled_peak_snapshot.rss_mb,
            "sampled_peak_rss_mb": sampled_peak.rss_mb,
            "rss_delta_mb": sampled_peak.rss_mb - sampled_peak_snapshot.rss_mb,
        }
    if latest_snapshot is not None:
        final_sample = samples[-1]
        alignment["latest_vs_final_sample"] = {
            "snapshot_elapsed_seconds": latest_snapshot.elapsed_seconds,
            "final_elapsed_seconds": final_sample.elapsed_seconds,
            "elapsed_delta_seconds": (
                final_sample.elapsed_seconds - latest_snapshot.elapsed_seconds
            ),
            "snapshot_rss_mb": latest_snapshot.rss_mb,
            "final_rss_mb": final_sample.rss_mb,
            "rss_delta_mb": final_sample.rss_mb - latest_snapshot.rss_mb,
        }
    if final_snapshot is not None:
        final_sample = samples[-1]
        alignment["final_vs_final_sample"] = {
            "snapshot_elapsed_seconds": final_snapshot.elapsed_seconds,
            "final_elapsed_seconds": final_sample.elapsed_seconds,
            "elapsed_delta_seconds": (
                final_sample.elapsed_seconds - final_snapshot.elapsed_seconds
            ),
            "snapshot_rss_mb": final_snapshot.rss_mb,
            "final_rss_mb": final_sample.rss_mb,
            "rss_delta_mb": final_sample.rss_mb - final_snapshot.rss_mb,
        }
    return alignment


def footprint_capture_overhead(
    snapshots: list[FootprintSnapshot],
    *,
    source: str = "snapshot_index",
    persisted_snapshot_count: int | None = None,
) -> dict[str, int | float | str | None]:
    if not snapshots:
        return {}

    durations = [
        snapshot.duration_seconds
        for snapshot in snapshots
        if snapshot.duration_seconds is not None
    ]
    success_count = sum(1 for snapshot in snapshots if snapshot.returncode == 0)
    failure_count = len(snapshots) - success_count
    total_duration = sum(durations) if durations else None

    return {
        "source": source,
        "attempt_count": len(snapshots),
        "persisted_snapshot_count": persisted_snapshot_count,
        "success_count": success_count,
        "failure_count": failure_count,
        "known_duration_count": len(durations),
        "total_duration_seconds": total_duration,
        "mean_duration_seconds": (
            total_duration / len(durations)
            if total_duration is not None and durations
            else None
        ),
        "max_duration_seconds": max(durations) if durations else None,
    }


def footprint_capture_overhead_lines(
    snapshots: list[FootprintSnapshot],
    *,
    source: str = "snapshot_index",
    persisted_snapshot_count: int | None = None,
) -> list[str]:
    overhead = footprint_capture_overhead(
        snapshots,
        source=source,
        persisted_snapshot_count=persisted_snapshot_count,
    )
    if not overhead:
        return []

    return [
        "footprint capture overhead",
        f"  source: {overhead['source']}",
        f"  attempts: {overhead['attempt_count']}",
        f"  persisted snapshots: {format_int(manifest_int(overhead, 'persisted_snapshot_count'))}",
        f"  successes: {overhead['success_count']}",
        f"  failures: {overhead['failure_count']}",
        f"  known durations: {overhead['known_duration_count']}",
        f"  total duration: {format_seconds(manifest_float(overhead, 'total_duration_seconds'))}",
        f"  mean duration: {format_seconds(manifest_float(overhead, 'mean_duration_seconds'))}",
        f"  max duration: {format_seconds(manifest_float(overhead, 'max_duration_seconds'))}",
    ]


def write_footprint_index(
    output_dir: Path | None,
    snapshots: list[FootprintSnapshot],
    capture_events: list[FootprintSnapshot] | None = None,
) -> Path | None:
    if output_dir is None or not snapshots:
        return None

    output_dir.mkdir(parents=True, exist_ok=True)
    index_path = output_dir / "footprint-index.json"
    payload = {
        "schema": "imposter.footprint_summary_index",
        "schema_version": 1,
        "snapshots": [
            footprint_snapshot_index_item(snapshot, include_paths=True)
            for snapshot in snapshots
        ],
    }
    if capture_events is not None:
        payload["capture_events"] = [
            footprint_snapshot_index_item(snapshot, include_paths=False)
            for snapshot in capture_events
        ]
    index_path.write_text(
        json.dumps(payload, indent=2, sort_keys=True) + "\n",
        encoding="utf-8",
    )
    return index_path


def footprint_snapshot_index_item(
    snapshot: FootprintSnapshot,
    *,
    include_paths: bool,
) -> dict[str, object]:
    item: dict[str, object] = {
        "label": snapshot.label,
        "elapsed_seconds": snapshot.elapsed_seconds,
        "pid": snapshot.pid,
        "rss_mb": snapshot.rss_mb,
        "returncode": snapshot.returncode,
        "duration_seconds": snapshot.duration_seconds,
        "error": snapshot.error,
    }
    if include_paths:
        item["text_path"] = artifact_string(snapshot.text_path)
        item["json_path"] = artifact_string(snapshot.json_path)
    return item


def path_from_index_value(index_path: Path, value: object) -> Path | None:
    if value is None:
        return None

    path = Path(str(value)).expanduser()
    if not path.is_absolute():
        path = (index_path.parent / path).resolve()
    return path


def read_footprint_index_data(index_path: Path) -> FootprintIndexData:
    payload = json.loads(index_path.read_text(encoding="utf-8"))
    if payload.get("schema") != "imposter.footprint_summary_index":
        raise ValueError(f"Unsupported footprint index schema: {index_path}")

    snapshots = read_footprint_index_items(index_path, payload.get("snapshots", []))
    capture_items = payload.get("capture_events")
    capture_events = (
        read_footprint_index_items(index_path, capture_items)
        if isinstance(capture_items, list)
        else None
    )
    return FootprintIndexData(snapshots=snapshots, capture_events=capture_events)


def read_footprint_index(index_path: Path) -> list[FootprintSnapshot]:
    return read_footprint_index_data(index_path).snapshots


def read_footprint_index_items(
    index_path: Path,
    items: object,
) -> list[FootprintSnapshot]:
    if not isinstance(items, list):
        raise ValueError(f"Invalid footprint snapshots in {index_path}")

    snapshots: list[FootprintSnapshot] = []
    for item in items:
        if not isinstance(item, dict):
            raise ValueError(f"Invalid footprint snapshot in {index_path}")

        try:
            returncode_value = item.get("returncode")
            duration_value = item.get("duration_seconds")
            snapshots.append(
                FootprintSnapshot(
                    label=str(item["label"]),
                    elapsed_seconds=float(item["elapsed_seconds"]),
                    pid=int(item["pid"]),
                    rss_mb=float(item["rss_mb"]),
                    text_path=path_from_index_value(index_path, item.get("text_path")),
                    json_path=path_from_index_value(index_path, item.get("json_path")),
                    returncode=(
                        int(returncode_value)
                        if returncode_value is not None
                        else None
                    ),
                    duration_seconds=(
                        float(duration_value)
                        if duration_value is not None
                        else None
                    ),
                    error=(
                        str(item["error"])
                        if item.get("error") is not None
                        else None
                    ),
                )
            )
        except (KeyError, TypeError, ValueError) as error:
            raise ValueError(f"Invalid footprint snapshot in {index_path}") from error

    return snapshots


def footprint_summary_lines(
    footprint_dir: Path | None,
    snapshots: list[FootprintSnapshot],
    index_path: Path | None,
    top_category_count: int,
    samples: list[Sample],
    capture_events: list[FootprintSnapshot] | None = None,
) -> list[str]:
    if footprint_dir is None:
        return []

    lines = ["footprint summary snapshots", f"Directory: {footprint_dir}"]
    if index_path:
        lines.append(f"Index: {index_path}")
    if not snapshots:
        lines.append("No footprint snapshots were captured.")
        return lines

    overhead_snapshots = capture_events if capture_events is not None else snapshots
    overhead_source = "capture_events" if capture_events is not None else "snapshot_index"
    lines.extend(
        footprint_capture_overhead_lines(
            overhead_snapshots,
            source=overhead_source,
            persisted_snapshot_count=len(snapshots),
        )
    )
    lines.extend(footprint_alignment_lines(samples, snapshots))

    for snapshot in snapshots:
        status = (
            "captured"
            if snapshot.returncode == 0
            else f"failed returncode={snapshot.returncode}"
        )
        lines.append(
            f"{snapshot.label}: {status}, pid={snapshot.pid}, "
            f"elapsed={snapshot.elapsed_seconds:.3f}s, rss={snapshot.rss_mb:.3f} MB, "
            f"duration={format_seconds(snapshot.duration_seconds)}, "
            f"text={snapshot.text_path}, json={snapshot.json_path}"
        )
        if snapshot.returncode == 0 and top_category_count > 0:
            lines.extend(
                footprint_process_summary_lines(snapshot, top_category_count)
            )
    return lines


def vmmap_summary_lines(
    vmmap_dir: Path | None,
    snapshots: list[VmmapSnapshot],
    index_path: Path | None,
) -> list[str]:
    if vmmap_dir is None:
        return []

    lines = ["vmmap summary snapshots", f"Directory: {vmmap_dir}"]
    if index_path:
        lines.append(f"Index: {index_path}")
    if not snapshots:
        lines.append("No vmmap snapshots were captured.")
        return lines

    for snapshot in snapshots:
        status = (
            "captured"
            if snapshot.returncode == 0
            else f"failed returncode={snapshot.returncode}"
        )
        lines.append(
            f"{snapshot.label}: {status}, pid={snapshot.pid}, "
            f"elapsed={snapshot.elapsed_seconds:.3f}s, rss={snapshot.rss_mb:.3f} MB, "
            f"path={snapshot.path}"
        )
    return lines


def gates_failed(samples: list[Sample], args: argparse.Namespace) -> bool:
    if args.rss_gate_mode == "report":
        return False
    has_warm_gate = (
        args.max_warm_peak_rss_mb is not None
        or args.max_warm_final_rss_mb is not None
    )
    if has_warm_gate and args.warm_rss_floor_mb is not None:
        _, warmed_samples = warm_samples(samples, args.warm_rss_floor_mb)
        if not warmed_samples:
            return True
    return any(not gate.passed for gate in rss_gates(samples, args))


def xcresult_json(path: Path, subcommand: str, args: argparse.Namespace) -> dict:
    command = [
        "xcrun",
        "xcresulttool",
        "get",
        "test-results",
        subcommand,
        "--path",
        str(path),
        "--format",
        "json",
    ]
    env = os.environ.copy()
    if args.developer_dir:
        env["DEVELOPER_DIR"] = args.developer_dir
    completed = subprocess.run(
        command,
        env=env,
        text=True,
        capture_output=True,
    )
    if completed.returncode != 0:
        raise RuntimeError(
            f"xcresulttool failed for {path}: {completed.stderr.strip()}"
        )
    return json.loads(completed.stdout)


def collect_test_case_durations(node: dict) -> list[float]:
    durations: list[float] = []
    if node.get("nodeType") == "Test Case":
        duration = node.get("durationInSeconds")
        if isinstance(duration, (int, float)):
            durations.append(float(duration))

    for child in node.get("children", []):
        if isinstance(child, dict):
            durations.extend(collect_test_case_durations(child))

    return durations


def parse_xcode_elapsed_seconds(log_path: Path | None) -> float | None:
    if log_path is None or not log_path.exists():
        return None

    pattern = re.compile(r"([0-9]+(?:\.[0-9]+)?) elapsed -- Testing started completed")
    for line in log_path.read_text(encoding="utf-8", errors="replace").splitlines():
        match = pattern.search(line)
        if match:
            return float(match.group(1))
    return None


def read_xcresult_stats(
    result_path: Path,
    log_path: Path | None,
    args: argparse.Namespace,
) -> XcresultStats:
    summary = xcresult_json(result_path, "summary", args)
    tests = xcresult_json(result_path, "tests", args)

    start_time = summary.get("startTime")
    finish_time = summary.get("finishTime")
    bundle_duration = (
        float(finish_time) - float(start_time)
        if isinstance(start_time, (int, float)) and isinstance(finish_time, (int, float))
        else None
    )

    test_durations: list[float] = []
    for node in tests.get("testNodes", []):
        if isinstance(node, dict):
            test_durations.extend(collect_test_case_durations(node))

    device_name: str | None = None
    devices = tests.get("devices", [])
    if devices and isinstance(devices[0], dict):
        device_name = devices[0].get("deviceName")

    return XcresultStats(
        result=str(summary.get("result", "Unknown")),
        total_tests=int(summary.get("totalTestCount", 0)),
        passed_tests=int(summary.get("passedTests", 0)),
        failed_tests=int(summary.get("failedTests", 0)),
        skipped_tests=int(summary.get("skippedTests", 0)),
        bundle_duration_seconds=bundle_duration,
        test_case_count=len(test_durations),
        test_case_duration_seconds=sum(test_durations) if test_durations else None,
        device_name=device_name,
        xcode_elapsed_seconds=parse_xcode_elapsed_seconds(log_path),
    )


def format_float(value: float | None) -> str:
    if value is None:
        return "n/a"
    return f"{value:.3f}"


def format_seconds(value: float | None) -> str:
    if value is None:
        return "n/a"
    return f"{value:.3f}s"


def format_delta(value: float | None) -> str:
    if value is None:
        return "n/a"
    if abs(value) < 0.0005:
        value = 0.0
    return f"{value:+.3f}"


def manifest_float(payload: dict | None, key: str) -> float | None:
    if payload is None:
        return None
    value = payload.get(key)
    if isinstance(value, (int, float)):
        return float(value)
    return None


def manifest_int(payload: dict | None, key: str) -> int | None:
    if payload is None:
        return None
    value = payload.get(key)
    if isinstance(value, int):
        return value
    return None


def manifest_str(payload: dict | None, key: str) -> str | None:
    if payload is None:
        return None
    value = payload.get(key)
    if isinstance(value, str):
        return value
    return None


def format_int(value: int | None) -> str:
    if value is None:
        return "n/a"
    return str(value)


def format_text(value: str | None) -> str:
    if value is None:
        return "n/a"
    return value


def markdown_table(headers: list[str], rows: list[list[str]]) -> str:
    widths = [
        max(len(header), *(len(row[index]) for row in rows))
        for index, header in enumerate(headers)
    ]
    header_line = "| " + " | ".join(
        header.ljust(widths[index]) for index, header in enumerate(headers)
    ) + " |"
    separator_line = "| " + " | ".join("-" * widths[index] for index in range(len(headers))) + " |"
    row_lines = [
        "| " + " | ".join(
            value.ljust(widths[index]) for index, value in enumerate(row)
        ) + " |"
        for row in rows
    ]
    return "\n".join([header_line, separator_line, *row_lines])


def gate_status(gate: RssGate, mode: str) -> str:
    if gate.passed:
        return "PASS"
    if mode == "report":
        return "REPORT-FAIL"
    return "FAIL"


def comparison_labels(args: argparse.Namespace) -> tuple[list[str] | None, str | None]:
    labels = args.compare_label or []
    if not labels:
        return None, None
    if len(labels) != len(args.compare_csv):
        return None, "--compare-label count must match --compare-csv count"
    return labels, None


def comparison_metadata(
    args: argparse.Namespace,
    dataset_count: int,
) -> tuple[list[ComparisonMetadata] | None, str | None]:
    run_labels = args.compare_run_label or []
    simulator_states = args.compare_simulator_state or []

    if run_labels and len(run_labels) != dataset_count:
        return None, "--compare-run-label count must match --compare-csv count"
    if simulator_states and len(simulator_states) != dataset_count:
        return None, "--compare-simulator-state count must match --compare-csv count"

    return [
        ComparisonMetadata(
            run_label=run_labels[index] if run_labels else None,
            simulator_state=simulator_states[index] if simulator_states else None,
        )
        for index in range(dataset_count)
    ], None


def comparison_metadata_headers(args: argparse.Namespace) -> list[str]:
    headers: list[str] = []
    if args.compare_run_label:
        headers.append("Run label")
    if args.compare_simulator_state:
        headers.append("Simulator state")
    return headers


def comparison_metadata_cells(metadata: ComparisonMetadata, args: argparse.Namespace) -> list[str]:
    cells: list[str] = []
    if args.compare_run_label:
        cells.append(metadata.run_label or "n/a")
    if args.compare_simulator_state:
        cells.append(metadata.simulator_state or "n/a")
    return cells


def comparison_xcresult_paths(
    args: argparse.Namespace,
    datasets: list[tuple[str, Path, list[Sample]]],
) -> tuple[list[Path | None] | None, str | None]:
    explicit_paths = args.compare_xcresult or []
    if explicit_paths and args.infer_xcresult:
        return None, "--compare-xcresult and --infer-xcresult cannot be used together"
    if explicit_paths:
        if len(explicit_paths) != len(datasets):
            return None, "--compare-xcresult count must match --compare-csv count"

        resolved_paths: list[Path | None] = []
        for result_path in explicit_paths:
            path = result_path.expanduser().resolve()
            if not path.exists():
                return None, f"Comparison xcresult does not exist: {path}"
            resolved_paths.append(path)
        return resolved_paths, None

    if args.infer_xcresult:
        inferred_paths: list[Path | None] = []
        for _, csv_path, _ in datasets:
            result_path = csv_path.with_suffix(".xcresult")
            inferred_paths.append(result_path if result_path.exists() else None)
        return inferred_paths, None

    return None, None


def read_probe_manifest(manifest_path: Path) -> dict:
    payload = json.loads(manifest_path.read_text(encoding="utf-8"))
    if payload.get("schema") != "imposter.ui_memory_probe_manifest":
        raise ValueError(f"Unsupported manifest schema: {manifest_path}")
    return payload


def manifest_policy_available(policy: dict) -> bool:
    return any(
        policy.get(key) is not None
        for key in [
            "max_rss_mb",
            "warm_rss_floor_mb",
            "max_warm_peak_rss_mb",
            "max_warm_final_rss_mb",
        ]
    )


def comparison_gate_args_were_explicit(args: argparse.Namespace) -> bool:
    return any(
        [
            args.max_rss_mb is not None,
            args.warm_rss_floor_mb is not None,
            args.max_warm_peak_rss_mb is not None,
            args.max_warm_final_rss_mb is not None,
            getattr(args, "rss_gate_mode_was_explicit", False),
        ]
    )


def apply_manifest_threshold_policy(args: argparse.Namespace, policy: dict) -> None:
    args.max_rss_mb = policy.get("max_rss_mb")
    args.warm_rss_floor_mb = policy.get("warm_rss_floor_mb")
    args.max_warm_peak_rss_mb = policy.get("max_warm_peak_rss_mb")
    args.max_warm_final_rss_mb = policy.get("max_warm_final_rss_mb")
    gate_mode = policy.get("rss_gate_mode")
    if gate_mode in {"fail", "report"}:
        args.rss_gate_mode = gate_mode


def apply_compare_manifests(args: argparse.Namespace) -> str | None:
    if not args.compare_manifest:
        return None
    if args.compare_csv:
        return "--compare-manifest and --compare-csv cannot be used together"

    csv_paths: list[Path] = []
    fallback_labels: list[str] = []
    run_labels: list[str] = []
    simulator_states: list[str] = []
    result_paths: list[Path] = []
    footprint_alignments: list[dict | None] = []
    footprint_capture_overheads: list[dict | None] = []
    first_threshold_policy: dict | None = None

    for manifest_input in args.compare_manifest:
        manifest_path = manifest_input.expanduser().resolve()
        try:
            manifest = read_probe_manifest(manifest_path)
        except (OSError, ValueError, json.JSONDecodeError) as error:
            return str(error)

        artifacts = manifest.get("artifacts", {})
        run = manifest.get("run", {})
        if first_threshold_policy is None:
            first_threshold_policy = manifest.get("threshold_policy", {})
        csv_value = artifacts.get("csv")
        if not csv_value:
            return f"Manifest is missing a CSV artifact: {manifest_path}"

        csv_path = Path(csv_value).expanduser().resolve()
        if not csv_path.exists():
            return f"Manifest CSV does not exist: {csv_path}"

        csv_paths.append(csv_path)
        run_label = run.get("label") or manifest_path.stem
        fallback_labels.append(run_label)
        run_labels.append(run_label)
        simulator_states.append(run.get("simulator_state") or "n/a")
        alignment = manifest.get("footprint_alignment")
        footprint_alignments.append(alignment if isinstance(alignment, dict) else None)
        overhead = manifest.get("footprint_capture_overhead")
        footprint_capture_overheads.append(
            overhead if isinstance(overhead, dict) else None
        )

        result_value = artifacts.get("result_bundle")
        if result_value:
            result_path = Path(result_value).expanduser().resolve()
            if result_path.exists():
                result_paths.append(result_path)

    args.compare_csv = csv_paths
    if not args.compare_label:
        args.compare_label = fallback_labels
    if not args.compare_run_label:
        args.compare_run_label = run_labels
    if not args.compare_simulator_state:
        args.compare_simulator_state = simulator_states
    if any(alignment is not None for alignment in footprint_alignments):
        args.compare_footprint_alignment = footprint_alignments
    if any(overhead is not None for overhead in footprint_capture_overheads):
        args.compare_footprint_capture_overhead = footprint_capture_overheads
    if not args.compare_xcresult and not args.infer_xcresult and len(result_paths) == len(csv_paths):
        args.compare_xcresult = result_paths
    if (
        first_threshold_policy
        and manifest_policy_available(first_threshold_policy)
        and not comparison_gate_args_were_explicit(args)
    ):
        apply_manifest_threshold_policy(args, first_threshold_policy)

    return None


def compare_csvs(args: argparse.Namespace) -> int:
    gate_error = validate_gate_args(args)
    if gate_error:
        print(gate_error, file=sys.stderr)
        return 2

    if len(args.compare_csv) < 2:
        print("--compare-csv requires at least two CSV paths", file=sys.stderr)
        return 2

    labels, label_error = comparison_labels(args)
    if label_error:
        print(label_error, file=sys.stderr)
        return 2

    datasets: list[tuple[str, Path, list[Sample]]] = []
    for index, csv_path in enumerate(args.compare_csv):
        path = csv_path.expanduser().resolve()
        samples = read_samples(path)
        if not samples:
            print(f"No samples in comparison CSV: {path}", file=sys.stderr)
            return 2
        label = labels[index] if labels else path.stem
        datasets.append((label, path, samples))

    baseline_label, _, baseline_samples = datasets[0]
    baseline = sample_stats(baseline_samples)
    result_paths, result_error = comparison_xcresult_paths(args, datasets)
    if result_error:
        print(result_error, file=sys.stderr)
        return 2
    metadata_rows, metadata_error = comparison_metadata(args, len(datasets))
    if metadata_error:
        print(metadata_error, file=sys.stderr)
        return 2
    metadata_rows = metadata_rows or []
    metadata_headers = comparison_metadata_headers(args)

    result_stats_by_label: dict[str, XcresultStats] = {}
    if result_paths:
        for (label, csv_path, _), result_path in zip(datasets, result_paths):
            if result_path is None:
                continue
            try:
                result_stats_by_label[label] = read_xcresult_stats(
                    result_path,
                    csv_path.with_suffix(".xcodebuild.log"),
                    args,
                )
            except (RuntimeError, json.JSONDecodeError) as error:
                print(str(error), file=sys.stderr)
                return 2

    lines = ["RSS CSV comparison"]
    if args.run_label:
        lines.append(f"Run label: {args.run_label}")
    lines.append(f"Baseline: {baseline_label}")

    rows: list[list[str]] = []
    for index, (label, _, samples) in enumerate(datasets):
        stats = sample_stats(samples)
        rows.append(
            [
                label,
                *comparison_metadata_cells(metadata_rows[index], args),
                str(stats.sample_count),
                format_float(stats.first_elapsed_seconds),
                format_float(stats.last_elapsed_seconds),
                format_float(stats.first_rss_mb),
                format_float(stats.peak_rss_mb),
                format_float(stats.last_rss_mb),
                format_delta(stats.peak_rss_mb - baseline.peak_rss_mb),
                format_delta(stats.last_rss_mb - baseline.last_rss_mb),
                format_float(stats.peak_minus_first_mb),
                format_float(stats.last_minus_first_mb),
            ]
        )

    lines.extend(
        [
            "",
            "Raw RSS comparison",
            markdown_table(
                [
                    "Label",
                    *metadata_headers,
                    "Samples",
                    "First s",
                    "Last s",
                    "First MB",
                    "Peak MB",
                    "Final MB",
                    "Peak vs base MB",
                    "Final vs base MB",
                    "Peak growth MB",
                    "Final growth MB",
                ],
                rows,
            ),
        ]
    )

    if args.warm_rss_floor_mb is not None:
        lines.append("")
        lines.append(f"Warm-start RSS floor: {args.warm_rss_floor_mb:.3f} MB")
        _, baseline_warm_samples = warm_samples(
            baseline_samples,
            args.warm_rss_floor_mb,
        )
        baseline_warm = sample_stats(baseline_warm_samples) if baseline_warm_samples else None
        warm_rows: list[list[str]] = []
        for index, (label, _, samples) in enumerate(datasets):
            start_index, warmed_samples = warm_samples(samples, args.warm_rss_floor_mb)
            if warmed_samples:
                stats = sample_stats(warmed_samples)
                warm_peak_delta = (
                    stats.peak_rss_mb - baseline_warm.peak_rss_mb
                    if baseline_warm
                    else None
                )
                warm_final_delta = (
                    stats.last_rss_mb - baseline_warm.last_rss_mb
                    if baseline_warm
                    else None
                )
                warm_rows.append(
                    [
                        label,
                        *comparison_metadata_cells(metadata_rows[index], args),
                        f"{start_index + 1} of {len(samples)}",
                        str(stats.sample_count),
                        format_float(stats.first_rss_mb),
                        format_float(stats.peak_rss_mb),
                        format_float(stats.last_rss_mb),
                        format_delta(warm_peak_delta),
                        format_delta(warm_final_delta),
                        format_float(stats.peak_minus_first_mb),
                        format_float(stats.last_minus_first_mb),
                    ]
                )
            else:
                warm_rows.append(
                    [
                        label,
                        *comparison_metadata_cells(metadata_rows[index], args),
                        "none",
                        "0",
                        "n/a",
                        "n/a",
                        "n/a",
                        "n/a",
                        "n/a",
                        "n/a",
                        "n/a",
                    ]
                )

        lines.extend(
            [
                "Warm-start RSS comparison",
                markdown_table(
                    [
                        "Label",
                        *metadata_headers,
                        "Warm index",
                        "Samples",
                        "First MB",
                        "Peak MB",
                        "Final MB",
                        "Peak vs base MB",
                        "Final vs base MB",
                        "Peak growth MB",
                        "Final growth MB",
                    ],
                    warm_rows,
                ),
            ]
        )

    gate_rows: list[list[str]] = []
    for index, (label, _, samples) in enumerate(datasets):
        for gate in rss_gates(samples, args):
            gate_rows.append(
                [
                    label,
                    *comparison_metadata_cells(metadata_rows[index], args),
                    gate.label,
                    gate_status(gate, args.rss_gate_mode),
                    format_float(gate.actual_mb),
                    format_float(gate.threshold_mb),
                ]
            )
    if gate_rows:
        lines.extend(
            [
                "",
                "RSS gate comparison",
                markdown_table(
                    [
                        "Label",
                        *metadata_headers,
                        "Gate",
                        "Status",
                        "Actual MB",
                        "Threshold MB",
                    ],
                    gate_rows,
                ),
            ]
        )

    alignment_items = getattr(args, "compare_footprint_alignment", None)
    if alignment_items and len(alignment_items) == len(datasets):
        alignment_rows: list[list[str]] = []
        for index, (label, _, _) in enumerate(datasets):
            alignment = alignment_items[index]
            peak_alignment = (
                alignment.get("peak_vs_sampled_peak")
                if isinstance(alignment, dict)
                else None
            )
            sampled_peak_alignment = (
                alignment.get("sampled_peak_vs_sampled_peak")
                if isinstance(alignment, dict)
                else None
            )
            latest_alignment = (
                alignment.get("latest_vs_final_sample")
                if isinstance(alignment, dict)
                else None
            )
            final_alignment = (
                alignment.get("final_vs_final_sample")
                if isinstance(alignment, dict)
                else None
            )
            alignment_rows.append(
                [
                    label,
                    *comparison_metadata_cells(metadata_rows[index], args),
                    format_delta(manifest_float(peak_alignment, "rss_delta_mb")),
                    format_delta(
                        manifest_float(peak_alignment, "elapsed_delta_seconds")
                    ),
                    format_delta(
                        manifest_float(sampled_peak_alignment, "rss_delta_mb")
                    ),
                    format_delta(
                        manifest_float(
                            sampled_peak_alignment,
                            "elapsed_delta_seconds",
                        )
                    ),
                    format_delta(manifest_float(latest_alignment, "rss_delta_mb")),
                    format_delta(
                        manifest_float(latest_alignment, "elapsed_delta_seconds")
                    ),
                    format_delta(manifest_float(final_alignment, "rss_delta_mb")),
                    format_delta(
                        manifest_float(final_alignment, "elapsed_delta_seconds")
                    ),
                ]
            )

        lines.extend(
            [
                "",
                "Footprint alignment comparison",
                markdown_table(
                    [
                        "Label",
                        *metadata_headers,
                        "Peak RSS delta MB",
                        "Peak elapsed delta s",
                        "Sampled peak RSS delta MB",
                        "Sampled peak elapsed delta s",
                        "Latest RSS delta MB",
                        "Latest elapsed delta s",
                        "Final RSS delta MB",
                        "Final elapsed delta s",
                    ],
                    alignment_rows,
                ),
            ]
        )

    overhead_items = getattr(args, "compare_footprint_capture_overhead", None)
    if overhead_items and len(overhead_items) == len(datasets):
        overhead_rows: list[list[str]] = []
        for index, (label, _, _) in enumerate(datasets):
            overhead = overhead_items[index]
            overhead = overhead if isinstance(overhead, dict) else None
            overhead_rows.append(
                [
                    label,
                    *comparison_metadata_cells(metadata_rows[index], args),
                    format_text(manifest_str(overhead, "source")),
                    format_int(manifest_int(overhead, "attempt_count")),
                    format_int(manifest_int(overhead, "persisted_snapshot_count")),
                    format_int(manifest_int(overhead, "success_count")),
                    format_int(manifest_int(overhead, "failure_count")),
                    format_int(manifest_int(overhead, "known_duration_count")),
                    format_float(
                        manifest_float(overhead, "total_duration_seconds")
                    ),
                    format_float(
                        manifest_float(overhead, "mean_duration_seconds")
                    ),
                    format_float(
                        manifest_float(overhead, "max_duration_seconds")
                    ),
                ]
            )

        lines.extend(
            [
                "",
                "Footprint capture overhead comparison",
                markdown_table(
                    [
                        "Label",
                        *metadata_headers,
                        "Source",
                        "Attempts",
                        "Snapshots",
                        "Successes",
                        "Failures",
                        "Known durations",
                        "Total s",
                        "Mean s",
                        "Max s",
                    ],
                    overhead_rows,
                ),
            ]
        )

    if result_stats_by_label:
        baseline_result = result_stats_by_label.get(baseline_label)
        result_rows: list[list[str]] = []
        for index, (label, _, _) in enumerate(datasets):
            stats = result_stats_by_label.get(label)
            if stats is None:
                result_rows.append(
                    [
                        label,
                        *comparison_metadata_cells(metadata_rows[index], args),
                        "n/a",
                        "n/a",
                        "n/a",
                        "n/a",
                        "n/a",
                        "n/a",
                        "n/a",
                        "n/a",
                        "n/a",
                    ]
                )
                continue

            case_delta = (
                stats.test_case_duration_seconds
                - baseline_result.test_case_duration_seconds
                if baseline_result
                and stats.test_case_duration_seconds is not None
                and baseline_result.test_case_duration_seconds is not None
                else None
            )
            elapsed_delta = (
                stats.xcode_elapsed_seconds - baseline_result.xcode_elapsed_seconds
                if baseline_result
                and stats.xcode_elapsed_seconds is not None
                and baseline_result.xcode_elapsed_seconds is not None
                else None
            )
            result_rows.append(
                [
                    label,
                    *comparison_metadata_cells(metadata_rows[index], args),
                    stats.result,
                    str(stats.total_tests),
                    str(stats.failed_tests),
                    format_float(stats.test_case_duration_seconds),
                    format_delta(case_delta),
                    format_float(stats.bundle_duration_seconds),
                    format_float(stats.xcode_elapsed_seconds),
                    format_delta(elapsed_delta),
                    stats.device_name or "n/a",
                ]
            )

        lines.extend(
            [
                "",
                "XCTest result comparison",
                markdown_table(
                    [
                        "Label",
                        *metadata_headers,
                        "Result",
                        "Total",
                        "Failed",
                        "Case s",
                        "Case vs base s",
                        "Bundle s",
                        "Xcode elapsed s",
                        "Elapsed vs base s",
                        "Device",
                    ],
                    result_rows,
                ),
            ]
        )

    summary = "\n".join(lines)
    print(summary)

    if args.summary_output:
        written_summary = write_summary_artifact(
            args.summary_output.expanduser().resolve(),
            summary,
        )
        if written_summary:
            print(f"summary: {written_summary}")

    if gates_failed_any(datasets, args):
        print("FAIL: one or more RSS gates failed", file=sys.stderr)
        return 1

    return 0


def gates_failed_any(
    datasets: list[tuple[str, Path, list[Sample]]],
    args: argparse.Namespace,
) -> bool:
    return any(gates_failed(samples, args) for _, _, samples in datasets)


def add_metadata(
    summary: str,
    args: argparse.Namespace,
    samples: list[Sample],
    command: list[str] | None = None,
    result_bundle: Path | None = None,
    output_csv: Path | None = None,
) -> str:
    lines = ["Probe metadata"]

    if args.run_label:
        lines.append(f"Run label: {args.run_label}")
    if args.simulator_state:
        lines.append(f"Simulator state: {args.simulator_state}")
    if args.configuration:
        lines.append(f"Configuration: {args.configuration}")
    if args.destination:
        lines.append(f"Destination: {args.destination}")
    if args.only_testing:
        lines.append(f"Focused test: {args.only_testing}")
    if command:
        lines.append(f"Command: {' '.join(command)}")
    if result_bundle:
        lines.append(f"Result bundle: {result_bundle}")
    if output_csv:
        lines.append(f"CSV: {output_csv}")

    if samples:
        lines.append(
            f"First app sample delay: {samples[0].elapsed_seconds:.3f} seconds"
        )
    else:
        lines.append("First app sample delay: no app samples captured")

    return "\n".join(lines + ["", summary])


def write_summary_artifact(summary_output: Path | None, summary: str) -> Path | None:
    if summary_output is None:
        return None

    summary_output.parent.mkdir(parents=True, exist_ok=True)
    summary_output.write_text(summary + "\n", encoding="utf-8")
    return summary_output


def threshold_policy(args: argparse.Namespace) -> dict[str, float | str | None]:
    return {
        "max_rss_mb": args.max_rss_mb,
        "warm_rss_floor_mb": args.warm_rss_floor_mb,
        "max_warm_peak_rss_mb": args.max_warm_peak_rss_mb,
        "max_warm_final_rss_mb": args.max_warm_final_rss_mb,
        "rss_gate_mode": args.rss_gate_mode,
    }


def existing_path(path: Path) -> Path | None:
    return path if path.exists() else None


def artifact_string(path: Path | None) -> str | None:
    return str(path) if path is not None else None


def probe_manifest(
    kind: str,
    args: argparse.Namespace,
    csv_path: Path | None,
    summary_path: Path | None,
    result_bundle: Path | None,
    log_path: Path | None,
    vmmap_dir: Path | None = None,
    vmmap_index: Path | None = None,
    footprint_dir: Path | None = None,
    footprint_index: Path | None = None,
    footprint_alignment_data: dict[str, dict[str, float]] | None = None,
    footprint_capture_overhead_data: dict[str, int | float | str | None] | None = None,
) -> dict:
    payload = {
        "schema": "imposter.ui_memory_probe_manifest",
        "schema_version": 1,
        "kind": kind,
        "run": {
            "label": args.run_label,
            "simulator_state": args.simulator_state,
            "configuration": args.configuration,
            "destination": args.destination,
            "focused_test": args.only_testing,
            "scheme": args.scheme,
        },
        "artifacts": {
            "csv": artifact_string(csv_path),
            "summary": artifact_string(summary_path),
            "result_bundle": artifact_string(result_bundle),
            "xcodebuild_log": artifact_string(log_path),
            "vmmap_dir": artifact_string(vmmap_dir),
            "vmmap_index": artifact_string(vmmap_index),
            "footprint_dir": artifact_string(footprint_dir),
            "footprint_index": artifact_string(footprint_index),
        },
        "threshold_policy": threshold_policy(args),
    }
    if footprint_alignment_data:
        payload["footprint_alignment"] = footprint_alignment_data
    if footprint_capture_overhead_data:
        payload["footprint_capture_overhead"] = footprint_capture_overhead_data
    return payload


def write_manifest_artifact(
    manifest_output: Path | None,
    payload: dict,
) -> Path | None:
    if manifest_output is None:
        return None

    manifest_output.parent.mkdir(parents=True, exist_ok=True)
    manifest_output.write_text(
        json.dumps(payload, indent=2, sort_keys=True) + "\n",
        encoding="utf-8",
    )
    return manifest_output


def build_xcodebuild_command(args: argparse.Namespace) -> list[str]:
    command = [
        "xcodebuild",
        "test",
        "-project",
        str(args.project),
        "-scheme",
        args.scheme,
    ]

    if args.configuration:
        command.extend(["-configuration", args.configuration])

    command.extend(
        [
            "-destination",
            args.destination,
            "-resultBundlePath",
            str(args.result_bundle),
        ]
    )

    if args.only_testing:
        command.append(f"-only-testing:{args.only_testing}")

    if not args.verbose_xcodebuild:
        command.append("-quiet")

    return command


def run_probe(args: argparse.Namespace) -> int:
    gate_error = validate_gate_args(args)
    if gate_error:
        print(gate_error, file=sys.stderr)
        return 2

    if args.result_bundle is None:
        print("--result-bundle is required unless --analyze-csv is used", file=sys.stderr)
        return 2
    if args.output_csv is None:
        print("--output-csv is required unless --analyze-csv is used", file=sys.stderr)
        return 2
    if args.vmmap_timeout_seconds <= 0:
        print("--vmmap-timeout-seconds must be greater than 0", file=sys.stderr)
        return 2
    if args.vmmap_peak_min_delta_mb < 0:
        print("--vmmap-peak-min-delta-mb cannot be negative", file=sys.stderr)
        return 2
    if args.footprint_timeout_seconds <= 0:
        print("--footprint-timeout-seconds must be greater than 0", file=sys.stderr)
        return 2
    if args.footprint_peak_min_delta_mb < 0:
        print("--footprint-peak-min-delta-mb cannot be negative", file=sys.stderr)
        return 2
    if args.footprint_latest_interval_seconds < 0:
        print("--footprint-latest-interval-seconds cannot be negative", file=sys.stderr)
        return 2
    if args.footprint_final_interval_seconds < 0:
        print("--footprint-final-interval-seconds cannot be negative", file=sys.stderr)
        return 2
    if args.footprint_top_categories < 0:
        print("--footprint-top-categories cannot be negative", file=sys.stderr)
        return 2

    result_bundle = args.result_bundle.expanduser().resolve()
    output_csv = args.output_csv.expanduser().resolve()
    vmmap_dir = args.vmmap_summary_dir.expanduser().resolve() if args.vmmap_summary_dir else None
    footprint_dir = (
        args.footprint_summary_dir.expanduser().resolve()
        if args.footprint_summary_dir
        else None
    )

    if result_bundle.exists():
        if not args.replace:
            print(f"Result bundle already exists: {result_bundle}", file=sys.stderr)
            return 2
        shutil.rmtree(result_bundle)
    if vmmap_dir is not None:
        if not vmmap_available():
            print("vmmap is not available on PATH", file=sys.stderr)
            return 2
        if vmmap_dir.exists():
            if not args.replace:
                print(f"vmmap summary dir already exists: {vmmap_dir}", file=sys.stderr)
                return 2
            shutil.rmtree(vmmap_dir)
    if footprint_dir is not None:
        if not footprint_available():
            print("footprint is not available on PATH", file=sys.stderr)
            return 2
        if footprint_dir.exists():
            if not args.replace:
                print(
                    f"footprint summary dir already exists: {footprint_dir}",
                    file=sys.stderr,
                )
                return 2
            shutil.rmtree(footprint_dir)

    command = build_xcodebuild_command(args)
    env = os.environ.copy()
    if args.developer_dir:
        env["DEVELOPER_DIR"] = args.developer_dir

    process = subprocess.Popen(
        command,
        cwd=args.cwd,
        env=env,
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
    )

    samples: list[Sample] = []
    output_chunks: list[str] = []
    vmmap_snapshots: dict[str, VmmapSnapshot] = {}
    footprint_snapshots: dict[str, FootprintSnapshot] = {}
    footprint_capture_events: list[FootprintSnapshot] = []
    last_footprint_latest_elapsed: float | None = None
    last_footprint_final_elapsed: float | None = None
    sampled_peak_footprint_rss_mb: float | None = None
    start = time.monotonic()

    def capture_footprint_snapshot(label: str, sample: Sample) -> FootprintSnapshot:
        assert footprint_dir is not None
        snapshot = write_footprint_snapshot(
            footprint_dir,
            label,
            sample,
            args.footprint_timeout_seconds,
        )
        footprint_snapshots[label] = snapshot
        footprint_capture_events.append(snapshot)
        return snapshot

    while process.poll() is None:
        if process.stdout:
            while True:
                ready, _, _ = select.select([process.stdout], [], [], 0)
                if not ready:
                    break
                line = process.stdout.readline()
                if not line:
                    break
                output_chunks.append(line)

        elapsed = time.monotonic() - start
        for pid, rss_mb, command_line in find_app_processes(args.app_executable):
            sample = Sample(
                elapsed_seconds=elapsed,
                pid=pid,
                rss_mb=rss_mb,
                command=command_line,
            )
            samples.append(sample)
            if vmmap_dir is not None:
                if "first" not in vmmap_snapshots:
                    vmmap_snapshots["first"] = write_vmmap_snapshot(
                        vmmap_dir,
                        "first",
                        sample,
                        args.vmmap_timeout_seconds,
                    )

                peak_snapshot = vmmap_snapshots.get("peak")
                should_capture_peak = peak_snapshot is None or (
                    sample.rss_mb
                    >= peak_snapshot.rss_mb + args.vmmap_peak_min_delta_mb
                )
                if should_capture_peak:
                    vmmap_snapshots["peak"] = write_vmmap_snapshot(
                        vmmap_dir,
                        "peak",
                        sample,
                        args.vmmap_timeout_seconds,
                    )
            if footprint_dir is not None:
                if "first" not in footprint_snapshots:
                    capture_footprint_snapshot("first", sample)

                peak_snapshot = footprint_snapshots.get("peak")
                should_capture_peak = peak_snapshot is None or (
                    sample.rss_mb
                    >= peak_snapshot.rss_mb + args.footprint_peak_min_delta_mb
                )
                if should_capture_peak:
                    capture_footprint_snapshot("peak", sample)
                should_capture_sampled_peak = (
                    args.footprint_capture_sampled_peak
                    and (
                        sampled_peak_footprint_rss_mb is None
                        or sample.rss_mb > sampled_peak_footprint_rss_mb
                    )
                )
                if should_capture_sampled_peak:
                    capture_footprint_snapshot("sampled_peak", sample)
                    sampled_peak_footprint_rss_mb = sample.rss_mb
                if args.footprint_latest_interval_seconds > 0:
                    should_capture_latest = (
                        last_footprint_latest_elapsed is None
                        or sample.elapsed_seconds
                        >= last_footprint_latest_elapsed
                        + args.footprint_latest_interval_seconds
                    )
                    if should_capture_latest:
                        capture_footprint_snapshot("latest", sample)
                        last_footprint_latest_elapsed = sample.elapsed_seconds
                if args.footprint_final_interval_seconds > 0:
                    should_capture_final = (
                        last_footprint_final_elapsed is None
                        or sample.elapsed_seconds
                        >= last_footprint_final_elapsed
                        + args.footprint_final_interval_seconds
                    )
                    if should_capture_final:
                        capture_footprint_snapshot("final", sample)
                        last_footprint_final_elapsed = sample.elapsed_seconds

        time.sleep(args.interval)

    if process.stdout:
        output_chunks.extend(process.stdout.readlines())

    if footprint_dir is not None and args.footprint_capture_final and samples:
        capture_footprint_snapshot("final", samples[-1])

    write_samples(output_csv, samples)
    vmmap_snapshot_list = [
        vmmap_snapshots[label]
        for label in ["first", "peak"]
        if label in vmmap_snapshots
    ]
    vmmap_index = write_vmmap_index(vmmap_dir, vmmap_snapshot_list)
    footprint_snapshot_list = [
        footprint_snapshots[label]
        for label in ["first", "peak", "sampled_peak", "latest", "final"]
        if label in footprint_snapshots
    ]
    footprint_index = write_footprint_index(
        footprint_dir,
        footprint_snapshot_list,
        footprint_capture_events if footprint_dir is not None else None,
    )
    footprint_alignment_data = footprint_alignment(samples, footprint_snapshot_list)
    footprint_capture_overhead_data = footprint_capture_overhead(
        footprint_capture_events if footprint_capture_events else footprint_snapshot_list,
        source="capture_events" if footprint_capture_events else "snapshot_index",
        persisted_snapshot_count=len(footprint_snapshot_list) if footprint_dir else None,
    )
    summary_body = summarize(samples, args.warm_rss_floor_mb)
    gates = gate_summary(samples, args)
    if gates:
        summary_body += "\n\n" + gates
    vmmap_lines = vmmap_summary_lines(vmmap_dir, vmmap_snapshot_list, vmmap_index)
    if vmmap_lines:
        summary_body += "\n\n" + "\n".join(vmmap_lines)
    footprint_lines = footprint_summary_lines(
        footprint_dir,
        footprint_snapshot_list,
        footprint_index,
        args.footprint_top_categories,
        samples,
        capture_events=footprint_capture_events if footprint_dir is not None else None,
    )
    if footprint_lines:
        summary_body += "\n\n" + "\n".join(footprint_lines)

    summary = add_metadata(
        summary_body,
        args,
        samples,
        command=command,
        result_bundle=result_bundle,
        output_csv=output_csv,
    )
    print(summary)

    summary_output = args.summary_output
    if summary_output is None:
        summary_output = output_csv.with_suffix(".summary.txt")
    written_summary = write_summary_artifact(summary_output.expanduser().resolve(), summary)
    if written_summary:
        print(f"summary: {written_summary}")

    log_path: Path | None = None
    if output_chunks:
        log_path = output_csv.with_suffix(".xcodebuild.log")
        log_path.write_text(
            "$ " + " ".join(command) + "\n\n" + "".join(output_chunks),
            encoding="utf-8",
        )
        print(f"xcodebuild log: {log_path}")

    written_manifest = write_manifest_artifact(
        args.manifest_output.expanduser().resolve() if args.manifest_output else None,
        probe_manifest(
            "live-probe",
            args,
            output_csv,
            written_summary,
            result_bundle,
            log_path,
            vmmap_dir=vmmap_dir,
            vmmap_index=vmmap_index,
            footprint_dir=footprint_dir,
            footprint_index=footprint_index,
            footprint_alignment_data=footprint_alignment_data,
            footprint_capture_overhead_data=footprint_capture_overhead_data,
        ),
    )
    if written_manifest:
        print(f"manifest: {written_manifest}")

    if process.returncode != 0:
        print(f"xcodebuild exited with {process.returncode}", file=sys.stderr)
        return process.returncode

    if not samples:
        print("No app memory samples captured.", file=sys.stderr)
        return 2

    if gates_failed(samples, args):
        print("FAIL: one or more RSS gates failed", file=sys.stderr)
        return 1

    return 0


def analyze_csv(args: argparse.Namespace) -> int:
    gate_error = validate_gate_args(args)
    if gate_error:
        print(gate_error, file=sys.stderr)
        return 2
    if args.footprint_top_categories < 0:
        print("--footprint-top-categories cannot be negative", file=sys.stderr)
        return 2

    input_csv = args.analyze_csv.expanduser().resolve()
    samples = read_samples(input_csv)
    footprint_dir = (
        args.footprint_summary_dir.expanduser().resolve()
        if args.footprint_summary_dir
        else None
    )
    footprint_index: Path | None = None
    footprint_snapshot_list: list[FootprintSnapshot] = []
    footprint_capture_events: list[FootprintSnapshot] | None = None
    if footprint_dir is not None:
        footprint_index = footprint_dir / "footprint-index.json"
        if not footprint_index.exists():
            print(f"footprint index not found: {footprint_index}", file=sys.stderr)
            return 2
        try:
            footprint_index_data = read_footprint_index_data(footprint_index)
        except (OSError, json.JSONDecodeError, ValueError) as error:
            print(f"Failed to read footprint index: {error}", file=sys.stderr)
            return 2
        footprint_snapshot_list = footprint_index_data.snapshots
        footprint_capture_events = footprint_index_data.capture_events

    summary_body = summarize(samples, args.warm_rss_floor_mb)
    gates = gate_summary(samples, args)
    if gates:
        summary_body += "\n\n" + gates
    footprint_lines = footprint_summary_lines(
        footprint_dir,
        footprint_snapshot_list,
        footprint_index,
        args.footprint_top_categories,
        samples,
        capture_events=footprint_capture_events,
    )
    if footprint_lines:
        summary_body += "\n\n" + "\n".join(footprint_lines)
    footprint_alignment_data = footprint_alignment(samples, footprint_snapshot_list)
    footprint_capture_overhead_data = footprint_capture_overhead(
        (
            footprint_capture_events
            if footprint_capture_events is not None
            else footprint_snapshot_list
        ),
        source=(
            "capture_events"
            if footprint_capture_events is not None
            else "snapshot_index"
        ),
        persisted_snapshot_count=(
            len(footprint_snapshot_list) if footprint_dir is not None else None
        ),
    )

    summary = add_metadata(
        summary_body,
        args,
        samples,
        output_csv=input_csv,
    )
    print(summary)

    written_summary: Path | None = None
    if args.summary_output:
        written_summary = write_summary_artifact(
            args.summary_output.expanduser().resolve(),
            summary,
        )
        if written_summary:
            print(f"summary: {written_summary}")
    else:
        written_summary = existing_path(input_csv.with_suffix(".summary.txt"))

    result_bundle = (
        args.result_bundle.expanduser().resolve()
        if args.result_bundle
        else existing_path(input_csv.with_suffix(".xcresult"))
    )
    log_path = existing_path(input_csv.with_suffix(".xcodebuild.log"))
    written_manifest = write_manifest_artifact(
        args.manifest_output.expanduser().resolve() if args.manifest_output else None,
        probe_manifest(
            "csv-analysis",
            args,
            input_csv,
            written_summary,
            result_bundle,
            log_path,
            footprint_dir=footprint_dir,
            footprint_index=footprint_index,
            footprint_alignment_data=footprint_alignment_data,
            footprint_capture_overhead_data=footprint_capture_overhead_data,
        ),
    )
    if written_manifest:
        print(f"manifest: {written_manifest}")

    if gates_failed(samples, args):
        print("FAIL: one or more RSS gates failed", file=sys.stderr)
        return 1

    return 0


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Run a focused UI test and sample the simulator app process RSS."
    )
    parser.add_argument("--project", type=Path, default=Path("Imposter.xcodeproj"))
    parser.add_argument("--scheme", default="Imposter-UITests")
    parser.add_argument("--configuration")
    parser.add_argument("--run-label")
    parser.add_argument(
        "--simulator-state",
        help="Free-form note such as erased-before-run, warm-booted, or shutdown.",
    )
    parser.add_argument(
        "--destination",
        default="platform=iOS Simulator,id=A113E399-3127-41CE-AB7E-B529DB41B3B6",
    )
    parser.add_argument(
        "--only-testing",
        default="ImposterUITests/ImposterUITests/testRenderedHostedFlowRecordsRuntimeAcrossRepeatedRounds",
    )
    parser.add_argument("--app-executable", default="Imposter")
    parser.add_argument("--result-bundle", type=Path)
    parser.add_argument("--output-csv", type=Path)
    parser.add_argument(
        "--analyze-csv",
        type=Path,
        help="Summarize an existing probe CSV instead of running xcodebuild.",
    )
    parser.add_argument(
        "--compare-csv",
        nargs="+",
        type=Path,
        help="Compare two or more probe CSVs and print raw/warm RSS variance tables.",
    )
    parser.add_argument(
        "--compare-manifest",
        nargs="+",
        type=Path,
        help="Compare two or more probe manifests generated by --manifest-output.",
    )
    parser.add_argument(
        "--compare-label",
        action="append",
        help="Optional display label for a --compare-csv path. Repeat once per CSV.",
    )
    parser.add_argument(
        "--compare-run-label",
        action="append",
        help="Optional run label column value. Repeat once per compared CSV.",
    )
    parser.add_argument(
        "--compare-simulator-state",
        action="append",
        help="Optional simulator-state column value. Repeat once per compared CSV.",
    )
    parser.add_argument(
        "--compare-xcresult",
        action="append",
        type=Path,
        help="Optional xcresult bundle for a --compare-csv path. Repeat once per CSV.",
    )
    parser.add_argument(
        "--infer-xcresult",
        action="store_true",
        help="In comparison mode, read sibling .xcresult and .xcodebuild.log artifacts.",
    )
    parser.add_argument(
        "--summary-output",
        type=Path,
        help="Write the printed summary to this path. Live probes default to <csv>.summary.txt.",
    )
    parser.add_argument(
        "--manifest-output",
        type=Path,
        help="Write a JSON manifest describing probe artifacts and threshold policy.",
    )
    parser.add_argument(
        "--vmmap-summary-dir",
        type=Path,
        help="Live probes only: capture vmmap -summary snapshots for first and peak samples.",
    )
    parser.add_argument(
        "--vmmap-timeout-seconds",
        type=float,
        default=10.0,
        help="Timeout for each vmmap -summary capture.",
    )
    parser.add_argument(
        "--vmmap-peak-min-delta-mb",
        type=float,
        default=0.0,
        help="Minimum RSS increase needed before replacing the peak vmmap snapshot.",
    )
    parser.add_argument(
        "--footprint-summary-dir",
        type=Path,
        help="Live probes: capture footprint summaries/JSON. CSV analysis: read footprint-index.json from this dir.",
    )
    parser.add_argument(
        "--footprint-timeout-seconds",
        type=float,
        default=10.0,
        help="Timeout for each footprint capture.",
    )
    parser.add_argument(
        "--footprint-peak-min-delta-mb",
        type=float,
        default=0.0,
        help="Minimum RSS increase needed before replacing the peak footprint snapshot.",
    )
    parser.add_argument(
        "--footprint-capture-final",
        action="store_true",
        help="Live probes only: capture one final footprint snapshot from the last sampled PID after xcodebuild exits.",
    )
    parser.add_argument(
        "--footprint-capture-sampled-peak",
        action="store_true",
        help="Live probes only: update a sampled_peak footprint snapshot whenever a sample sets a new run-high RSS.",
    )
    parser.add_argument(
        "--footprint-latest-interval-seconds",
        type=float,
        default=0.0,
        help="Live probes only: update a latest footprint snapshot at this minimum in-run interval; 0 disables.",
    )
    parser.add_argument(
        "--footprint-final-interval-seconds",
        type=float,
        default=0.0,
        help="Live probes only: update a final footprint snapshot at this minimum in-run interval; 0 disables.",
    )
    parser.add_argument(
        "--footprint-top-categories",
        type=int,
        default=8,
        help="Number of top dirty footprint categories to print for each captured snapshot.",
    )
    parser.add_argument("--interval", type=float, default=1.0)
    parser.add_argument("--max-rss-mb", type=float)
    parser.add_argument("--max-warm-peak-rss-mb", type=float)
    parser.add_argument("--max-warm-final-rss-mb", type=float)
    parser.add_argument(
        "--rss-gate-mode",
        choices=["fail", "report"],
        default="fail",
        help="Use report to print gate failures without returning a failing exit code.",
    )
    parser.add_argument(
        "--warm-rss-floor-mb",
        type=float,
        help="Also summarize samples starting at the first RSS >= this floor.",
    )
    parser.add_argument("--developer-dir", default="/Applications/Xcode.app/Contents/Developer")
    parser.add_argument("--cwd", type=Path, default=Path.cwd())
    parser.add_argument("--replace", action="store_true")
    parser.add_argument("--verbose-xcodebuild", action="store_true")
    rss_gate_mode_was_explicit = "--rss-gate-mode" in sys.argv[1:]
    args = parser.parse_args()
    args.rss_gate_mode_was_explicit = rss_gate_mode_was_explicit

    if args.compare_manifest:
        manifest_error = apply_compare_manifests(args)
        if manifest_error:
            print(manifest_error, file=sys.stderr)
            return 2

    if args.analyze_csv and args.compare_csv:
        print(
            "--analyze-csv and --compare-csv/--compare-manifest cannot be used together",
            file=sys.stderr,
        )
        return 2

    if args.compare_csv:
        return compare_csvs(args)

    if args.analyze_csv:
        return analyze_csv(args)

    return run_probe(args)


if __name__ == "__main__":
    raise SystemExit(main())
