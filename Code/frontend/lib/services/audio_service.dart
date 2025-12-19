import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AudioType { music, sfx }

class AudioService {
  static final AudioService _instance = AudioService._internal();
  
  late AudioPlayer _musicPlayer;
  late AudioPlayer _sfxPlayer;
  
  bool _isMusicEnabled = true;
  bool _isSfxEnabled = true;
  double _musicVolume = 0.5;
  double _sfxVolume = 0.7;
  
  String? _currentMusicTrack;
  bool _isMusicPlaying = false;

  factory AudioService() {
    return _instance;
  }

  AudioService._internal() {
    _musicPlayer = AudioPlayer();
    _sfxPlayer = AudioPlayer();
  }

  /// Initialize audio service
  Future<void> initialize() async {
    // Load saved settings from SharedPreferences
    await _loadSettings();
    
    // Configure music player
    await _musicPlayer.setReleaseMode(ReleaseMode.loop);
    await _musicPlayer.setVolume(_musicVolume);
    
    // Listen to music player state changes
    _musicPlayer.onPlayerStateChanged.listen((state) {
      _isMusicPlaying = state == PlayerState.playing;
    });
    
    // Configure SFX player with audio context that doesn't pause music
    await _sfxPlayer.setVolume(_sfxVolume);
    await _sfxPlayer.setAudioContext(
      AudioContext(
        iOS: AudioContextIOS(
          options: {
            AVAudioSessionOptions.duckOthers,
          },
        ),
        android: AudioContextAndroid(
          audioFocus: AndroidAudioFocus.none,
        ),
      ),
    );
  }

  /// Load saved audio settings from SharedPreferences
  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _isMusicEnabled = prefs.getBool('isMusicEnabled') ?? true;
    _isSfxEnabled = prefs.getBool('isSfxEnabled') ?? true;
    _musicVolume = prefs.getDouble('musicVolume') ?? 0.5;
    _sfxVolume = prefs.getDouble('sfxVolume') ?? 0.7;
  }

  /// Save audio settings to SharedPreferences
  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isMusicEnabled', _isMusicEnabled);
    await prefs.setBool('isSfxEnabled', _isSfxEnabled);
    await prefs.setDouble('musicVolume', _musicVolume);
    await prefs.setDouble('sfxVolume', _sfxVolume);
  }

  /// Play background music
  Future<void> playMusic(String musicPath, {bool loop = true}) async {
    if (!_isMusicEnabled) return;
    
    try {
      // Stop current music if different track
      if (_currentMusicTrack != musicPath && _currentMusicTrack != null) {
        await _musicPlayer.stop();
      }
      
      // Don't restart the same music that's already playing
      if (_currentMusicTrack == musicPath && _isMusicPlaying) {
        return;
      }
      
      _currentMusicTrack = musicPath;
      await _musicPlayer.setReleaseMode(loop ? ReleaseMode.loop : ReleaseMode.stop);
      await _musicPlayer.play(AssetSource(musicPath));
      _isMusicPlaying = true;
    } catch (e) {
      print('Error playing music: $e');
    }
  }

  /// Play sound effect
  Future<void> playSfx(String sfxPath) async {
    if (!_isSfxEnabled) return;
    
    try {
      await _sfxPlayer.play(AssetSource(sfxPath));
    } catch (e) {
      print('Error playing sound effect: $e');
    }
  }

  /// Stop background music
  Future<void> stopMusic() async {
    await _musicPlayer.stop();
    _currentMusicTrack = null;
    _isMusicPlaying = false;
  }

  /// Pause background music
  Future<void> pauseMusic() async {
    await _musicPlayer.pause();
    _isMusicPlaying = false;
  }

  /// Resume background music
  Future<void> resumeMusic() async {
    if (_currentMusicTrack != null && !_isMusicPlaying) {
      await _musicPlayer.resume();
      _isMusicPlaying = true;
    }
  }

  /// Stop all audio
  Future<void> stopAll() async {
    await _musicPlayer.stop();
    await _sfxPlayer.stop();
    _currentMusicTrack = null;
    _isMusicPlaying = false;
  }

  /// Set music volume (0.0 - 1.0)
  Future<void> setMusicVolume(double volume) async {
    _musicVolume = volume.clamp(0.0, 1.0);
    await _musicPlayer.setVolume(_musicVolume);
    await _saveSettings();
  }

  /// Set SFX volume (0.0 - 1.0)
  Future<void> setSfxVolume(double volume) async {
    _sfxVolume = volume.clamp(0.0, 1.0);
    await _sfxPlayer.setVolume(_sfxVolume);
    await _saveSettings();
  }

  /// Toggle music on/off
  Future<void> toggleMusic({bool? enabled}) async {
    _isMusicEnabled = enabled ?? !_isMusicEnabled;
    await _saveSettings();
    if (!_isMusicEnabled) {
      await pauseMusic();
    } else if (_currentMusicTrack != null) {
      await resumeMusic();
    }
  }

  /// Toggle SFX on/off
  Future<void> toggleSfx({bool? enabled}) async {
    _isSfxEnabled = enabled ?? !_isSfxEnabled;
    await _saveSettings();
  }

  /// Dispose audio service
  Future<void> dispose() async {
    await _musicPlayer.dispose();
    await _sfxPlayer.dispose();
  }

  // Getters
  bool get isMusicEnabled => _isMusicEnabled;
  bool get isSfxEnabled => _isSfxEnabled;
  double get musicVolume => _musicVolume;
  double get sfxVolume => _sfxVolume;
  String? get currentMusicTrack => _currentMusicTrack;
  bool get isMusicPlaying => _isMusicPlaying;
}