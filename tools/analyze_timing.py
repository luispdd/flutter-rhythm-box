#!/usr/bin/env python3
"""Timing analysis tool for Rhythm Box audio recordings.

Analyzes WAV recordings of looped playback, detects audio onsets,
and reports timing statistics against nominal intervals:
- Inter-Onset Interval (IOI) mean
- IOI standard deviation
- Maximum deviation from nominal
- Cumulative drift against the nominal timeline
- Swap boundary interval & deviation across loop transitions (Task 2.2)
- Pass/Fail verification against spec requirements (M0 Timing Spike)
"""

import argparse
import json
import math
import sys
from dataclasses import asdict, dataclass
from pathlib import Path
from typing import List, Optional, Tuple

import numpy as np
from scipy import signal
from scipy.io import wavfile


# Specification thresholds from openspec/changes/m0-timing-spike/specs/loop-timing/spec.md
THRESH_STD_MS = 1.0
THRESH_MAX_DEV_MS = 3.0
THRESH_DRIFT_MS = 5.0
THRESH_SWAP_DEV_MS = 3.0


@dataclass
class SwapBoundaryResult:
    swap_time_sec: float
    onset_before_sec: float
    onset_after_sec: float
    boundary_interval_ms: float
    nominal_interval_ms: float
    deviation_ms: float
    passed: bool


@dataclass
class TimingMetrics:
    total_samples: int
    sample_rate: int
    duration_sec: float
    onset_count: int
    nominal_ioi_ms: float
    ioi_mean_ms: float
    ioi_std_ms: float
    ioi_min_ms: float
    ioi_max_ms: float
    max_dev_from_nominal_ms: float
    cumulative_drift_ms: float
    max_drift_ms: float
    swap_result: Optional[SwapBoundaryResult]
    passed_std: bool
    passed_max_dev: bool
    passed_drift: bool
    passed_swap: Optional[bool]
    overall_passed: bool
    sequence_spec: Optional[str] = None
    sequence_transitions: Optional[List[dict]] = None
    max_transition_dev_ms: Optional[float] = None
    passed_sequence_transitions: Optional[bool] = None


def load_wav(file_path: str) -> Tuple[np.ndarray, int]:
    """Load a WAV file and return mono float64 audio data normalized to [-1, 1] and sample rate."""
    sr, data = wavfile.read(file_path)

    # Convert to float64
    if data.dtype == np.int16:
        audio = data.astype(np.float64) / 32768.0
    elif data.dtype == np.int32:
        audio = data.astype(np.float64) / 2147483648.0
    elif data.dtype == np.uint8:
        audio = (data.astype(np.float64) - 128.0) / 128.0
    elif np.issubdtype(data.dtype, np.floating):
        audio = data.astype(np.float64)
    else:
        audio = data.astype(np.float64)

    # Convert to mono if multi-channel
    if audio.ndim > 1:
        audio = np.mean(audio, axis=1)

    return audio, sr


def detect_onsets(
    audio: np.ndarray,
    sample_rate: int,
    rel_threshold: float = 0.25,
    min_distance_ms: float = 40.0,
) -> np.ndarray:
    """Detect onset sample indices from sharp click audio using peak detection.

    Args:
        audio: 1D array of audio samples.
        sample_rate: Sampling frequency in Hz.
        rel_threshold: Peak height relative to max amplitude (default 0.25).
        min_distance_ms: Minimum refractory period between onsets in ms (default 40.0).

    Returns:
        1D array of onset timestamps in seconds.
    """
    if len(audio) == 0:
        return np.array([], dtype=np.float64)

    abs_audio = np.abs(audio)
    peak_val = np.max(abs_audio)
    if peak_val <= 1e-6:
        return np.array([], dtype=np.float64)

    height = peak_val * rel_threshold
    min_dist_samples = max(1, int(sample_rate * (min_distance_ms / 1000.0)))

    peak_indices, _ = signal.find_peaks(
        abs_audio,
        height=height,
        distance=min_dist_samples,
    )

    if len(peak_indices) == 0:
        return np.array([], dtype=np.float64)

    # For each detected peak, scan back up to 2 ms to locate the leading edge
    # (first sample exceeding 20% of that peak's height) for sample-accurate onset.
    lead_window = max(1, int(sample_rate * 0.002))
    refined_indices = []
    for p in peak_indices:
        start_scan = max(0, p - lead_window)
        thresh = abs_audio[p] * 0.20
        region = abs_audio[start_scan : p + 1]
        above = np.where(region >= thresh)[0]
        if len(above) > 0:
            onset_sample = start_scan + above[0]
        else:
            onset_sample = p
        refined_indices.append(onset_sample)

    refined_indices = np.array(refined_indices, dtype=np.int64)
    return refined_indices / sample_rate


