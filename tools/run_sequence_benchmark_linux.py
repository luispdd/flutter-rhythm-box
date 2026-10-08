#!/usr/bin/env python3
"""Automated script to record and analyze a 5-minute looping sequence on Linux.

Runs the sequence CLI mode (Pattern A 120 BPM, Pattern B 140 BPM) for 305 seconds,
records via PipeWire (pw-record linked to default sink monitor),
and runs tools/analyze_timing.py with --sequence 120:4,140:4.
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


def get_default_sink_name() -> str:
    name_env = os.environ.get("TARGET_SINK")
    if name_env:
        return name_env
    try:
        out = subprocess.check_output(["wpctl", "status"], text=True)
        in_sinks = False
        node_id = None
        for line in out.splitlines():
            if "Sinks:" in line:
                in_sinks = True
                continue
            if in_sinks:
                if "Sources:" in line or "Devices:" in line:
                    break
                if "*" in line:
                    parts = line.strip().lstrip("│").strip().lstrip("*").strip().split(".")
                    node_id = parts[0].strip()
                    break
        if node_id:
            info = subprocess.check_output(["pw-cli", "info", node_id], text=True)
            for iline in info.splitlines():
                if "node.name =" in iline:
                    return iline.split("=")[1].strip().strip('"')
    except Exception:
        pass
    return "alsa_output.pci-0000_00_1f.3-platform-skl_hda_dsp_generic.HiFi__HDMI1__sink"


def main():
    RECORDINGS_DIR.mkdir(parents=True, exist_ok=True)
    if not APP_BINARY.exists():
        print(f"Binary not found: {APP_BINARY}", file=sys.stderr)
        sys.exit(1)

    duration_sec = 305
    wav_path = RECORDINGS_DIR / "linux_sequence_5min.wav"
    results_path = RECORDINGS_DIR / "linux_sequence_5min_results.json"

    print("=======================================================")
    print(f"Starting Linux 5-minute Sequence Benchmark (duration: {duration_sec}s)")
    print(f"Output WAV: {wav_path}")
    print("=======================================================")

    # 1. Start audio recording via pw-record targeting unlinked input, then link to active sink monitor
    rec_cmd = ["pw-record", "--latency", "250ms", "--target", "0", str(wav_path)]
    rec_proc = subprocess.Popen(rec_cmd, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    time.sleep(0.3)
    sink_prefix = get_default_sink_name()
    print(f"Linking to sink: {sink_prefix}")
    subprocess.run(["pw-link", f"{sink_prefix}:monitor_FL", "pw-record:input_FL"], capture_output=True)
    subprocess.run(["pw-link", f"{sink_prefix}:monitor_FR", "pw-record:input_FR"], capture_output=True)

    # 2. Run Flutter app in sequence mode
    app_cmd = [str(APP_BINARY), "sequence", str(duration_sec)]
    print(f"Running: {' '.join(app_cmd)}")
    app_proc = subprocess.run(app_cmd, capture_output=True, text=True)
    if app_proc.returncode != 0:
        print(f"App error: {app_proc.stderr}", file=sys.stderr)

    time.sleep(0.5)
    rec_proc.terminate()
    rec_proc.wait()

    # 3. Run analyzer
    an_cmd = [
        "python3",
        str(ANALYZER_SCRIPT),
        str(wav_path),
        "--sequence",
        "120:4,140:4",
        "--json",
    ]
    print(f"Running analyzer: {' '.join(an_cmd)}")
    an_proc = subprocess.run(an_cmd, capture_output=True, text=True)
    if an_proc.returncode not in (0, 2):
        print(f"Analyzer failed: {an_proc.stderr}", file=sys.stderr)
        raise RuntimeError(f"Analyzer error: {an_proc.stderr}")

    metrics = json.loads(an_proc.stdout)
    with open(results_path, "w") as f:
        json.dump(metrics, f, indent=2)

    # Print summary report
    rep_cmd = [
        "python3",
        str(ANALYZER_SCRIPT),
        str(wav_path),
        "--sequence",
        "120:4,140:4",
    ]
    rep_proc = subprocess.run(rep_cmd, capture_output=True, text=True)
    print(rep_proc.stdout)

    print(f"Results saved to {results_path}")
    if not metrics.get("overall_passed", False):
        sys.exit(2)


if __name__ == "__main__":
    main()
