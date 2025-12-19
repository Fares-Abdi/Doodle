# Room Creation Features - Implementation Guide

## Quick Start

Players can now customize their game rooms with three parameters:

1. **Max Players** (2-8)
2. **Rounds per Player** (1-10)  
3. **Word Difficulty** (Easy/Medium/Hard)

---

## Code Changes Summary

### Frontend Files Modified

#### 1. `lib/models/game_session.dart`
**What Changed:**
- Added 3 new fields to GameSession class
- Updated serialization/deserialization
- Modified GameSession.create() factory

**Key Addition:**
```dart
int maxPlayers;              // New field
int maxRounds;               // Updated from auto-calculated
String wordDifficulty;       // New field
```

#### 2. `lib/screens/pages/scribble_lobby_screen.dart`
**What Changed:**
- Modified `_createGame()` to show dialog
- Added `_showCreateRoomDialog()` - beautiful dialog UI
- Added `_buildDifficultyButton()` - difficulty selector
- Added `_createRoomWithSettings()` - processes settings

**Flow:**
```
_createGame() 
  → _showCreateRoomDialog()  [Dialog opens]
    → _buildDifficultyButton() [Rendered 3 times]
      → _createRoomWithSettings() [On "Create" button]
        → GameSession.create(settings)
          → GameRoomScreen
```

#### 3. `lib/widgets/waiting_room.dart`
**What Changed:**
- Added `_buildRoomSettings()` - displays room config
- Inserted between connection status and start button

**Display:**
```
┌──────────────────────────────┐
│ Players │ Rounds │ Difficulty│
│  2/4    │   3    │   Easy     │
└──────────────────────────────┘
```

### Backend Files Modified

#### 1. `backend/wsHandler.js` - `create_game` handler
**What Changed:**
```javascript
maxPlayers: payload.maxPlayers || 4,
maxRounds: payload.maxRounds || 3,
wordDifficulty: payload.wordDifficulty || 'medium',
```

**Effect:**
- Stores room parameters from client
- Logs them for debugging
- Broadcasts to all players

#### 2. `backend/wsHandler.js` - `join_game` handler
**What Changed:**
```javascript
// Check if game is full
if (game.players.length >= game.maxPlayers) {
  // Send error to client
}
```

**Effect:**
- Validates player count against room limit
- Prevents overbooking
- Returns error message

#### 3. `backend/wsHandler.js` - `start_game` handler
**What Changed:**
```javascript
// Use room's configured maxRounds instead of auto-calculating
if (!game.maxRounds || game.maxRounds === 0) {
  game.maxRounds = game.players.length * 2;  // fallback only
}
```

**Effect:**
- Respects creator's round configuration
- Game ends after configured rounds

#### 4. `backend/gameManager.js` - Word system
**What Changed:**
```javascript
const wordsByDifficulty = {
  easy: [ /* 33 words */ ],
  medium: [ /* 33 words */ ],
  hard: [ /* 30 words */ ]
};

function getRandomWord(difficulty = 'medium') {
  const words = wordsByDifficulty[difficulty] || wordsByDifficulty.medium;
  return words[Math.floor(Math.random() * words.length)];
}
```

**Effect:**
- Words selected based on difficulty
- Fallback to medium if invalid
- Each round uses appropriate vocabulary

#### 5. `backend/gameManager.js` - startPrepPhase()
**What Changed:**
```javascript
game.currentWord = getRandomWord(game.wordDifficulty);
```

**Effect:**
- Passes room's difficulty to word selection
- Logs difficulty for debugging

---

## Data Flow Diagram

```
FRONTEND                           BACKEND                      DATABASE
┌─────────────────┐
│ Create Room     │
│ Dialog Opens    │
└────────┬────────┘
         │ Player sets:
         │ - maxPlayers
         │ - maxRounds
         │ - wordDifficulty
         │
         ▼
┌─────────────────────────┐
│ _createRoomWithSettings │
│ - Read settings         │
│ - Create GameSession    │
└────────┬────────────────┘
         │ Serialize to JSON:
         │ {
         │   maxPlayers: 4,
         │   maxRounds: 3,
         │   wordDifficulty: 'medium'
         │ }
         │
         ├──────────────► create_game ──────► Store in Map
         │    message       handler           with settings
         │
         ▼
┌──────────────────────────┐
│ WaitingRoom              │
│ _buildRoomSettings()     │
│ Shows: 2/4 | 3 | Easy    │
└──────────────────────────┘
         │
         │ Player joins
         ├──────────────► join_game ────────► Validate
         │    message       handler           maxPlayers
         │
         ▼
┌──────────────────────┐
│ START GAME           │
│ Button Clicked       │
└────────┬─────────────┘
         │
         ├──────────────► start_game ───────► Use maxRounds
         │    message       handler           from room config
         │
         ▼
┌──────────────────────────────┐
│ Game Playing                 │
│ - Words from difficulty      │
│ - Round count respected      │
│ - Max players enforced       │
└──────────────────────────────┘
```

---

## Testing Checklist