def check_swap_boundary(
    onset_times_sec: np.ndarray,
    swap_time_sec: float,
    nominal_before_ms: float,
    nominal_after_ms: Optional[float] = None,
) -> SwapBoundaryResult:
    """Check the interval across a known swap boundary.

    Args:
        onset_times_sec: Timestamps of all detected onsets in seconds.
        swap_time_sec: Nominal or logged timestamp of the swap point in seconds.
        nominal_before_ms: Nominal step interval before swap.
        nominal_after_ms: Nominal step interval after swap (default: same as before).

    Returns:
        SwapBoundaryResult with boundary interval and deviation metrics.
    """
    if nominal_after_ms is None:
        nominal_after_ms = nominal_before_ms

    # Find the last onset at or before swap_time and the first onset strictly after
    before_mask = onset_times_sec <= swap_time_sec
    after_mask = onset_times_sec > swap_time_sec

    if not np.any(before_mask) or not np.any(after_mask):
        raise ValueError(
            f"Cannot locate onsets around swap time {swap_time_sec:.3f}s. "
            f"Range of onsets is [{onset_times_sec[0]:.3f}s, {onset_times_sec[-1]:.3f}s]."
        )

    idx_before = np.where(before_mask)[0][-1]
    idx_after = np.where(after_mask)[0][0]

    t_before = onset_times_sec[idx_before]
    t_after = onset_times_sec[idx_after]

    interval_ms = (t_after - t_before) * 1000.0
    # Expected boundary interval is the duration of the final step of the prior pattern
    expected_ms = nominal_before_ms
    deviation_ms = abs(interval_ms - expected_ms)
    passed = deviation_ms < THRESH_SWAP_DEV_MS

    return SwapBoundaryResult(
        swap_time_sec=swap_time_sec,
        onset_before_sec=float(t_before),
        onset_after_sec=float(t_after),
        boundary_interval_ms=float(interval_ms),
        nominal_interval_ms=float(expected_ms),
        deviation_ms=float(deviation_ms),
        passed=bool(passed),
    )


def compute_metrics(
    onset_times_sec: np.ndarray,
    nominal_ioi_ms: float,
    sample_rate: int,
    total_samples: int,
    swap_time_sec: Optional[float] = None,
    swap_nominal_ms: Optional[float] = None,
) -> TimingMetrics:
    """Compute timing statistics and check pass/fail against requirements."""
    n = len(onset_times_sec)
    duration_sec = total_samples / sample_rate

    if n < 2:
        raise ValueError(f"Need at least 2 onsets to compute IOI metrics, found {n}")

    # Inter-Onset Intervals in ms
    iois_ms = np.diff(onset_times_sec) * 1000.0
    ioi_mean = float(np.mean(iois_ms))
    ioi_std = float(np.std(iois_ms, ddof=1)) if len(iois_ms) > 1 else 0.0
    ioi_min = float(np.min(iois_ms))
    ioi_max = float(np.max(iois_ms))

    # Deviations from nominal interval
    deviations = np.abs(iois_ms - nominal_ioi_ms)
    max_dev = float(np.max(deviations))

    # Cumulative drift against nominal timeline:
    # Expected timestamp of onset i: t_0 + i * (nominal_ms / 1000)
    nominal_step_sec = nominal_ioi_ms / 1000.0
    expected_timeline = onset_times_sec[0] + np.arange(n) * nominal_step_sec
    drifts_ms = (onset_times_sec - expected_timeline) * 1000.0
    cumulative_drift = float(drifts_ms[-1])  # Drift at final onset
    max_drift = float(np.max(np.abs(drifts_ms)))

    # Swap check if requested
    swap_res = None
    passed_swap = None
    if swap_time_sec is not None:
        swap_res = check_swap_boundary(
            onset_times_sec,
            swap_time_sec=swap_time_sec,
            nominal_before_ms=nominal_ioi_ms,
            nominal_after_ms=swap_nominal_ms,
        )
        passed_swap = swap_res.passed

    # Pass/fail against thresholds
    passed_std = ioi_std < THRESH_STD_MS
    passed_max_dev = max_dev < THRESH_MAX_DEV_MS
    passed_drift = abs(cumulative_drift) < THRESH_DRIFT_MS

    overall = passed_std and passed_max_dev and passed_drift
    if passed_swap is not None:
        overall = overall and passed_swap

    return TimingMetrics(
        total_samples=total_samples,
        sample_rate=sample_rate,
        duration_sec=duration_sec,
        onset_count=n,
        nominal_ioi_ms=nominal_ioi_ms,
        ioi_mean_ms=ioi_mean,
        ioi_std_ms=ioi_std,
        ioi_min_ms=ioi_min,
        ioi_max_ms=ioi_max,
        max_dev_from_nominal_ms=max_dev,
        cumulative_drift_ms=cumulative_drift,
        max_drift_ms=max_drift,
        swap_result=swap_res,
        passed_std=passed_std,
        passed_max_dev=passed_max_dev,
        passed_drift=passed_drift,
        passed_swap=passed_swap,
        overall_passed=overall,
    )


