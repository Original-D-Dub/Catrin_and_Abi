// ignore_for_file: avoid_print
/// Generates simple WAV tone audio files for the Letter Quest game.
///
/// Run with: dart run tool/generate_audio.dart
///
/// Creates 4 WAV files in assets/audio/letter_quest/:
/// - collect_correct.wav  — ascending two-note chime
/// - collect_wrong.wav    — descending buzz tone
/// - word_complete.wav    — ascending three-note arpeggio
/// - game_complete.wav    — full ascending fanfare
library;

import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

/// Generates a sine wave tone at the given frequency and duration.
///
/// [frequency] is in Hz (e.g., 523.25 for C5).
/// [durationMs] is the length in milliseconds.
/// [sampleRate] is samples per second (default 44100).
/// [amplitude] is the volume level from 0.0 to 1.0.
///
/// Returns a list of double samples in the range -1.0 to 1.0.
List<double> generateTone({
  required double frequency,
  required int durationMs,
  int sampleRate = 44100,
  double amplitude = 0.7,
}) {
  final numSamples = (sampleRate * durationMs / 1000).round();
  final samples = List<double>.filled(numSamples, 0.0);

  for (int i = 0; i < numSamples; i++) {
    final t = i / sampleRate;
    samples[i] = amplitude * sin(2 * pi * frequency * t);
  }

  return samples;
}

/// Applies a fade-in and fade-out envelope to avoid clicks.
///
/// [samples] is the raw audio data.
/// [fadeMs] is the fade duration in milliseconds at each end.
/// [sampleRate] is samples per second.
void applyEnvelope({
  required List<double> samples,
  int fadeMs = 20,
  int sampleRate = 44100,
}) {
  final fadeSamples = (sampleRate * fadeMs / 1000).round();

  for (int i = 0; i < fadeSamples && i < samples.length; i++) {
    samples[i] *= i / fadeSamples;
  }

  for (int i = 0; i < fadeSamples && i < samples.length; i++) {
    final idx = samples.length - 1 - i;
    samples[idx] *= i / fadeSamples;
  }
}

/// Concatenates multiple sample lists with optional gap of silence between them.
List<double> concatenate(List<List<double>> segments, {int gapMs = 0, int sampleRate = 44100}) {
  final gapSamples = (sampleRate * gapMs / 1000).round();
  final gap = List<double>.filled(gapSamples, 0.0);
  final result = <double>[];

  for (int i = 0; i < segments.length; i++) {
    result.addAll(segments[i]);
    if (i < segments.length - 1 && gapMs > 0) {
      result.addAll(gap);
    }
  }

  return result;
}

/// Writes samples to a WAV file (16-bit PCM, mono, 44100 Hz).
///
/// [filePath] is the output file path.
/// [samples] is the audio data (values from -1.0 to 1.0).
/// [sampleRate] is samples per second.
void writeWav({
  required String filePath,
  required List<double> samples,
  int sampleRate = 44100,
}) {
  final numSamples = samples.length;
  final bitsPerSample = 16;
  final numChannels = 1;
  final byteRate = sampleRate * numChannels * bitsPerSample ~/ 8;
  final blockAlign = numChannels * bitsPerSample ~/ 8;
  final dataSize = numSamples * blockAlign;
  final fileSize = 36 + dataSize;

  final buffer = ByteData(44 + dataSize);
  int offset = 0;

  // RIFF header
  void writeString(String s) {
    for (int i = 0; i < s.length; i++) {
      buffer.setUint8(offset++, s.codeUnitAt(i));
    }
  }

  void writeUint32(int value) {
    buffer.setUint32(offset, value, Endian.little);
    offset += 4;
  }

  void writeUint16(int value) {
    buffer.setUint16(offset, value, Endian.little);
    offset += 2;
  }

  writeString('RIFF');
  writeUint32(fileSize);
  writeString('WAVE');

  // fmt chunk
  writeString('fmt ');
  writeUint32(16); // chunk size
  writeUint16(1); // PCM format
  writeUint16(numChannels);
  writeUint32(sampleRate);
  writeUint32(byteRate);
  writeUint16(blockAlign);
  writeUint16(bitsPerSample);

  // data chunk
  writeString('data');
  writeUint32(dataSize);

  // Write samples as 16-bit signed integers
  for (int i = 0; i < numSamples; i++) {
    final clamped = samples[i].clamp(-1.0, 1.0);
    final intSample = (clamped * 32767).round();
    buffer.setInt16(offset, intSample, Endian.little);
    offset += 2;
  }

  final file = File(filePath);
  file.writeAsBytesSync(buffer.buffer.asUint8List());
  print('Created: $filePath (${(file.lengthSync() / 1024).toStringAsFixed(1)} KB)');
}

