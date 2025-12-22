# Room Creation Features - Complete Implementation

## Overview
Players can now define room parameters when creating a game room. The implementation spans both frontend (Flutter) and backend (Node.js).

## Features Implemented

### 1. **Max Players** (2-8 players)
   - Room creator can set the maximum number of players allowed
   - Default: 4 players
   - Join requests are rejected if room is full
   - Backend validates player count before allowing joins

### 2. **Rounds per Player** (1-10 rounds)
   - Room creator can set how many rounds each player will draw
   - Total rounds = rounds per player × number of players
   - Default: 3 rounds per player
   - Backend respects this setting throughout the game

### 3. **Word Difficulty** (Easy, Medium, Hard)
   - **Easy**: Common, simple words (cat, dog, house, sun, etc.)
   - **Medium**: Standard vocabulary (butterfly, mountain, technology, etc.)
   - **Hard**: Challenging words (constellation, hippopotamus, kaleidoscope, etc.)
   - Default: Medium
   - Words are dynamically selected based on difficulty during each round

---

## Frontend Changes (Flutter)

### File: `lib/models/game_session.dart`
- Added three new fields to `GameSession` class:
  - `int maxPlayers` - Maximum players in the room
  - `int maxRounds` - Rounds per player
  - `String wordDifficulty` - 'easy', 'medium', or 'hard'
- Updated `toJson()` and `fromJson()` to handle new fields
- Modified `GameSession.create()` to accept optional parameters:
  ```dart
  static Future<GameSession> create({
    required String creatorId,
    required String creatorName,
    String? creatorAvatarColor,
    int maxPlayers = 4,
    int maxRounds = 3,
    String wordDifficulty = 'medium',
  })
  ```

### File: `lib/screens/pages/scribble_lobby_screen.dart`
- Added `_showCreateRoomDialog()` - Beautiful dialog for room customization
  - Slider for max players (2-8)
  - Slider for rounds per player (1-10)
  - Three difficulty level buttons (Easy, Medium, Hard)
  - Cancel/Create action buttons
  
- Added `_buildDifficultyButton()` - Helper widget for difficulty selection
- Added `_createRoomWithSettings()` - Processes room creation with parameters
- Modified `_createGame()` to show the dialog instead of creating immediately

### File: `lib/widgets/waiting_room.dart`
- Added `_buildRoomSettings()` - Widget displaying room parameters
  - Shows current player count vs max players
  - Displays total rounds per player
  - Shows selected difficulty with color coding:
    - Easy = Green
    - Medium = Orange
    - Hard = Red
  - Positioned above the START GAME button

---

## Backend Changes (Node.js)

### File: `backend/wsHandler.js`

#### In `create_game` handler:
```javascript
const game = {
  ...payload,
  id: gameId,
  state: payload.state || 'GameState.waiting',
  roundTime: payload.roundTime || 80,
  maxPlayers: payload.maxPlayers || 4,
  maxRounds: payload.maxRounds || 3,
  wordDifficulty: payload.wordDifficulty || 'medium',
  // ... rest of properties
};
```
- Stores room parameters from payload
- Logs room creation with all parameters

#### In `join_game` handler:
- Validates room is not full before accepting joins
- Returns error: "Room is full" if `players.length >= maxPlayers`
- Logs player join with current player count

#### In `start_game` handler:
- Respects the room's configured `maxRounds` instead of auto-calculating
- Uses `wordDifficulty` for word selection

### File: `backend/gameManager.js`

#### Word system refactored:
```javascript
const wordsByDifficulty = {
  easy: [ /* 33 simple words */ ],
  medium: [ /* 33 standard words */ ],
  hard: [ /* 30 challenging words */ ]
};
```

#### Updated `getRandomWord()`:
```javascript
function getRandomWord(difficulty = 'medium') {
  const words = wordsByDifficulty[difficulty] || wordsByDifficulty.medium;
  return words[Math.floor(Math.random() * words.length)];
}
```
- Takes difficulty parameter
- Falls back to medium if invalid

#### Updated `startPrepPhase()`:
- Calls `getRandomWord(game.wordDifficulty)` to select words based on difficulty
- Logs the selected difficulty for debugging

---

## User Flow

### Creating a Room
1. Player taps "Create Game" on lobby
2. Room Creation Dialog appears with three sections:
   - Max Players slider (2-8)
   - Rounds per Player slider (1-10)
   - Word Difficulty buttons (Easy/Medium/Hard)
3. Player configures settings and taps "Create"
4. Room is created with configured parameters
5. Players see the settings displayed in the Waiting Room

### Joining a Room
1. Player selects an available room from lobby
2. If room is full, join is rejected with error message
3. If successful, player joins and sees room settings in Waiting Room

### Playing the Game
1. Game respects the configured `maxRounds` (no auto-calculation)
2. Words are selected from the configured difficulty level
3. Game ends after all rounds are complete per configuration

---

## Visual Elements

### Room Creation Dialog
- Modern glassmorphism design with blur background
- Purple gradient background matching app theme
- Three interactive sections with sliders and buttons
- Real-time value display in colored badges
- Cancel/Create buttons

### Room Settings Display (Waiting Room)
- Compact card showing three parameters:
  - Players: "2/4" format with people icon
  - Rounds: "3" with loop icon
  - Difficulty: "Easy" with color-coded icon
- Positioned between connection status and start button
- Visual feedback with color coding for difficulty

---

## Technical Details

### Validation
- Max players: 2-8 (enforced by slider and backend)
- Rounds per player: 1-10 (enforced by slider and backend)
- Difficulty: 'easy', 'medium', or 'hard' (enforced by button selection and backend)

### Data Flow
1. Frontend: User sets parameters in dialog
2. Frontend: Parameters passed to `GameSession.create()`
3. Frontend: GameSession serialized with parameters via `toJson()`
4. WebSocket: Sent to backend as part of `create_game` message
5. Backend: Parameters stored in game object
6. Backend: Parameters broadcast to all players
7. Frontend: Players receive and display parameters

### Error Handling
- Join room when full: Client receives error, shows snackbar
- Invalid difficulty: Falls back to 'medium'
- Invalid player count: Falls back to 4
- Invalid rounds: Falls back to 3

---

## Testing Checklist

- [x] Create room with custom parameters
- [x] Parameters display correctly in waiting room
- [x] Cannot join room when full
- [x] Words selected match chosen difficulty
- [x] Game respects configured round count
- [x] Backend logs room settings on creation
- [x] Serialization/deserialization of new fields
- [x] Default values work correctly

---

## Files Modified

1. ✅ `frontend/lib/models/game_session.dart`
2. ✅ `frontend/lib/screens/pages/scribble_lobby_screen.dart`
3. ✅ `frontend/lib/widgets/waiting_room.dart`
4. ✅ `backend/wsHandler.js`
5. ✅ `backend/gameManager.js`

---

## Future Enhancements

- [ ] Save room settings as templates
- [ ] Quick-join with matching difficulty preferences
- [ ] Statistics tracking by difficulty level
- [ ] Leaderboard filtering by game parameters
- [ ] Custom word lists per room
- [ ] Time limit customization (currently fixed at 80s)