def generate_synthetic_wav(
    output_path: str,
    duration_sec: float,
    nominal_ms: float,
    sample_rate: int = 44100,
    jitter_ms: float = 0.0,
    drift_rate_ppm: float = 0.0,
    swap_time_sec: Optional[float] = None,
    swap_offset_ms: float = 0.0,
    seed: int = 42,
) -> List[float]:
    """Generate a synthetic WAV click track for verification and testing.

    Args:
        output_path: Path to save the synthetic WAV.
        duration_sec: Total duration in seconds.
        nominal_ms: Nominal step interval in ms.
        sample_rate: Sampling frequency in Hz.
        jitter_ms: Maximum peak-to-peak random jitter in ms.
        drift_rate_ppm: Clock drift in parts-per-million.
        swap_time_sec: If provided, a swap occurs at this time with swap_offset_ms added.
        swap_offset_ms: Offset in ms added at swap boundary.
        seed: Random seed for deterministic jitter.

    Returns:
        List of generated ground truth onset timestamps in seconds.
    """
    rng = np.random.default_rng(seed)
    total_samples = int(duration_sec * sample_rate)
    audio = np.zeros(total_samples, dtype=np.float64)

    nominal_step_sec = (nominal_ms / 1000.0) * (1.0 + drift_rate_ppm * 1e-6)
    click_dur_samples = max(2, int(sample_rate * 0.002))  # 2 ms click
    # Exponentially decaying sine burst at 2 kHz
    t_click = np.arange(click_dur_samples) / sample_rate
    click_kernel = np.sin(2 * np.pi * 2000.0 * t_click) * np.exp(-t_click / 0.0005)

    current_t = 0.050  # Start 50ms in
    ground_truth_times: List[float] = []

    while current_t < duration_sec - 0.050:
        # Determine actual time with jitter
        t_actual = current_t
        if jitter_ms > 0:
            jitter_sec = rng.uniform(-jitter_ms / 2000.0, jitter_ms / 2000.0)
            t_actual += jitter_sec

        sample_idx = int(round(t_actual * sample_rate))
        if 0 <= sample_idx < total_samples - click_dur_samples:
            ground_truth_times.append(t_actual)
            audio[sample_idx : sample_idx + click_dur_samples] += click_kernel

        # Next interval
        next_interval = nominal_step_sec
        if swap_time_sec is not None and current_t <= swap_time_sec and (current_t + nominal_step_sec) > swap_time_sec:
            # Boundary jump
            next_interval += swap_offset_ms / 1000.0

        current_t += next_interval

    # Normalize to 0.95 peak
    max_val = np.max(np.abs(audio))
    if max_val > 0:
        audio = (audio / max_val) * 0.95

    # Save 16-bit PCM WAV
    int_audio = (audio * 32767).astype(np.int16)
    wavfile.write(output_path, sample_rate, int_audio)

    return ground_truth_times


def parse_sequence_spec(spec_str: str, steps_per_beat: int = 4) -> Tuple[List[float], List[int]]:
    """Parse sequence spec string like '120:4,140:4' into cycle intervals and transition indices.

    Each item is 'BPM:STEPS'.
    Returns:
        (cycle_intervals_ms, transition_indices)
        where transition_indices are 0-based indices of intervals corresponding to entry transitions.
    """
    entries = []
    for part in spec_str.split(","):
        part = part.strip()
        if not part:
            continue
        bpm_str, steps_str = part.split(":")
        bpm = float(bpm_str)
        steps = int(steps_str)
        entries.append((bpm, steps))

    cycle_intervals: List[float] = []
    transition_indices: List[int] = []
    current_idx = 0
    for bpm, steps in entries:
        nominal_step_ms = (60.0 / bpm / steps_per_beat) * 1000.0
        for _ in range(steps):
            cycle_intervals.append(nominal_step_ms)
        current_idx += steps
        transition_indices.append(current_idx - 1)

    return cycle_intervals, transition_indices


