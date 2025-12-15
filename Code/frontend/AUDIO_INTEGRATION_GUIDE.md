# Audio Integration Guide

This guide shows how to integrate sound effects and music into your Flutter game.

## Quick Start

### 1. Import the Audio Service
```dart
import 'package:doodle/services/audio_service.dart';
import 'package:doodle/utils/game_sounds.dart';
import 'package:doodle/utils/audio_mixin.dart';
```

### 2. Option A: Using AudioMixin (Recommended for Widgets)

Add the mixin to your StatefulWidget:

```dart
class MyGameScreen extends StatefulWidget {
  @override
  _MyGameScreenState createState() => _MyGameScreenState();
}

class _MyGameScreenState extends State<MyGameScreen> with AudioMixin {
  @override
  void initState() {
    super.initState();
    // Play background music when screen loads
    playBackgroundMusic(GameSounds.gameMusic);
  }

  @override
  void dispose() {
    stopBackgroundMusic();
    super.dispose();
  }

  void handleButtonPress() async {
    await playButtonClick();
    // Do something
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Game')),
      body: Center(
        child: SoundButton(
          label: 'Play Game',
          onPressed: handleButtonPress,
        ),
      ),
    );
  }
}
```

### 3. Option B: Direct AudioService Usage

For more control:

```dart
final audioService = AudioService();

// Play sound effect
await audioService.playSfx(GameSounds.correctGuess);

// Play background music
await audioService.playMusic(GameSounds.gameMusic);

// Control volume
await audioService.setMusicVolume(0.5);
await audioService.setSfxVolume(0.7);

// Toggle music
await audioService.toggleMusic();

// Stop all audio
await audioService.stopAll();
```

## Using SoundButton Widget

Instead of regular buttons, use `SoundButton` for automatic click sounds:

```dart
SoundButton(
  label: 'Start Game',
  onPressed: () {
    // Handle game start
  },
  backgroundColor: Colors.blue,
  textColor: Colors.white,
  fontSize: 18,
  playSound: true, // Set to false to disable sound for this button
)
```

## Using SoundFloatingActionButton

For FABs with sound:

```dart
SoundFloatingActionButton(
  icon: Icons.play_arrow,
  onPressed: () {
    // Handle action
  },
  backgroundColor: Colors.green,
  tooltip: 'Play Game',
)
```

## Audio Service Methods

### Music Control
- `playMusic(String path, {bool loop = true})` - Play background music
- `stopMusic()` - Stop current music
- `pauseMusic()` - Pause music
- `resumeMusic()` - Resume paused music
- `setMusicVolume(double volume)` - Set volume (0.0 - 1.0)
- `toggleMusic({bool? enabled})` - Toggle music on/off

### Sound Effects
- `playSfx(String path)` - Play a sound effect
- `setSfxVolume(double volume)` - Set SFX volume (0.0 - 1.0)
- `toggleSfx({bool? enabled})` - Toggle SFX on/off

### General
- `initialize()` - Initialize the audio service (called in main.dart)
- `stopAll()` - Stop all audio playback
- `dispose()` - Clean up resources

### Getters
- `isMusicEnabled` - Check if music is enabled
- `isSfxEnabled` - Check if SFX is enabled
- `musicVolume` - Get current music volume
- `sfxVolume` - Get current SFX volume
- `currentMusicTrack` - Get current playing track

## Game Sounds Constants

Available sound constants in `GameSounds` class:

### Music
- `GameSounds.lobbyMusic` - Lobby background
- `GameSounds.gameMusic` - Game background
- `GameSounds.roundTransitionMusic` - Transition music

### Sound Effects
- `GameSounds.buttonClick` - Button press
- `GameSounds.correctGuess` - Correct answer
- `GameSounds.wrongGuess` - Wrong answer
- `GameSounds.roundStart` - Round begins
- `GameSounds.roundEnd` - Round ends
- `GameSounds.gameOver` - Game finished
- `GameSounds.notification` - Generic notification
- `GameSounds.playerJoined` - Player joined
- `GameSounds.timerTick` - Timer ticking
- `GameSounds.levelUp` - Level up event

## Integration Examples

### In Lobby Screen
```dart
class _ScribbleLobbyScreenState extends State<ScribbleLobbyScreen> with AudioMixin {
  @override
  void initState() {
    super.initState();
    playBackgroundMusic(GameSounds.lobbyMusic);
  }

  void createGame() async {
    await playButtonClick();
    // Create game logic
  }

  @override
  void dispose() {
    stopBackgroundMusic();
    super.dispose();
  }
}
```

### In Game Screen
```dart
class _GameRoomScreenState extends State<GameRoomScreen> with AudioMixin {
  @override
  void initState() {
    super.initState();
    playBackgroundMusic(GameSounds.gameMusic);
  }

  void onRoundStart() async {
    await playRoundStart();
    // Start round logic
  }

  void onGuessCorrect() async {
    await playCorrectGuess();
    // Update score
  }

  void onGuessWrong() async {
    await playWrongGuess();
    // Handle wrong guess
  }

  void onGameEnd() async {
    await playGameOver();
    // Game over logic
  }
}
```

### In Settings/Preferences
```dart
class _SettingsScreenState extends State<SettingsScreen> with AudioMixin {
  late bool _musicEnabled;
  late bool _sfxEnabled;
  late double _musicVolume;
  late double _sfxVolume;

  @override
  void initState() {
    super.initState();
    final audio = getAudioService();
    _musicEnabled = audio.isMusicEnabled;
    _sfxEnabled = audio.isSfxEnabled;
    _musicVolume = audio.musicVolume;
    _sfxVolume = audio.sfxVolume;
  }

  void onMusicVolumeChanged(double value) async {
    await getAudioService().setMusicVolume(value);
    setState(() => _musicVolume = value);
  }

  void onSfxVolumeChanged(double value) async {
    await getAudioService().setSfxVolume(value);
    setState(() => _sfxVolume = value);
  }

  void toggleMusic() async {
    await getAudioService().toggleMusic();
    setState(() => _musicEnabled = !_musicEnabled);
  }

  void toggleSfx() {
    getAudioService().toggleSfx();
    setState(() => _sfxEnabled = !_sfxEnabled);
  }
}
```

## Adding Your Own Audio Files

1. Add your audio files (MP3, WAV, OGG, M4A) to:
   - `assets/audio/music/` for background music
   - `assets/audio/sfx/` for sound effects

2. Update the `GameSounds` class in `lib/utils/game_sounds.dart`:
   ```dart
   class GameSounds {
     static const String myNewSound = 'assets/audio/sfx/my_new_sound.mp3';
   }
   ```

3. Use it in your code:
   ```dart
   await audioService.playSfx(GameSounds.myNewSound);
   ```

## Platform Support

The `audioplayers` package supports:
- Android
- iOS
- Web
- Windows
- macOS
- Linux

## Troubleshooting

### No sound playing
- Ensure audio files exist in the correct directories
- Check that file paths are correct (case-sensitive)
- Verify `pubspec.yaml` has the audio assets listed
- Check that device volume is not muted

### Audio cutting off
- Increase fade-out duration if needed
- Use separate AudioPlayer instances for music vs SFX (already done in AudioService)

### Performance issues
- Limit number of simultaneous sound effects
- Use compressed audio formats (MP3 or OGG)
- Pre-load frequently used sounds if needed

## Resources

- [audioplayers documentation](https://pub.dev/packages/audioplayers)
- [Flutter audio guide](https://flutter.dev/docs/development/packages-and-plugins/using-packages)
- Free sounds: Freesound.org, Zapsplat.com, Pixabay.com/music

