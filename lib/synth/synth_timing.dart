/// Pure-Dart timing and rounding utility for step sequencer and metronome loops.
///
/// Follows Design D1 & D2:
/// - Default sample rate is 44100 Hz.
/// - 4 steps per beat (16th notes).
/// - samplesPerStep = (sampleRate * 60.0) / (bpm * stepsPerBeat).
/// - samplesPerBeat = (sampleRate * 60.0) / bpm.
/// - Onset of step i at `round(i * samplesPerStep)`.
/// - Loop length for stepCount steps at `round(stepCount * samplesPerStep)`.
/// - Onset of metronome beat i at `round(i * samplesPerBeat)`.
/// - Metronome bar length for beatsPerBar beats at `round(beatsPerBar * samplesPerBeat)`.
/// - Non-cumulative rounding guarantees sample-accurate timing across loop boundaries.
class SynthTiming {
  /// Default audio sampling rate in Hz.
  static const int defaultSampleRate = 44100;

  /// Constant steps per beat (16th notes in 4/4 time).
  static const int stepsPerBeat = 4;

  final int sampleRate;

  const SynthTiming({this.sampleRate = defaultSampleRate});

  /// Computes the exact number of audio samples per 16th-note step for a given BPM.
  double samplesPerStep(double bpm) {
    if (bpm <= 0) {
      throw ArgumentError.value(bpm, 'bpm', 'BPM must be positive');
    }
    return (sampleRate * 60.0) / (bpm * stepsPerBeat);
  }

  /// Computes the exact number of audio samples per beat for a given BPM.
  double samplesPerBeat(double bpm) {
    if (bpm <= 0) {
      throw ArgumentError.value(bpm, 'bpm', 'BPM must be positive');
    }
    return (sampleRate * 60.0) / bpm;
  }

  /// Calculates the onset sample index for step [stepIndex] at tempo [bpm].
  ///
  /// Uses rounding rule: `round(stepIndex * samplesPerStep)`.
  int onsetSampleForStep(int stepIndex, double bpm) {
    if (stepIndex < 0) {
      throw ArgumentError.value(stepIndex, 'stepIndex', 'stepIndex must be non-negative');
    }
    return (stepIndex * samplesPerStep(bpm)).round();
  }

  /// Calculates the onset sample index for metronome beat [beatIndex] at tempo [bpm].
  ///
  /// Uses rounding rule: `round(beatIndex * samplesPerBeat)`.
  int onsetSampleForBeat(int beatIndex, double bpm) {
    if (beatIndex < 0) {
      throw ArgumentError.value(beatIndex, 'beatIndex', 'beatIndex must be non-negative');
    }
    return (beatIndex * samplesPerBeat(bpm)).round();
  }

  /// Calculates the total loop length in samples for [stepCount] steps at tempo [bpm].
  ///
  /// Uses rounding rule: `round(stepCount * samplesPerStep)`.
  int loopLengthSamples(int stepCount, double bpm) {
    if (stepCount <= 0) {
      throw ArgumentError.value(stepCount, 'stepCount', 'stepCount must be positive');
    }
    return (stepCount * samplesPerStep(bpm)).round();
  }

  /// Calculates the metronome bar length in samples for [beatsPerBar] beats at tempo [bpm].
  ///
  /// Uses rounding rule: `round(beatsPerBar * samplesPerBeat)`.
  int metronomeBarLengthSamples(int beatsPerBar, double bpm) {
    if (beatsPerBar <= 0) {
      throw ArgumentError.value(beatsPerBar, 'beatsPerBar', 'beatsPerBar must be positive');
    }
    return (beatsPerBar * samplesPerBeat(bpm)).round();
  }

  /// Calculates the onset indices for all steps from 0 to [stepCount] - 1.
  List<int> calculateStepOnsetIndices(int stepCount, double bpm) {
    return List<int>.generate(
      stepCount,
      (i) => onsetSampleForStep(i, bpm),
      growable: false,
    );
  }

  /// Calculates the onset indices for all beats from 0 to [beatsPerBar] - 1.
  List<int> calculateBeatOnsetIndices(int beatsPerBar, double bpm) {
    return List<int>.generate(
      beatsPerBar,
      (i) => onsetSampleForBeat(i, bpm),
      growable: false,
    );
  }
}