void main() {
  const outputDir = 'assets/audio/letter_quest';

  // Musical note frequencies (Hz)
  const c5 = 523.25;
  const e5 = 659.25;
  const g5 = 783.99;
  const c6 = 1046.50;
  const e4 = 329.63;
  const c4 = 261.63;

  // 1. Collect correct — ascending two-note chime (C5 → E5)
  final correctNote1 = generateTone(frequency: c5, durationMs: 120, amplitude: 0.6);
  final correctNote2 = generateTone(frequency: e5, durationMs: 180, amplitude: 0.6);
  applyEnvelope(samples: correctNote1);
  applyEnvelope(samples: correctNote2);
  final correctSamples = concatenate([correctNote1, correctNote2], gapMs: 30);
  writeWav(filePath: '$outputDir/collect_correct.wav', samples: correctSamples);

  // 2. Collect wrong — descending buzz (E4 → C4)
  final wrongNote1 = generateTone(frequency: e4, durationMs: 150, amplitude: 0.5);
  final wrongNote2 = generateTone(frequency: c4, durationMs: 200, amplitude: 0.5);
  applyEnvelope(samples: wrongNote1);
  applyEnvelope(samples: wrongNote2);
  final wrongSamples = concatenate([wrongNote1, wrongNote2], gapMs: 20);
  writeWav(filePath: '$outputDir/collect_wrong.wav', samples: wrongSamples);

  // 3. Word complete — ascending three-note arpeggio (C5 → E5 → G5)
  final wc1 = generateTone(frequency: c5, durationMs: 150, amplitude: 0.6);
  final wc2 = generateTone(frequency: e5, durationMs: 150, amplitude: 0.6);
  final wc3 = generateTone(frequency: g5, durationMs: 250, amplitude: 0.7);
  applyEnvelope(samples: wc1);
  applyEnvelope(samples: wc2);
  applyEnvelope(samples: wc3);
  final wordCompleteSamples = concatenate([wc1, wc2, wc3], gapMs: 40);
  writeWav(filePath: '$outputDir/word_complete.wav', samples: wordCompleteSamples);

  // 4. Game complete — full ascending fanfare (C5 → E5 → G5 → C6)
  final gc1 = generateTone(frequency: c5, durationMs: 150, amplitude: 0.6);
  final gc2 = generateTone(frequency: e5, durationMs: 150, amplitude: 0.6);
  final gc3 = generateTone(frequency: g5, durationMs: 150, amplitude: 0.7);
  final gc4 = generateTone(frequency: c6, durationMs: 400, amplitude: 0.8);
  applyEnvelope(samples: gc1);
  applyEnvelope(samples: gc2);
  applyEnvelope(samples: gc3);
  applyEnvelope(samples: gc4, fadeMs: 50);
  final gameCompleteSamples = concatenate([gc1, gc2, gc3, gc4], gapMs: 50);
  writeWav(filePath: '$outputDir/game_complete.wav', samples: gameCompleteSamples);

  print('\nAll audio files generated successfully!');
}