def compute_sequence_metrics(
    onset_times_sec: np.ndarray,
    sequence_spec: str,
    sample_rate: int,
    total_samples: int,
    steps_per_beat: int = 4,
) -> TimingMetrics:
    """Compute timing statistics across a sequence of patterns with different tempos."""
    n = len(onset_times_sec)
    duration_sec = total_samples / sample_rate
    if n < 2:
        raise ValueError(f"Need at least 2 onsets to compute sequence timing metrics, found {n}")

    cycle_intervals, transition_indices = parse_sequence_spec(sequence_spec, steps_per_beat)
    k = len(cycle_intervals)
    iois_ms = np.diff(onset_times_sec) * 1000.0

    # Determine best starting phase
    check_len = min(len(iois_ms), 64)
    best_phase = 0
    best_err = float("inf")
    for p in range(k):
        err = float(np.sum([abs(iois_ms[i] - cycle_intervals[(p + i) % k]) for i in range(check_len)]))
        if err < best_err:
            best_err = err
            best_phase = p

    nominal_iois_ms = np.array([cycle_intervals[(best_phase + i) % k] for i in range(len(iois_ms))], dtype=np.float64)
    deviations_ms = np.abs(iois_ms - nominal_iois_ms)
    max_dev = float(np.max(deviations_ms))

    # Transitions
    transition_devs: List[float] = []
    transitions_data: List[dict] = []
    for i in range(len(iois_ms)):
        phase_in_cycle = (best_phase + i) % k
        if phase_in_cycle in transition_indices:
            dev = float(deviations_ms[i])
            transition_devs.append(dev)
            transitions_data.append({
                "interval_index": i,
                "onset_before_sec": float(onset_times_sec[i]),
                "onset_after_sec": float(onset_times_sec[i + 1]),
                "interval_ms": float(iois_ms[i]),
                "nominal_ms": float(nominal_iois_ms[i]),
                "deviation_ms": dev,
                "passed": dev < THRESH_MAX_DEV_MS,
            })

    max_trans_dev = float(np.max(transition_devs)) if transition_devs else 0.0

    # Cumulative drift timeline
    expected_timeline = np.zeros(n, dtype=np.float64)
    expected_timeline[0] = onset_times_sec[0]
    for i in range(len(nominal_iois_ms)):
        expected_timeline[i + 1] = expected_timeline[i] + (nominal_iois_ms[i] / 1000.0)

    drifts_ms = (onset_times_sec - expected_timeline) * 1000.0
    cumulative_drift = float(drifts_ms[-1])
    max_drift = float(np.max(np.abs(drifts_ms)))

    ioi_mean = float(np.mean(iois_ms))
    ioi_std = float(np.std(deviations_ms, ddof=1)) if len(deviations_ms) > 1 else 0.0

    passed_std = ioi_std < THRESH_STD_MS
    passed_max_dev = max_dev < THRESH_MAX_DEV_MS
    passed_drift = abs(cumulative_drift) < THRESH_DRIFT_MS
    passed_transitions = max_trans_dev < THRESH_MAX_DEV_MS
    overall = passed_max_dev and passed_drift and passed_transitions

    return TimingMetrics(
        total_samples=total_samples,
        sample_rate=sample_rate,
        duration_sec=duration_sec,
        onset_count=n,
        nominal_ioi_ms=float(np.mean(cycle_intervals)),
        ioi_mean_ms=ioi_mean,
        ioi_std_ms=ioi_std,
        ioi_min_ms=float(np.min(iois_ms)),
        ioi_max_ms=float(np.max(iois_ms)),
        max_dev_from_nominal_ms=max_dev,
        cumulative_drift_ms=cumulative_drift,
        max_drift_ms=max_drift,
        swap_result=None,
        passed_std=passed_std,
        passed_max_dev=passed_max_dev,
        passed_drift=passed_drift,
        passed_swap=None,
        overall_passed=overall,
        sequence_spec=sequence_spec,
        sequence_transitions=transitions_data,
        max_transition_dev_ms=max_trans_dev,
        passed_sequence_transitions=passed_transitions,
    )


