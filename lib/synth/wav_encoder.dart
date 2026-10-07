import 'dart:typed_data';

/// Encodes 16-bit mono PCM samples into a standard 44-byte RIFF/WAVE header container.
Uint8List encodeWav(Int16List pcmSamples, {int sampleRate = 44100}) {
  const numChannels = 1;
  const bitsPerSample = 16;
  final byteRate = sampleRate * numChannels * (bitsPerSample ~/ 8);
  final blockAlign = numChannels * (bitsPerSample ~/ 8);
  final dataSize = pcmSamples.length * 2;
  final fileSize = 36 + dataSize;

  final bytes = Uint8List(44 + dataSize);
  final bdata = ByteData.sublistView(bytes);

  // RIFF header
  bytes.setRange(0, 4, 'RIFF'.codeUnits);
  bdata.setUint32(4, fileSize, Endian.little);
  bytes.setRange(8, 12, 'WAVE'.codeUnits);

  // fmt subchunk
  bytes.setRange(12, 16, 'fmt '.codeUnits);
  bdata.setUint32(16, 16, Endian.little); // Subchunk1Size for PCM
  bdata.setUint16(20, 1, Endian.little); // AudioFormat: 1 = PCM
  bdata.setUint16(22, numChannels, Endian.little);
  bdata.setUint32(24, sampleRate, Endian.little);
  bdata.setUint32(28, byteRate, Endian.little);
  bdata.setUint16(32, blockAlign, Endian.little);
  bdata.setUint16(34, bitsPerSample, Endian.little);

  // data subchunk
  bytes.setRange(36, 40, 'data'.codeUnits);
  bdata.setUint32(40, dataSize, Endian.little);

  // PCM samples (little endian 16-bit)
  final pcmBytes = pcmSamples.buffer.asUint8List(
    pcmSamples.offsetInBytes,
    pcmSamples.lengthInBytes,
  );
  bytes.setRange(44, 44 + dataSize, pcmBytes);

  return bytes;
}
