# Quick Start Guide - Player Profile Editing Feature

## What's New?

Players can now change their name and avatar color while in the **waiting room** before the game starts.

## How to Use

### 1. Open Profile Editor
- In the Waiting Room, tap the **person icon (👤)** button in the top-right corner
- The "Edit Your Profile" dialog will appear

### 2. Edit Your Profile
- **Change Name**: Type a new name in the text field
- **Choose Avatar Color**: Select from 8 color options (red, pink, orange, yellow, green, blue, indigo, purple)
- **Live Preview**: See your initials and chosen color update in real-time

### 3. Save Changes
- Click **"Save"** button to apply changes
- Your changes are immediately broadcast to all other players in the game
- Click **"Cancel"** to discard changes without saving

## Technical Details

### Frontend Files Added/Modified

**New Files:**
- `lib/utils/avatar_color_helper.dart` - Color conversion utility
- `lib/widgets/player_profile_editor.dart` - Profile editor dialog

**Modified Files:**
- `lib/services/game_service.dart` - Added `updatePlayer()` method
- `lib/widgets/waiting_room.dart` - Added profile editor button and method
- `lib/widgets/player_avatar.dart` - Updated to use avatar colors
- `lib/widgets/player_tile.dart` - Updated to use avatar colors
- `lib/widgets/game_over_screen.dart` - Updated to display avatar colors
- `lib/widgets/round_transition.dart` - Updated to display avatar colors

### Backend Files Modified

**Modified Files:**
- `backend/wsHandler.js` - Added `update_player` message handler
  - Receives player updates
  - Updates player object in game session
  - Broadcasts changes to all connected clients

## Data Flow Diagram

```
User clicks profile icon
    ↓
PlayerProfileEditor dialog opens
    ↓
User edits name/color and clicks Save
    ↓
GameService.updatePlayer() called
    ↓
WebSocket message: 'update_player' sent to backend
    ↓
Backend wsHandler receives message
    ↓
Updates game.players[i].name and game.players[i].photoURL
    ↓
Broadcasts 'game_update' to all clients in game
    ↓
Frontend GameService stream receives update
    ↓
GameSession.fromJson() reconstructs game state
    ↓
All UI widgets listening to game stream rebuild
    ↓
Avatar colors, names display updated across all screens
```

## API Contracts

### WebSocket Message - Update Player

**Request** (Client → Server):
```json
{
  "type": "update_player",
  "gameId": "game-12345",
  "payload": {
    "playerId": "player-67890",
    "name": "New Name",
    "photoURL": "red"
  }
}
```

**Response** (Server → All Clients):
```json
{
  "type": "game_update",
  "gameId": "game-12345",
  "payload": {
    "id": "game-12345",
    "players": [
      {
        "id": "player-67890",
        "name": "New Name",
        "photoURL": "red",
        "score": 0,
        "isDrawing": false,
        "isCreator": true
      },
      // ... other players
    ],
    "state": "GameState.waiting",
    // ... other game properties
  }
}
```

## Screens Where Changes Appear

1. **Waiting Room** ✅ - Live updates in player avatars
2. **Game Board** ✅ - Updated player tiles in chat panel
3. **Round Transition** ✅ - Updated avatars in round preview
4. **Game Over Screen** ✅ - Updated podium display with colors

## Color System

Colors are stored internally as string names but displayed as color-coded circles:

| Color Name | Display Color |
|-----------|---------------|
| `red` | 🔴 Red |
| `pink` | 🩷 Pink |
| `orange` | 🟠 Orange |
| `yellow` | 🟡 Yellow |
| `green` | 🟢 Green |
| `blue` | 🔵 Blue (default) |
| `indigo` | 🟣 Indigo |
| `purple` | 🟣 Purple |

## Validation

- **Name**: Must not be empty (Save button disabled if empty)
- **Color**: Always valid (8 predefined colors only)

## Backward Compatibility

- Existing `photoURL` field repurposed (was for network image URLs, now stores color names)
- No database schema changes required
- Old games/profiles without colors default to blue

## Known Limitations

- Profile editing only available in **Waiting Room** state
- Cannot edit profile during active game (in Drawing state)
- Cannot edit profile after game ends (in GameOver state)
- Name changes don't persist across game sessions (new game = fresh profile)

## Testing

To test the feature:

1. **Start a new game** and invite other players
2. **Click the profile icon** in the waiting room
3. **Edit name and color**, then save
4. **Verify changes appear** in waiting room for all players
5. **Start the game** and verify colors persist in game board
6. **Complete the game** and verify colors show in game over screen

## Troubleshooting

**Issue**: Changes not appearing for other players
- **Solution**: Ensure WebSocket connection is active (check backend logs)
- Check that `update_player` message is being received by backend

**Issue**: Avatar colors not displaying correctly
- **Solution**: Verify `AvatarColorHelper.getColorFromName()` is being called
- Check that `photoURL` field contains valid color name string

**Issue**: Profile editor dialog not opening
- **Solution**: Ensure you're in Waiting Room state
- Check that profile icon button is visible in app bar
