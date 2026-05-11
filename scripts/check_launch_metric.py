#!/usr/bin/env python3
"""Gate Xcode XCTApplicationLaunchMetric values from an xcresult bundle."""

from __future__ import annotations

import argparse
import ast
import csv
import subprocess
import sys
import tempfile
from dataclasses import dataclass
from pathlib import Path


APP_LAUNCH_AVERAGE_COLUMN = "Duration (AppLaunch) (Average)"
APP_LAUNCH_ITERATIONS_COLUMN = "Duration (AppLaunch) (Iterations)"


@dataclass(frozen=True)
class LaunchMetric:
    destination: str
    configuration: str
    average_seconds: float
    iterations_seconds: list[float]
    source: Path

    @property
    def max_iteration_seconds(self) -> float:
        return max(self.iterations_seconds, default=0)


def parse_duration(value: str) -> float:
    cleaned = value.strip()
    if cleaned.endswith(" s"):
        cleaned = cleaned[:-2]
    return float(cleaned)


def parse_iterations(value: str) -> list[float]:
    parsed = ast.literal_eval(value)
    if not isinstance(parsed, list):
        raise ValueError(f"Expected iteration list, got {value!r}")
    return [float(item) for item in parsed]


def export_metrics(xcresult_path: Path, output_path: Path) -> None:
    command = [
        "xcrun",
        "xcresulttool",
        "export",
        "metrics",
        "--path",
        str(xcresult_path),
        "--output-path",
        str(output_path),
    ]
    completed = subprocess.run(command, check=False, text=True, capture_output=True)
    if completed.returncode != 0:
        sys.stderr.write(completed.stderr)
        sys.stderr.write(completed.stdout)
        raise SystemExit(completed.returncode)


def load_launch_metrics(metrics_dir: Path) -> list[LaunchMetric]:
    metrics: list[LaunchMetric] = []

    for csv_path in sorted(metrics_dir.glob("*.csv")):
        with csv_path.open(newline="", encoding="utf-8") as csv_file:
            for row in csv.DictReader(csv_file):
                average = row.get(APP_LAUNCH_AVERAGE_COLUMN)
                iterations = row.get(APP_LAUNCH_ITERATIONS_COLUMN)
                if not average or not iterations:
                    continue

                metrics.append(
                    LaunchMetric(
                        destination=row.get("Destination", "unknown"),
                        configuration=row.get("Configuration", "unknown"),
                        average_seconds=parse_duration(average),
                        iterations_seconds=parse_iterations(iterations),
                        source=csv_path,
                    )
                )

    return metrics


def format_seconds(values: list[float]) -> str:
    return ", ".join(f"{value:.3f}" for value in values)


def check_metrics(
    metrics: list[LaunchMetric],
    max_average_seconds: float,
    max_iteration_seconds: float | None,
) -> int:
    if not metrics:
        print("No XCTApplicationLaunchMetric rows found.", file=sys.stderr)
        return 2

    exit_code = 0

    for metric in metrics:
        print(
            f"{metric.destination} / {metric.configuration}: "
            f"average={metric.average_seconds:.3f}s, "
            f"max_iteration={metric.max_iteration_seconds:.3f}s, "
            f"iterations=[{format_seconds(metric.iterations_seconds)}]"
        )

        if metric.average_seconds > max_average_seconds:
            print(
                f"FAIL: average {metric.average_seconds:.3f}s exceeded "
                f"{max_average_seconds:.3f}s",
                file=sys.stderr,
            )
            exit_code = 1

        if (
            max_iteration_seconds is not None
            and metric.max_iteration_seconds > max_iteration_seconds
        ):
            print(
                f"FAIL: max iteration {metric.max_iteration_seconds:.3f}s exceeded "
                f"{max_iteration_seconds:.3f}s",
                file=sys.stderr,
            )
            exit_code = 1

    return exit_code


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Export and gate XCTApplicationLaunchMetric values from an xcresult bundle."
    )
    parser.add_argument("--xcresult", required=True, type=Path, help="Path to .xcresult bundle")
    parser.add_argument(
        "--max-average",
        required=True,
        type=float,
        help="Maximum allowed average app launch duration in seconds",
    )
    parser.add_argument(
        "--max-iteration",
        type=float,
        help="Optional maximum allowed single launch iteration in seconds",
    )
    args = parser.parse_args()

    xcresult_path = args.xcresult.expanduser().resolve()
    if not xcresult_path.exists():
        print(f"xcresult bundle does not exist: {xcresult_path}", file=sys.stderr)
        return 2

    with tempfile.TemporaryDirectory(prefix="imposter-launch-metrics-") as temp_dir:
        metrics_dir = Path(temp_dir)
        export_metrics(xcresult_path, metrics_dir)
        metrics = load_launch_metrics(metrics_dir)
        return check_metrics(
            metrics,
            max_average_seconds=args.max_average,
            max_iteration_seconds=args.max_iteration,
        )


if __name__ == "__main__":
    raise SystemExit(main())
