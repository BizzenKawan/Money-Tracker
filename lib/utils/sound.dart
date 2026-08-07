import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';

/// Plays short sound effects for taps and saves.
///
/// Uses bundled .wav files via audioplayers so the sound plays regardless of
/// whether the phone's system "touch sounds" setting is on (the built-in
/// SystemSound is silent when that setting is off, which is the default on many
/// phones). Two reusable players are kept so a rapid tap doesn't cut itself off
/// awkwardly, and each is set to low latency mode for snappy response.
class Sound {
  Sound._();

  static final AudioPlayer _tapPlayer = AudioPlayer()
    ..setPlayerMode(PlayerMode.lowLatency)
    ..setReleaseMode(ReleaseMode.stop);
  static final AudioPlayer _savePlayer = AudioPlayer()
    ..setPlayerMode(PlayerMode.lowLatency)
    ..setReleaseMode(ReleaseMode.stop);

  static bool _enabled = true;

  /// Lets a settings toggle mute all effects.
  static void setEnabled(bool value) => _enabled = value;
  static bool get enabled => _enabled;

  static Future<void> _play(AudioPlayer player, String asset) async {
    if (!_enabled) return;
    try {
      await player.stop();
      await player.play(AssetSource(asset), volume: 0.6);
    } catch (_) {
      // Audio should never crash the app; ignore any playback error.
    }
  }

  static void tap() {
    _play(_tapPlayer, 'sounds/tap.wav');
    HapticFeedback.selectionClick();
  }

  static void save() {
    _play(_savePlayer, 'sounds/save.wav');
    HapticFeedback.mediumImpact();
  }
}

/// Backwards-compatible free functions used throughout the app.
void tapFeedback() => Sound.tap();
void saveFeedback() => Sound.save();