def generate_synthetic_sequence_wav(
    output_path: str,
    duration_sec: float,
    sequence_spec: str,
    sample_rate: int = 44100,
    steps_per_beat: int = 4,
    jitter_ms: float = 0.0,
    seed: int = 42,
) -> List[float]:
    """Generate a synthetic WAV click track for a looping sequence with multiple tempos."""
    rng = np.random.default_rng(seed)
    total_samples = int(duration_sec * sample_rate)
    audio = np.zeros(total_samples, dtype=np.float64)

    cycle_intervals, _ = parse_sequence_spec(sequence_spec, steps_per_beat)
    k = len(cycle_intervals)

    click_dur_samples = max(2, int(sample_rate * 0.002))
    t_click = np.arange(click_dur_samples) / sample_rate
    click_kernel = np.sin(2 * np.pi * 2000.0 * t_click) * np.exp(-t_click / 0.0005)

    current_t = 0.050
    ground_truth_times: List[float] = []
    step_idx = 0

    while current_t < duration_sec - 0.050:
        t_actual = current_t
        if jitter_ms > 0:
            jitter_sec = rng.uniform(-jitter_ms / 2000.0, jitter_ms / 2000.0)
            t_actual += jitter_sec

        sample_idx = int(round(t_actual * sample_rate))
        if 0 <= sample_idx < total_samples - click_dur_samples:
            ground_truth_times.append(t_actual)
            audio[sample_idx : sample_idx + click_dur_samples] += click_kernel

        next_interval_sec = cycle_intervals[step_idx % k] / 1000.0
        current_t += next_interval_sec
        step_idx += 1

    max_val = np.max(np.abs(audio))
    if max_val > 0:
        audio = (audio / max_val) * 0.95

    int_audio = (audio * 32767).astype(np.int16)
    wavfile.write(output_path, sample_rate, int_audio)

    return ground_truth_times


def print_report(metrics: TimingMetrics, wav_path: str):
    """Print human-readable measurement report to stdout."""
    print("=" * 68)
    print(f"RHYTHM BOX TIMING SPIKE REPORT: {Path(wav_path).name}")
    print("=" * 68)
    print(f"File duration:     {metrics.duration_sec:.2f} s ({metrics.duration_sec/60:.2f} min)")
    print(f"Sample rate:       {metrics.sample_rate} Hz")
    print(f"Detected onsets:   {metrics.onset_count}")
    print(f"Nominal IOI:       {metrics.nominal_ioi_ms:.3f} ms")
    print("-" * 68)
    print(f"IOI Mean:          {metrics.ioi_mean_ms:10.3f} ms")
    print(f"IOI Min:           {metrics.ioi_min_ms:10.3f} ms")
    print(f"IOI Max:           {metrics.ioi_max_ms:10.3f} ms")
    print("-" * 68)

    std_pass_str = "PASS" if metrics.passed_std else "FAIL"
    print(f"IOI Std Dev:       {metrics.ioi_std_ms:10.3f} ms  (Target: < {THRESH_STD_MS:.1f} ms)  [{std_pass_str}]")

    max_dev_pass_str = "PASS" if metrics.passed_max_dev else "FAIL"
    print(f"Max Deviation:     {metrics.max_dev_from_nominal_ms:10.3f} ms  (Target: < {THRESH_MAX_DEV_MS:.1f} ms)  [{max_dev_pass_str}]")

    drift_pass_str = "PASS" if metrics.passed_drift else "FAIL"
    print(f"Cumulative Drift:  {metrics.cumulative_drift_ms:10.3f} ms  (Target: < {THRESH_DRIFT_MS:.1f} ms)  [{drift_pass_str}]")
    print(f"Peak Abs Drift:    {metrics.max_drift_ms:10.3f} ms")

    if metrics.swap_result is not None:
        sr = metrics.swap_result
        swap_pass_str = "PASS" if sr.passed else "FAIL"
        print("-" * 68)
        print("SWAP BOUNDARY CHECK:")
        print(f"  Swap time logged: {sr.swap_time_sec:.3f} s")
        print(f"  Onset before:     {sr.onset_before_sec:.3f} s")
        print(f"  Onset after:      {sr.onset_after_sec:.3f} s")
        print(f"  Boundary IOI:     {sr.boundary_interval_ms:.3f} ms (Nominal: {sr.nominal_interval_ms:.3f} ms)")
        print(f"  Boundary dev:     {sr.deviation_ms:.3f} ms  (Target: < {THRESH_SWAP_DEV_MS:.1f} ms)  [{swap_pass_str}]")

    if metrics.sequence_spec is not None:
        trans_pass_str = "PASS" if metrics.passed_sequence_transitions else "FAIL"
        print("-" * 68)
        print("SEQUENCE TRANSITIONS CHECK:")
        print(f"  Sequence spec:       {metrics.sequence_spec}")
        print(f"  Total transitions:   {len(metrics.sequence_transitions or [])}")
        print(f"  Max transition dev:  {metrics.max_transition_dev_ms:10.3f} ms  (Target: < {THRESH_MAX_DEV_MS:.1f} ms)  [{trans_pass_str}]")

    print("=" * 68)
    verdict = "PASSED" if metrics.overall_passed else "FAILED"
    print(f"OVERALL SPIKE VERDICT: {verdict}")
    print("=" * 68)


