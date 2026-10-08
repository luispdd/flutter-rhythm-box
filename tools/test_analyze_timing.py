#!/usr/bin/env python3
"""Verification tests for tools/analyze_timing.py.

Verifies:
- Task 2.1: IOI mean, std, max deviation from nominal, and cumulative drift on synthetic WAVs
  (including steady 120 BPM and deliberately jittered intervals).
- Task 2.2: Swap-boundary check (interval across a known swap time) on synthetic WAVs.
"""

import math
import os
import sys
import tempfile
import unittest
from pathlib import Path

# Ensure tools directory is in sys.path
sys.path.insert(0, str(Path(__file__).parent))

import numpy as np

from analyze_timing import (
    THRESH_DRIFT_MS,
    THRESH_MAX_DEV_MS,
    THRESH_STD_MS,
    THRESH_SWAP_DEV_MS,
    check_swap_boundary,
    compute_metrics,
    compute_sequence_metrics,
    detect_onsets,
    generate_synthetic_sequence_wav,
    generate_synthetic_wav,
    load_wav,
)


class TestTimingAnalyzer(unittest.TestCase):
    def setUp(self):
        self.temp_dir = tempfile.TemporaryDirectory()
        self.temp_path = Path(self.temp_dir.name)

    def tearDown(self):
        self.temp_dir.cleanup()

    def test_2_1_steady_synthetic_wav(self):
        """Verify perfectly timed synthetic WAV (120 BPM, 16th notes -> 125 ms nominal)."""
        wav_file = str(self.temp_path / "steady_120bpm.wav")
        duration_sec = 5.0
        nominal_ms = 125.0
        sr = 44100

        ground_truth = generate_synthetic_wav(
            output_path=wav_file,
            duration_sec=duration_sec,
            nominal_ms=nominal_ms,
            sample_rate=sr,
            jitter_ms=0.0,
            drift_rate_ppm=0.0,
        )

        audio, sample_rate = load_wav(wav_file)
        self.assertEqual(sample_rate, sr)

        onsets = detect_onsets(audio, sample_rate)
        # All onsets should be detected
        self.assertEqual(len(onsets), len(ground_truth))

        metrics = compute_metrics(
            onset_times_sec=onsets,
            nominal_ioi_ms=nominal_ms,
            sample_rate=sample_rate,
            total_samples=len(audio),
        )

        # Expected:
        # At 44.1 kHz, 1 sample is ~0.0227 ms. Quantization error <= 1 sample.
        self.assertAlmostEqual(metrics.ioi_mean_ms, nominal_ms, delta=0.05)
        self.assertLess(metrics.ioi_std_ms, 0.05)
        self.assertLess(metrics.max_dev_from_nominal_ms, 0.05)
        self.assertLess(abs(metrics.cumulative_drift_ms), 0.05)
        self.assertTrue(metrics.passed_std)
        self.assertTrue(metrics.passed_max_dev)
        self.assertTrue(metrics.passed_drift)
        self.assertTrue(metrics.overall_passed)

    def test_2_1_deliberately_jittered_wav(self):
        """Verify that a deliberately jittered synthetic WAV correctly reports jitter statistics."""
        wav_file = str(self.temp_path / "jittered.wav")
        duration_sec = 6.0
        nominal_ms = 125.0
        sr = 44100
        # Inject up to +/- 2.0 ms jitter (p2p 4.0 ms)
        jitter_p2p_ms = 4.0

        generate_synthetic_wav(
            output_path=wav_file,
            duration_sec=duration_sec,
            nominal_ms=nominal_ms,
            sample_rate=sr,
            jitter_ms=jitter_p2p_ms,
            seed=123,
        )

        audio, sample_rate = load_wav(wav_file)
        onsets = detect_onsets(audio, sample_rate)

        metrics = compute_metrics(
            onset_times_sec=onsets,
            nominal_ioi_ms=nominal_ms,
            sample_rate=sample_rate,
            total_samples=len(audio),
        )

        # Injected jitter is uniform in [-2.0, 2.0] ms.
        # Theoretical std of difference of two uniform variables U(-a, a) is sqrt(2 * a^2 / 3) = a * sqrt(2/3) ~ 1.63 ms.
        # The analyzer must detect significant standard deviation and max deviation > 1.5 ms.
        self.assertGreater(metrics.ioi_std_ms, 0.8)
        self.assertGreater(metrics.max_dev_from_nominal_ms, 1.5)
        # Mean should still center near nominal
        self.assertAlmostEqual(metrics.ioi_mean_ms, nominal_ms, delta=0.5)

        # Verify against threshold flags:
        # If std >= 1.0 ms, passed_std should be False
        if metrics.ioi_std_ms >= THRESH_STD_MS:
            self.assertFalse(metrics.passed_std)
            self.assertFalse(metrics.overall_passed)

    def test_2_1_clock_drift_synthetic_wav(self):
        """Verify cumulative drift measurement on a synthetic WAV with deliberate clock drift."""
        wav_file = str(self.temp_path / "drifting.wav")
        duration_sec = 10.0
        nominal_ms = 125.0
        sr = 44100
        # 1000 ppm drift = 0.1% slower clock -> +0.125 ms per interval.
        # In 10s (approx 80 intervals), cumulative drift should be ~10 ms.
        ppm = 1000.0

        generate_synthetic_wav(
            output_path=wav_file,
            duration_sec=duration_sec,
            nominal_ms=nominal_ms,
            sample_rate=sr,
            drift_rate_ppm=ppm,
        )

        audio, sample_rate = load_wav(wav_file)
        onsets = detect_onsets(audio, sample_rate)

        metrics = compute_metrics(
            onset_times_sec=onsets,
            nominal_ioi_ms=nominal_ms,
            sample_rate=sample_rate,
            total_samples=len(audio),
        )

        # Expected cumulative drift: ~10.0 ms
        expected_drift = (len(onsets) - 1) * nominal_ms * (ppm * 1e-6)
        self.assertAlmostEqual(metrics.cumulative_drift_ms, expected_drift, delta=0.5)
        self.assertFalse(metrics.passed_drift)
        self.assertFalse(metrics.overall_passed)

    def test_2_2_swap_boundary_check_clean(self):
        """Verify task 2.2: swap boundary check on a synthetic WAV with clean transition."""
        wav_file = str(self.temp_path / "clean_swap.wav")
        duration_sec = 4.0
        nominal_ms = 125.0
        sr = 44100
        swap_time = 2.0  # Swap occurs at 2.0s

        generate_synthetic_wav(
            output_path=wav_file,
            duration_sec=duration_sec,
            nominal_ms=nominal_ms,
            sample_rate=sr,
            swap_time_sec=swap_time,
            swap_offset_ms=0.0,  # Perfectly gapless swap
        )

        audio, sample_rate = load_wav(wav_file)
        onsets = detect_onsets(audio, sample_rate)

        swap_result = check_swap_boundary(
            onset_times_sec=onsets,
            swap_time_sec=swap_time,
            nominal_before_ms=nominal_ms,
        )

        self.assertAlmostEqual(swap_result.boundary_interval_ms, nominal_ms, delta=0.05)
        self.assertLess(swap_result.deviation_ms, 0.05)
        self.assertTrue(swap_result.passed)

        metrics = compute_metrics(
            onset_times_sec=onsets,
            nominal_ioi_ms=nominal_ms,
            sample_rate=sample_rate,
            total_samples=len(audio),
            swap_time_sec=swap_time,
        )
        self.assertIsNotNone(metrics.swap_result)
        self.assertTrue(metrics.passed_swap)
        self.assertTrue(metrics.overall_passed)

    def test_2_2_swap_boundary_check_glitch_detected(self):
        """Verify task 2.2: swap boundary check detects a glitch/gap exceeding 3 ms."""
        wav_file = str(self.temp_path / "glitch_swap.wav")
        duration_sec = 4.0
        nominal_ms = 125.0
        sr = 44100
        swap_time = 2.0
        gap_offset_ms = 5.0  # Introduce a 5.0 ms gap at swap boundary

        generate_synthetic_wav(
            output_path=wav_file,
            duration_sec=duration_sec,
            nominal_ms=nominal_ms,
            sample_rate=sr,
            swap_time_sec=swap_time,
            swap_offset_ms=gap_offset_ms,
        )

        audio, sample_rate = load_wav(wav_file)
        onsets = detect_onsets(audio, sample_rate)

        swap_result = check_swap_boundary(
            onset_times_sec=onsets,
            swap_time_sec=swap_time,
            nominal_before_ms=nominal_ms,
        )

        # Boundary interval should be 125.0 + 5.0 = 130.0 ms
        self.assertAlmostEqual(swap_result.boundary_interval_ms, 130.0, delta=0.05)
        self.assertAlmostEqual(swap_result.deviation_ms, 5.0, delta=0.05)
        # Target threshold is < 3.0 ms, so this MUST fail
        self.assertFalse(swap_result.passed)

        metrics = compute_metrics(
            onset_times_sec=onsets,
            nominal_ioi_ms=nominal_ms,
            sample_rate=sample_rate,
            total_samples=len(audio),
            swap_time_sec=swap_time,
        )
        self.assertFalse(metrics.passed_swap)
        self.assertFalse(metrics.overall_passed)

    def test_sequence_timing_clean(self):
        """Verify sequence timing analysis across multiple tempos (120:4, 140:4)."""
        wav_file = str(self.temp_path / "sequence_clean.wav")
        duration_sec = 6.0
        seq_spec = "120:4,140:4"
        sr = 44100

        ground_truth = generate_synthetic_sequence_wav(
            output_path=wav_file,
            duration_sec=duration_sec,
            sequence_spec=seq_spec,
            sample_rate=sr,
        )

        audio, sample_rate = load_wav(wav_file)
        self.assertEqual(sample_rate, sr)

        onsets = detect_onsets(audio, sample_rate)
        self.assertEqual(len(onsets), len(ground_truth))

        metrics = compute_sequence_metrics(
            onset_times_sec=onsets,
            sequence_spec=seq_spec,
            sample_rate=sample_rate,
            total_samples=len(audio),
        )

        self.assertLess(metrics.max_dev_from_nominal_ms, 0.05)
        self.assertLess(abs(metrics.cumulative_drift_ms), 0.05)
        self.assertLess(metrics.max_transition_dev_ms, 0.05)
        self.assertTrue(metrics.passed_max_dev)
        self.assertTrue(metrics.passed_drift)
        self.assertTrue(metrics.passed_sequence_transitions)
        self.assertTrue(metrics.overall_passed)


def run_all_tests() -> bool:
    suite = unittest.defaultTestLoader.loadTestsFromTestCase(TestTimingAnalyzer)
    runner = unittest.TextTestRunner(verbosity=2)
    result = runner.run(suite)
    return result.wasSuccessful()


if __name__ == "__main__":
    unittest.main()
