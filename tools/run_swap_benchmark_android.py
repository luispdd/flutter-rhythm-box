#!/usr/bin/env python3
"""Automated script to record and analyze the Android swap test on the emulator.

Records audio output directly from qemu-system-x86_64 via PipeWire (pw-link) while running tools/android_swap_benchmark.dart.
Detects the exact swap point (first onset + 15.0s) and runs tools/analyze_timing.py.
"""

import json
import os
import subprocess
import sys
import time
from pathlib import Path

import numpy as np

REPO_ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(REPO_ROOT / "tools"))
RECORDINGS_DIR = REPO_ROOT / "recordings"
WAV_PATH = RECORDINGS_DIR / "android_swap_boundary.wav"
ANALYZER_SCRIPT = REPO_ROOT / "tools/analyze_timing.py"
BENCHMARK_DART = REPO_ROOT / "tools/android_swap_benchmark.dart"


def main():
    RECORDINGS_DIR.mkdir(parents=True, exist_ok=True)
    if WAV_PATH.exists():
        WAV_PATH.unlink()

    print("=======================================================")
    print("Starting Android Swap Benchmark recording on emulator")
    print(f"Output WAV: {WAV_PATH}")
    print("=======================================================")

    # 1. Start audio recording with unlinked target
    rec_cmd = ["pw-record", "--target", "0", str(WAV_PATH)]
    print(f"Starting recorder: {' '.join(rec_cmd)}")
    rec_proc = subprocess.Popen(rec_cmd, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    time.sleep(0.3)

    # Link directly to qemu output ports
    print("Linking pw-record directly to qemu-system-x86_64 audio ports...")
    subprocess.run(["pw-link", "qemu-system-x86_64:output_FL", "pw-record:input_FL"], check=False)
    subprocess.run(["pw-link", "qemu-system-x86_64:output_FR", "pw-record:input_FR"], check=False)

    # 2. Run Flutter app on Android emulator
    app_cmd = [
        "flutter",
        "run",
        "-d",
        "emulator-5554",
        "-t",
        str(BENCHMARK_DART),
    ]
    print(f"Launching app: {' '.join(app_cmd)}")
    app_proc = subprocess.run(app_cmd, capture_output=True, text=True)

    time.sleep(1.0)
    rec_proc.terminate()
    try:
        rec_proc.wait(timeout=5)
    except subprocess.TimeoutExpired:
        rec_proc.kill()

    print("\nFlutter run completed.")
    print("STDOUT tail:")
    for line in app_proc.stdout.splitlines()[-15:]:
        print("  ", line)

    if not WAV_PATH.exists() or WAV_PATH.stat().st_size == 0:
        print(f"Error: Recording file {WAV_PATH} was not generated or is empty.", file=sys.stderr)
        sys.exit(1)

    print(f"\nRecording size: {WAV_PATH.stat().st_size} bytes")

    # 3. Detect onsets to determine precise swap time
    from analyze_timing import load_wav, detect_onsets

    audio, sr = load_wav(str(WAV_PATH))
    print(f"Loaded audio: sample_rate={sr}, length={len(audio)}, max_amp={np.max(np.abs(audio)):.4f}")
    onsets = detect_onsets(audio, sr)
    print(f"Detected {len(onsets)} onsets in recording.")
    if len(onsets) < 10:
        print("Error: Too few onsets detected in Android recording.", file=sys.stderr)
        sys.exit(1)

    first_onset = onsets[0]
    # Swap requested 15.0 seconds after start
    estimated_swap_time = first_onset + 15.0
    print(f"First onset: {first_onset:.3f}s. Estimated swap time: {estimated_swap_time:.3f}s")

    # 4. Run analyze_timing.py with calculated swap time
    an_cmd = [
        "python3",
        str(ANALYZER_SCRIPT),
        str(WAV_PATH),
        "--bpm",
        "120",
        "--steps-per-beat",
        "4",
        "--swap-time",
        f"{estimated_swap_time:.4f}",
        "--json",
    ]
    print(f"\nRunning analyzer: {' '.join(an_cmd)}")
    an_proc = subprocess.run(an_cmd, capture_output=True, text=True)
    if an_proc.returncode not in (0, 2):
        print(f"Analyzer failed with code {an_proc.returncode}:\n{an_proc.stderr}", file=sys.stderr)
        sys.exit(an_proc.returncode)

    metrics = json.loads(an_proc.stdout)

    # Pretty print analyzer report
    rep_cmd = [
        "python3",
        str(ANALYZER_SCRIPT),
        str(WAV_PATH),
        "--bpm",
        "120",
        "--steps-per-beat",
        "4",
        "--swap-time",
        f"{estimated_swap_time:.4f}",
    ]
    rep_proc = subprocess.run(rep_cmd, capture_output=True, text=True)
    print(rep_proc.stdout)

    # Save metrics to json file
    result_path = RECORDINGS_DIR / "android_swap_benchmark_results.json"
    with open(result_path, "w") as f:
        json.dump(metrics, f, indent=2)

    print(f"Results saved to {result_path}")
    if metrics.get("overall_passed"):
        print("\nSUCCESS: All timing and swap criteria PASSED!")
    else:
        print("\nWARNING: Some criteria did not meet threshold!")


if __name__ == "__main__":
    main()
