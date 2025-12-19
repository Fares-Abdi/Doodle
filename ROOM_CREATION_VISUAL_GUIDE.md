# Room Creation - Visual Guide

## 1. Room Creation Dialog

When a player taps "Create Game" on the lobby, this dialog appears:

```
┌─────────────────────────────────────┐
│                                     │
│        Create Room                  │
│                                     │
├─────────────────────────────────────┤
│                                     │
│  Max Players:              [4]      │  ← Badge showing current value
│  ├─●━━━━━━━━━━━━━━━━━━┤           │  ← Slider from 2 to 8
│  │ 2    3    4    5    6    7    8 │  ← Division marks
│                                     │
├─────────────────────────────────────┤
│                                     │
│  Rounds per Player:        [3]      │  ← Badge showing current value
│  ├━━━━━●━━━━━━━━━━━━━━━┤          │  ← Slider from 1 to 10
│  │ 1   2   3   4  ...  10         │  ← Division marks
│                                     │
├─────────────────────────────────────┤
│                                     │
│  Word Difficulty:                   │
│  ┌─────────┐ ┌─────────┐ ┌─────┐  │
│  │  Easy   │ │ Medium  │ │Hard │  │  ← Button selection
│  │  🟢     │ │  🟠     │ │ 🔴 │  │
│  └─────────┘ └─────────┘ └─────┘  │
│                                     │
├─────────────────────────────────────┤
│                                     │
│  [  Cancel  ]  [  Create  ]        │  ← Action buttons
│                                     │
└─────────────────────────────────────┘
```

### Dialog Features
- **Max Players**: 2-8 players per room
- **Rounds per Player**: 1-10 drawing rounds
- **Difficulty**: Easy (🟢), Medium (🟠), Hard (🔴)
- **Color Scheme**: Purple gradient background with glassmorphism effect

---

## 2. Room Settings Display (Waiting Room)

After creating/joining a room, players see this card:

```
┌────────────────────────────────────┐
│   👥 Players      ⟳ Rounds    😊 Difficulty  │
│   ────────────    ─────────    ─────────────  │
│    2/4            3            Easy           │
│   Players         Rounds       Difficulty     │
│                                               │
└────────────────────────────────────┘
```

### Settings Card Components

| Icon | Label | Value | Purpose |
|------|-------|-------|---------|
| 👥 | Players | "2/4" | Current / Max players |
| ⟳ | Rounds | "3" | Rounds per player |
| 😊/😐/😞 | Difficulty | Easy/Med/Hard | Word difficulty |

### Difficulty Icons & Colors
- **Easy (🟢)**: Green icon, simple words
- **Medium (🟠)**: Orange icon, standard words  
- **Hard (🔴)**: Red icon, challenging words

---

## 3. Game Flow with Room Parameters

```
┌─────────────────────────────────────────────────┐
│ LOBBY                                           │
│ ┌─────────────────────────────────────────────┐ │
│ │ Player taps "Create Game"                   │ │
│ └────────────────┬────────────────────────────┘ │
│                  │                              │
│                  ▼                              │
│ ┌─────────────────────────────────────────────┐ │
│ │ Room Creation Dialog Appears                │ │
│ │ • Set Max Players: 2-8                      │ │
│ │ • Set Rounds: 1-10                          │ │
│ │ • Select Difficulty: Easy/Med/Hard          │ │
│ └────────────────┬────────────────────────────┘ │
│                  │                              │
│                  ▼                              │
│ ┌─────────────────────────────────────────────┐ │
│ │ WAITING ROOM                                │ │
│ │ • Shows room settings card                  │ │
│ │ • Displays: 2/4 players, 3 rounds, Easy     │ │
│ │ • Other players join (up to max)            │ │
│ └────────────────┬────────────────────────────┘ │
│                  │                              │
│                  ▼                              │
│ ┌─────────────────────────────────────────────┐ │
│ │ GAME START                                  │ │
│ │ • Respects max rounds setting               │ │
│ │ • Uses words from selected difficulty       │ │
│ │ • Round limit enforced: 3 rounds × 2 = 6   │ │
│ └─────────────────────────────────────────────┘ │
│                                                 │
└─────────────────────────────────────────────────┘
```

---

## 4. Word Difficulty Comparison

### Easy Words (Simple & Common)
```
🎨 Drawing Level: Simple shapes
Examples: chat (cat), soleil (sun), maison (house), fleur (flower)
Total Words: 33
Use Case: Children, beginners, casual play
```

### Medium Words (Standard)
```
🎨 Drawing Level: Some detail needed
Examples: ordinateur (computer), montagne (mountain), papillon (butterfly)
Total Words: 33
Use Case: Standard gameplay, all skill levels
```

### Hard Words (Challenging)
```
🎨 Drawing Level: Complex details
Examples: hippopotame (hippopotamus), kaleidoscope, constellation
Total Words: 30
Use Case: Experienced players, competitive play
```

---

## 5. Backend Room Configuration

When a room is created, the backend stores:

```javascript
{
  id: "abc12345",
  maxPlayers: 4,
  maxRounds: 3,
  wordDifficulty: "medium",
  players: [
    {
      id: "player1",
      name: "Alice",
      photoURL: "#FF6B9D",
      isCreator: true,
      score: 0
    }
  ],
  state: "GameState.waiting",
  // ... other game properties
}
```

---

## 6. Sample Room Configurations

### Family Game
```
Max Players: 4
Rounds: 2
Difficulty: Easy
→ 8 total rounds, beginner-friendly words
```

### Competitive Game
```
Max Players: 6
Rounds: 4
Difficulty: Hard
→ 24 total rounds, challenging vocabulary
```

### Quick Game
```
Max Players: 3
Rounds: 1
Difficulty: Medium
→ 3 total rounds, fast-paced game
```

---

## 7. Error Handling

### Room Full
```
❌ Join Failed
"Room is full (4/4 players)"

Action: Show snackbar and return to lobby
```

### Invalid Configuration (Fallback)
```
Invalid Input → System Default
─────────────────────────────
maxPlayers = 0 → 4
maxRounds = 0 → 3
wordDifficulty = "invalid" → "medium"
```

---

## 8. Player Experience Journey

### Creator
1. ✅ Opens Create Game dialog
2. ✅ Sets parameters (Players, Rounds, Difficulty)
3. ✅ Taps "Create"
4. ✅ Enters Waiting Room with settings visible
5. ✅ Other players join
6. ✅ Taps "START GAME"
7. ✅ Game respects all configured parameters

### Joiner
1. ✅ Sees available rooms on lobby
2. ✅ Taps to join room
3. ✅ Checks room settings (Players, Rounds, Difficulty)
4. ✅ Waits for room to start
5. ✅ Plays with configured settings

---

## 9. Technical Implementation Summary

### Frontend Components
- `_showCreateRoomDialog()` - Dialog UI
- `_buildDifficultyButton()` - Difficulty selector
- `_buildRoomSettings()` - Settings display
- `GameSession.create()` - Model with parameters

### Backend Processing
- `create_game` handler - Stores room config
- `join_game` handler - Validates max players
- `start_game` handler - Respects maxRounds
- `getRandomWord()` - Filters by difficulty

### Data Storage
- Firebase/Backend: Full configuration
- Local Cache: Room list with parameters
- Game Session: All parameters included

---

## 10. Configuration Limits & Defaults

| Parameter | Min | Default | Max |
|-----------|-----|---------|-----|
| Max Players | 2 | 4 | 8 |
| Rounds/Player | 1 | 3 | 10 |
| Difficulty | - | medium | - |

Total Max Rounds = 8 players × 10 rounds = 80 rounds