### Frontend Testing
- [ ] Create room dialog displays correctly
- [ ] Sliders work smoothly (2-8 players, 1-10 rounds)
- [ ] Difficulty buttons toggle properly (Easy/Med/Hard)
- [ ] Settings displayed in waiting room
- [ ] Settings persist when navigating

### Backend Testing
- [ ] `create_game` stores maxPlayers, maxRounds, wordDifficulty
- [ ] `join_game` rejects if room full
- [ ] `start_game` uses configured maxRounds
- [ ] `getRandomWord()` selects from correct difficulty
- [ ] Logs show room configuration

### Integration Testing
- [ ] Create room with custom settings → Join → Start game works
- [ ] Room full → Cannot join → Returns to lobby
- [ ] Game respects round limit
- [ ] Words match difficulty level
- [ ] Multiple rooms with different settings run simultaneously

### User Scenarios
- [ ] Family game: 4 players, 2 rounds, Easy
- [ ] Quick game: 3 players, 1 round, Medium
- [ ] Competitive: 6 players, 4 rounds, Hard
- [ ] Solo testing: Can't join room when full

---

## Debugging

### Backend Logs to Monitor

**Room Creation:**
```
Game {gameId} created by {playerName} - maxPlayers: 4, maxRounds: 3, difficulty: medium
```

**Player Join:**
```
{playerName} joined game {gameId} (2/4)
Failed to join game {gameId} - room is full (4/4)
```

**Game Start:**
```
Game {gameId} started. Total rounds: 3, Difficulty: medium
```

**Word Selection:**
```
Prep phase started for game {gameId}. Drawer: {playerName}, Word: {word} (medium)
```

### Frontend Debugging

**State Printing:**
```dart
print('Room: ${session.maxPlayers} players, ${session.maxRounds} rounds, ${session.wordDifficulty}');
```

**Dialog Issues:**
- Verify dialog shows with no errors
- Check sliders move smoothly
- Ensure buttons toggle highlighting

**Display Issues:**
- Room settings card should appear in waiting room
- Values should match what was set in dialog

---

## Common Issues & Solutions

### Issue: Settings not persisting
**Cause:** Not serialized in toJson()
**Solution:** Check all fields in toJson() and fromJson()

### Issue: Room accepting more players than max
**Cause:** join_game not checking maxPlayers
**Solution:** Verify join_game handler has player count validation

### Issue: Words from wrong difficulty
**Cause:** getRandomWord() not receiving difficulty parameter
**Solution:** Check startPrepPhase() passes game.wordDifficulty

### Issue: Dialog not showing
**Cause:** setState called incorrectly in StatefulBuilder
**Solution:** Verify setState passed correctly to StatefulBuilder

### Issue: Sliders not working
**Cause:** onChanged not updating state
**Solution:** Verify setState(() => variable = value) in onChanged

---

## Performance Considerations

### Frontend
- Dialog uses SingleChildScrollView to handle small screens
- Sliders use divisions for smooth 2-8 and 1-10 ranges
- No heavy computations in build methods

### Backend
- Word arrays cached, not dynamically built
- No database queries needed
- O(1) lookup from wordsByDifficulty map

### Network
- Settings sent once on room creation
- No additional messages needed
- Broadcast to all players uses same mechanism

---

## Future Enhancement Ideas

1. **Save Presets**
   - Let users save favorite room configurations
   - "Quick Game", "Competitive", "Family" presets

2. **Statistics Tracking**
   - Win rate by difficulty
   - Average rounds played
   - Leaderboard filtering by settings

3. **Advanced Configuration**
   - Custom time limits
   - Point scaling by difficulty
   - Team-based gameplay

4. **Matchmaking**
   - Find players with similar preferences
   - Difficulty-based room suggestions

5. **Custom Word Lists**
   - Allow room creator to add custom words
   - Theme-based word lists (animals, sports, etc.)

---

## API Reference

### GameSession Model
```dart
GameSession.create({
  required String creatorId,
  required String creatorName,
  String? creatorAvatarColor,
  int maxPlayers = 4,           // NEW
  int maxRounds = 3,            // NEW
  String wordDifficulty = 'medium',  // NEW
})
```

### Backend Messages
```javascript
// create_game payload includes:
{
  maxPlayers: 4,
  maxRounds: 3,
  wordDifficulty: 'medium'
}

// join_game error response:
{
  type: 'join_error',
  gameId: 'abc123',
  payload: { message: 'Room is full' }
}
```

### Difficulty Values
- `'easy'` - Beginner-friendly words
- `'medium'` - Standard vocabulary (default)
- `'hard'` - Challenging words

---

## Version History

**Version 1.0** - Initial Release
- ✅ Max players selection (2-8)
- ✅ Rounds per player selection (1-10)
- ✅ Difficulty selection (Easy/Medium/Hard)
- ✅ Room capacity enforcement
- ✅ Word filtering by difficulty
- ✅ UI display in waiting room

---

## Support

For issues or questions:
1. Check the debugging section above
2. Review the data flow diagram
3. Check backend logs for create_game/join_game messages
4. Verify frontend dialog showing/dismissing correctly