def parse_args():
    parser = argparse.ArgumentParser(
        description="Analyze timing stability and drift of audio recordings for Rhythm Box."
    )
    parser.add_argument(
        "wav_file",
        nargs="?",
        help="Path to WAV audio file to analyze.",
    )
    parser.add_argument(
        "--bpm",
        type=float,
        default=None,
        help="Tempo in BPM (e.g. 120.0).",
    )
    parser.add_argument(
        "--steps-per-beat",
        type=int,
        default=4,
        help="Steps per beat (default: 4 for 16th notes sequencer; 1 for metronome beats).",
    )
    parser.add_argument(
        "--nominal-ms",
        type=float,
        default=None,
        help="Explicit nominal IOI in ms (overrides --bpm and --steps-per-beat).",
    )
    parser.add_argument(
        "--swap-time",
        type=float,
        default=None,
        help="Known swap timestamp in seconds to verify loop boundary interval.",
    )
    parser.add_argument(
        "--swap-nominal-ms",
        type=float,
        default=None,
        help="Nominal interval after swap in ms if different from before.",
    )
    parser.add_argument(
        "--sequence",
        type=str,
        default=None,
        help="Sequence specification string, e.g. '120:4,140:4' (BPM:steps for each pattern entry in loop).",
    )
    parser.add_argument(
        "--min-distance-ms",
        type=float,
        default=None,
        help="Minimum refractory period between onsets in ms (default: auto derived from sequence/tempo).",
    )
    parser.add_argument(
        "--rel-threshold",
        type=float,
        default=0.25,
        help="Relative onset detection threshold [0.0 - 1.0] (default: 0.25).",
    )
    parser.add_argument(
        "--json",
        action="store_true",
        help="Output results in JSON format.",
    )
    parser.add_argument(
        "--self-test",
        action="store_true",
        help="Run self-verification test on synthetic audio with known timing.",
    )
    return parser.parse_args()


def main():
    args = parse_args()

    if args.self_test:
        from test_analyze_timing import run_all_tests
        success = run_all_tests()
        sys.exit(0 if success else 1)

    if not args.wav_file:
        print("Error: wav_file argument required (or run with --self-test).", file=sys.stderr)
        sys.exit(1)

    # Calculate nominal IOI
    if args.nominal_ms is not None:
        nominal_ms = args.nominal_ms
    elif args.bpm is not None:
        nominal_ms = (60.0 / args.bpm / args.steps_per_beat) * 1000.0
    else:
        # Default: 120 BPM with 4 steps per beat = 125 ms
        nominal_ms = 125.0

    if args.min_distance_ms is not None:
        min_dist = args.min_distance_ms
    elif args.sequence:
        cycle_intervals, _ = parse_sequence_spec(args.sequence, args.steps_per_beat)
        min_dist = max(40.0, min(cycle_intervals) * 0.6)
    else:
        min_dist = 40.0

    audio, sr = load_wav(args.wav_file)
    onsets = detect_onsets(audio, sr, rel_threshold=args.rel_threshold, min_distance_ms=min_dist)

    if args.sequence:
        metrics = compute_sequence_metrics(
            onset_times_sec=onsets,
            sequence_spec=args.sequence,
            sample_rate=sr,
            total_samples=len(audio),
            steps_per_beat=args.steps_per_beat,
        )
    else:
        metrics = compute_metrics(
            onset_times_sec=onsets,
            nominal_ioi_ms=nominal_ms,
            sample_rate=sr,
            total_samples=len(audio),
            swap_time_sec=args.swap_time,
            swap_nominal_ms=args.swap_nominal_ms,
        )

    if args.json:
        data = asdict(metrics)
        print(json.dumps(data, indent=2))
    else:
        print_report(metrics, args.wav_file)

    if not metrics.overall_passed:
        sys.exit(2)


if __name__ == "__main__":
    main()
