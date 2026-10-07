import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:rhythm_box/domain/audio_buffer.dart';

import 'fake_audio_engine.dart';

AudioBuffer _createDummyBuffer(int id, {Duration duration = const Duration(seconds: 2)}) {
  return AudioBuffer(
    wavBytes: Uint8List.fromList([id]),
    pcmSamples: Int16List(0),
    sampleRate: 44100,
    totalSamples: 88200,
    duration: duration,
  );
}

void main() {
  group('FakeAudioEngine', () {
    test('records startLoop and sets playing state and audible buffer', () async {
      final engine = FakeAudioEngine();
      final buf1 = _createDummyBuffer(1);

      expect(engine.isPlaying, isFalse);
      expect(engine.audibleBuffer, isNull);

      await engine.startLoop(buf1);

      expect(engine.isPlaying, isTrue);
      expect(engine.startLoopCalls, equals(1));
      expect(engine.audibleBuffer, equals(buf1));
      expect(engine.pendingBuffer, isNull);
      expect(engine.lastStartedBuffer, equals(buf1));
    });

    test('exercises swap, latest-wins, and boundary promotion', () async {
      final engine = FakeAudioEngine();
      final bufA = _createDummyBuffer(1);
      final bufB = _createDummyBuffer(2);
      final bufC = _createDummyBuffer(3);
      final bufD = _createDummyBuffer(4);

      await engine.startLoop(bufA);
      expect(engine.audibleBuffer, equals(bufA));

      // Swap once: bufB is pending, bufA remains audible
      await engine.swapLoopAtBoundary(bufB);
      expect(engine.swapLoopCalls, equals(1));
      expect(engine.audibleBuffer, equals(bufA));
      expect(engine.pendingBuffer, equals(bufB));

      // Multiple rapid swaps before boundary: latest-wins
      await engine.swapLoopAtBoundary(bufC);
      await engine.swapLoopAtBoundary(bufD);
      expect(engine.swapLoopCalls, equals(3));
      expect(engine.audibleBuffer, equals(bufA)); // audible loop is not cut early
      expect(engine.pendingBuffer, equals(bufD)); // bufD replaced bufB and bufC
      expect(engine.lastSwappedBuffer, equals(bufD));

      // Simulating loop boundary promotes latest pending buffer
      engine.triggerBoundary();
      expect(engine.audibleBuffer, equals(bufD));
      expect(engine.pendingBuffer, isNull);
    });

    test('exercises stop immediately ceasing sound and clearing state', () async {
      final engine = FakeAudioEngine();
      final bufA = _createDummyBuffer(1);
      final bufB = _createDummyBuffer(2);

      await engine.startLoop(bufA);
      await engine.swapLoopAtBoundary(bufB);
      expect(engine.isPlaying, isTrue);
      expect(engine.pendingBuffer, equals(bufB));

      // Immediate stop
      await engine.stop();
      expect(engine.isPlaying, isFalse);
      expect(engine.stopCalls, equals(1));
      expect(engine.audibleBuffer, isNull);
      expect(engine.pendingBuffer, isNull);
    });

    test('swap when stopped starts playback directly', () async {
      final engine = FakeAudioEngine();
      final bufA = _createDummyBuffer(1);

      await engine.swapLoopAtBoundary(bufA);
      expect(engine.isPlaying, isTrue);
      expect(engine.startLoopCalls, equals(1));
      expect(engine.audibleBuffer, equals(bufA));
      expect(engine.pendingBuffer, isNull);
    });
  });
}
