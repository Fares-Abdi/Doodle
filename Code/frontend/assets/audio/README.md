# Audio Assets Guide

This directory contains all audio files for the Doodle game.

## Directory Structure

- `music/` - Background music tracks
- `sfx/` - Sound effects

## How to Add Audio Files

### Supported Formats
- MP3
- WAV
- OGG
- M4A

### Adding Background Music

1. Add your music files to `assets/audio/music/`
2. Suggested filenames:
   - `lobby_background.mp3` - Music for lobby screen
   - `game_background.mp3` - Music for gameplay
   - `round_transition.mp3` - Music for transitions

### Adding Sound Effects

1. Add your SFX files to `assets/audio/sfx/`
2. Suggested filenames:
   - `button_click.mp3` - Button press sound
   - `correct_guess.mp3` - When a guess is correct
   - `wrong_guess.mp3` - When a guess is wrong
   - `round_start.mp3` - Start of a new round
   - `round_end.mp3` - End of a round
   - `game_over.mp3` - Game ends
   - `notification.mp3` - Notification sound

### Example Usage in Code

```dart
final audioService = AudioService();

// Play background music
await audioService.playMusic('assets/audio/music/game_background.mp3');

// Play sound effect
await audioService.playSfx('assets/audio/sfx/button_click.mp3');

// Control volume
await audioService.setMusicVolume(0.5);
await audioService.setSfxVolume(0.7);

// Toggle audio
await audioService.toggleMusic();
audioService.toggleSfx();

// Stop all audio
await audioService.stopAll();
```

## Recommended Audio Resources

### Free Audio Websites
- Freesound.org
- Zapsplat.com
- Pixabay.com/en/music/
- OpenGameArt.org
- Incompetech.com

### Tools for Creating Audio
- Audacity (Free, open-source)
- FL Studio
- GarageBand (macOS/iOS)

## License Considerations

Ensure all audio files are properly licensed for use in your project. Use royalty-free or properly attributed audio.
