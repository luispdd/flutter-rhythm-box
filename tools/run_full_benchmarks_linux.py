#!/usr/bin/env python3
"""Automated benchmark script to run 5-minute recordings on Linux for Rhythm Box.

Records:
1. Sequencer loop (5 minutes, 120 BPM, 4 steps per beat, 16th notes -> nominal 125 ms).
2. Metronome loop (5 minutes, 120 BPM, 1 step per beat, quarter notes -> nominal 500 ms).
3. Loop boundary swap test (30s, swap at 15s).

Saves WAV files in recordings/ and writes timing results to recordings/linux_benchmark_results.json.
"""

import json
import os
import subprocess
import sys
import time
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent
RECORDINGS_DIR = REPO_ROOT / "recordings"
APP_BINARY = REPO_ROOT / "build/linux/x64/debug/bundle/rhythm_box"
ANALYZER_SCRIPT = REPO_ROOT / "tools/analyze_timing.py"

# Default target serial for PipeWire monitor
TARGET_SERIAL = "702"


def record_test(name: str, app_args: list[str], duration_sec: int, analyzer_args: list[str]) -> dict:
    wav_path = RECORDINGS_DIR / f"{name}.wav"
    print(f"\n=======================================================")
    print(f"Starting test: {name} (duration: {duration_sec}s)")
    print(f"Output WAV: {wav_path}")
    print(f"=======================================================")

    # 1. Start audio recording via pw-record
    rec_cmd = ["pw-record", "--target", TARGET_SERIAL, str(wav_path)]
    rec_proc = subprocess.Popen(rec_cmd, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    time.sleep(0.5)

    # 2. Run Flutter app
    app_cmd = [str(APP_BINARY)] + app_args
    print(f"Running: {' '.join(app_cmd)}")
    app_proc = subprocess.run(app_cmd, capture_output=True, text=True)
    if app_proc.returncode != 0:
        print(f"App error: {app_proc.stderr}", file=sys.stderr)

    time.sleep(0.5)
    rec_proc.terminate()
    rec_proc.wait()

    # 3. Run analyzer
    an_cmd = ["python3", str(ANALYZER_SCRIPT), str(wav_path), "--json"] + analyzer_args
    print(f"Running analyzer: {' '.join(an_cmd)}")
    an_proc = subprocess.run(an_cmd, capture_output=True, text=True)
    if an_proc.returncode not in (0, 2):
        print(f"Analyzer failed: {an_proc.stderr}", file=sys.stderr)
        raise RuntimeError(f"Analyzer error: {an_proc.stderr}")

    metrics = json.loads(an_proc.stdout)

    # Print summary report
    rep_cmd = ["python3", str(ANALYZER_SCRIPT), str(wav_path)] + analyzer_args
    rep_proc = subprocess.run(rep_cmd, capture_output=True, text=True)
    print(rep_proc.stdout)

    return metrics


def main():
    RECORDINGS_DIR.mkdir(parents=True, exist_ok=True)

    if not APP_BINARY.exists():
        print(f"Binary not found: {APP_BINARY}", file=sys.stderr)
        sys.exit(1)

    all_results = {}

    # Test 1: Sequencer 5-minute loop (305s)
    seq_results = record_test(
        name="linux_sequencer_5min",
        app_args=["sequencer", "305"],
        duration_sec=305,
        analyzer_args=["--bpm", "120", "--steps-per-beat", "4"],
    )
    all_results["sequencer_5min"] = seq_results

    # Test 2: Metronome 5-minute loop (305s)
    metro_results = record_test(
        name="linux_metronome_5min",
        app_args=["metronome", "305"],
        duration_sec=305,
        analyzer_args=["--bpm", "120", "--steps-per-beat", "1"],
    )
    all_results["metronome_5min"] = metro_results

    # Test 3: Swap test (30s total, swap at 15s)
    swap_results = record_test(
        name="linux_swap_boundary",
        app_args=["swap", "15", "30"],
        duration_sec=30,
        analyzer_args=["--bpm", "120", "--steps-per-beat", "4", "--swap-time", "15.0"],
    )
    all_results["swap_boundary"] = swap_results

    # Save aggregated results
    summary_path = RECORDINGS_DIR / "linux_benchmark_results.json"
    with open(summary_path, "w") as f:
        json.dump(all_results, f, indent=2)

    print(f"\nAll Linux benchmarks completed! Results saved to {summary_path}")


if __name__ == "__main__":
    main()
