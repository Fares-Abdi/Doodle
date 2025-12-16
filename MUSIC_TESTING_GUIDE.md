# Music System - Testing Guide

## Overview of Changes

This document helps you verify that all music-related issues have been fixed.

## Issue #1: Music Continues Playing When App Closes ✓ FIXED

### What Was Happening
- When you force-closed the app (swiping it away from recent apps or powering off) the music would continue playing from the device speaker

### What Fixed It
- App lifecycle listener in `main.dart` now stops all audio when app reaches `detached` state
- Music is paused when app goes to background (`paused` state)
- Music resumes when app returns to foreground (`resumed` state)

### How to Test
1. Start the app with lobby music playing
2. Go to home screen (app goes to background)
   - Music should pause
3. Tap app to return
   - Music should resume automatically
4. Force-close app (swipe from recent apps)
   - Music should stop completely

---

## Issue #2: Lobby Music Continues in Waiting Room (Doesn't Stop) ✓ FIXED

### What Was Happening
- When joining a game, the lobby music would keep playing in the waiting room
- Music wouldn't be managed properly, sometimes playing multiple instances

### What Fixed It
- `WaitingRoom` now intelligently checks if lobby music is already playing
- If it is, it doesn't restart it
- If it's different music or stopped, it plays the lobby music once

### How to Test
1. Start in lobby (lobby music playing)
2. Create or join a game
   - Waiting room opens (lobby music should continue playing smoothly - no restart)
3. Listen carefully - should be same continuous music, not restarted

---

## Issue #3: Music Only Plays Once - Doesn't Resume After Match ✓ FIXED

### What Was Happening
- After a game finished and you returned to lobby, the lobby music wouldn't start playing again
- The system lost track of what music should be playing

### What Fixed It
- Enhanced `AudioService` to track actual music playback state
- Each game state transition now explicitly manages music switches
- When returning to lobby from game over, lobby music automatically starts
- Music properly loops/continues instead of stopping

### How to Test
1. Start lobby (lobby music plays - should loop continuously)
2. Create/join game and play a round
3. Game finishes → Game over screen shows
   - Game over music should play
4. Click "Back to Lobby"
   - Game over music should stop
   - Lobby music should immediately start playing again
   - Should NOT be silent

---

## Issue #4: Music Not Properly Resuming on App Resume ✓ FIXED

### What Was Happening
- When app was paused and resumed, music might not resume properly
- Or it might restart instead of continuing from where it was paused

### What Fixed It
- `ScribbleLobbyScreen` now checks music state before taking action
- App lifecycle handler intelligently resumes vs. replays based on current state
- Music service tracks actual playback state with `_isMusicPlaying` flag

### How to Test
1. App is in lobby with music playing
2. Pause app (home button or swipe)
   - Music pauses
3. Resume app
   - Music should resume smoothly (not restart)
4. Check timing - should pick up where it left off, not restart from beginning

---

## Complete Game Flow Test

For comprehensive testing, follow this complete flow:

### Step 1: Lobby Phase
- [ ] Open app → Lobby music starts playing
- [ ] Music loops continuously
- [ ] Volume and sound quality are good

### Step 2: Waiting Room Phase
- [ ] Create or join a game
- [ ] Lobby music continues (not restarted)
- [ ] Other players can join, sounds play for that
- [ ] Lobby music still in background

### Step 3: Game Playing Phase
- [ ] Game starts (lobby music stops)
- [ ] Game music plays instead
- [ ] Game music loops while playing

### Step 4: Round Transition Phase
- [ ] Round ends
- [ ] Game music stops
- [ ] Transition sound plays (1-2 seconds)
- [ ] Returns to waiting room
- [ ] Lobby music resumes

### Step 5: Game Over Phase
- [ ] Final round ends
- [ ] Game over screen shows
- [ ] Game over music plays
- [ ] Click "Back to Lobby"
- [ ] Game over music stops
- [ ] Lobby music starts immediately

### Step 6: App Lifecycle Phase
- [ ] With lobby music playing, press home button
- [ ] Music pauses
- [ ] Open app again
- [ ] Music resumes (doesn't restart from beginning)
- [ ] Force-close app
- [ ] Music stops completely (not playing in background anymore)

---

## Audio Files Check

Verify these audio files exist and are properly configured:

```
assets/audio/music/
├── lobby.mp3                 ← Plays in lobby and waiting room
├── game_music.mp3            ← Plays during game rounds
├── game_over_music.mp3       ← Plays when game ends
└── next_round.m4a            ← Plays during round transitions

assets/audio/music/ (Sound Effects)
├── game_start.m4a            ← Round starts
├── found_word.m4a            ← Correct guess
├── false_guesse.m4a          ← Wrong guess
├── round_end.m4a             ← Round ends
└── player_joined.m4a         ← Player joins
```

---

## Code Changes Summary

### Modified Files:
1. **main.dart** - App lifecycle handling
2. **audio_service.dart** - Music state tracking
3. **scribble_lobby_screen.dart** - Lobby music management
4. **waiting_room.dart** - Smart music playback
5. **game_room_screen.dart** - Game state music transitions
6. **game_over_screen.dart** - Game over to lobby transition
7. **round_transition.dart** - Round transition audio handling

### Key Improvements:
- ✓ Music state is tracked and verified before playing
- ✓ No duplicate music instances
- ✓ App lifecycle properly pauses/resumes/stops music
- ✓ Music continues looping through game states
- ✓ Clean transitions between different music tracks
- ✓ Music stops when app is killed

---

## Common Issues & Solutions

### Issue: App still plays music in background
- **Solution**: Hard restart device, check that app is fully closed. The fix may require app rebuild.

### Issue: Music restarts instead of continuing
- **Solution**: Check that `isMusicPlaying` state is being tracked. May need to rebuild app.

### Issue: No music in waiting room
- **Solution**: Verify `_ensureLobbyMusicPlaying()` is being called. Check that lobby.mp3 exists in assets.

### Issue: Music doesn't resume after game over
- **Solution**: Verify `_stopGameOverAndReturnToLobby()` is called. Check GameSounds.lobbyMusic path is correct.

---

## Performance Notes

- All audio operations use proper async/await
- Music state is checked before operations to prevent duplicates
- No memory leaks from unclosed audio files
- Battery usage should be improved (no background music when app is closed)

---

## Questions?

Refer to the `MUSIC_FIXES_SUMMARY.md` file for detailed technical information about each fix.
