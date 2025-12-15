import 'package:flutter/material.dart';
import '../services/audio_service.dart';
import 'game_sounds.dart';

/// Mixin to add audio functionality to any widget
mixin AudioMixin {
  final AudioService _audioService = AudioService();

  /// Play a button click sound effect
  Future<void> playButtonClick() async {
    await _audioService.playSfx(GameSounds.buttonClick);
  }

  /// Play a notification sound
  Future<void> playNotification() async {
    await _audioService.playSfx(GameSounds.notification);
  }

  /// Play correct guess sound
  Future<void> playCorrectGuess() async {
    await _audioService.playSfx(GameSounds.correctGuess);
  }

  /// Play wrong guess sound
  Future<void> playWrongGuess() async {
    await _audioService.playSfx(GameSounds.wrongGuess);
  }

  /// Play round start sound
  Future<void> playRoundStart() async {
    await _audioService.playSfx(GameSounds.roundStart);
  }

  /// Play round end sound
  Future<void> playRoundEnd() async {
    await _audioService.playSfx(GameSounds.roundEnd);
  }

  /// Play game over sound
  Future<void> playGameOver() async {
    await _audioService.playSfx(GameSounds.gameOver);
  }

  /// Play player joined sound
  Future<void> playPlayerJoined() async {
    await _audioService.playSfx(GameSounds.playerJoined);
  }

  /// Play background music
  Future<void> playBackgroundMusic(String musicPath) async {
    await _audioService.playMusic(musicPath);
  }

  /// Stop background music
  Future<void> stopBackgroundMusic() async {
    await _audioService.stopMusic();
  }

  /// Pause background music
  Future<void> pauseBackgroundMusic() async {
    await _audioService.pauseMusic();
  }

  /// Resume background music
  Future<void> resumeBackgroundMusic() async {
    await _audioService.resumeMusic();
  }

  /// Get audio service instance for advanced control
  AudioService getAudioService() => _audioService;
}

/// Creates a button with built-in sound effect
class SoundButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final Color? backgroundColor;
  final Color? textColor;
  final double fontSize;
  final EdgeInsets? padding;
  final bool playSound;

  const SoundButton({
    Key? key,
    required this.label,
    required this.onPressed,
    this.backgroundColor,
    this.textColor,
    this.fontSize = 16,
    this.padding,
    this.playSound = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final audioService = AudioService();
    
    return ElevatedButton(
      onPressed: () async {
        if (playSound) {
          await audioService.playSfx(GameSounds.buttonClick);
        }
        onPressed();
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: backgroundColor,
        padding: padding ?? const EdgeInsets.symmetric(
          horizontal: 32,
          vertical: 16,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: fontSize,
          color: textColor ?? Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

/// Creates a floating action button with built-in sound effect
class SoundFloatingActionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final Color? backgroundColor;
  final String? tooltip;
  final bool playSound;

  const SoundFloatingActionButton({
    Key? key,
    required this.icon,
    required this.onPressed,
    this.backgroundColor,
    this.tooltip,
    this.playSound = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final audioService = AudioService();
    
    return FloatingActionButton(
      onPressed: () async {
        if (playSound) {
          await audioService.playSfx(GameSounds.buttonClick);
        }
        onPressed();
      },
      backgroundColor: backgroundColor,
      tooltip: tooltip,
      child: Icon(icon),
    );
  }
}
