# Player Profile Editing Feature - Implementation Summary

## Overview
Added the ability for players to change their name and avatar color in the lobby. Changes are synchronized across all game screens (waiting room, round transition, game over screen) via WebSocket.

## Files Created

### 1. **Frontend - Utility Helper**
- **File**: `lib/utils/avatar_color_helper.dart`
- **Purpose**: Centralized helper for converting between avatar color names and Color objects
- **Key Features**:
  - Maps 8 avatar colors: red, pink, orange, yellow, green, blue, indigo, purple
  - `getColorFromName()` - Converts string color name to Color object
  - `getColorNameFromColor()` - Converts Color object to string name

### 2. **Frontend - Player Profile Editor Dialog**
- **File**: `lib/widgets/player_profile_editor.dart`
- **Purpose**: Dialog widget allowing players to edit their name and avatar color
- **Features**:
  - Live avatar preview as user types name
  - 8 color options with visual selection
  - Input validation (name cannot be empty)
  - Clean, gradient-styled dialog matching app theme

## Files Modified

### Frontend Changes

#### 1. **GameService** (`lib/services/game_service.dart`)
- **Added Method**: `updatePlayer(gameId, playerId, name, photoURL)`
- **Purpose**: Sends player profile updates to backend via WebSocket

#### 2. **WaitingRoom Widget** (`lib/widgets/waiting_room.dart`)
- **Changes**:
  - Added import for `PlayerProfileEditor`
  - Added profile icon button (person icon) in top-right of header
  - Added `_showProfileEditor()` method to open the editor dialog
  - Calls `GameService.updatePlayer()` when profile is saved

#### 3. **PlayerAvatar Widget** (`lib/widgets/player_avatar.dart`)
- **Changes**:
  - Now uses `AvatarColorHelper.getColorFromName()` to display avatar colors
  - Avatar circles now display color-coded backgrounds with player initials
  - Removed NetworkImage dependency (was checking for photoURL as image URL)

#### 4. **PlayerTile Widget** (`lib/widgets/player_tile.dart`)
- **Changes**:
  - Integrated `AvatarColorHelper` for consistent color display
  - Updated avatar rendering to use color-coded backgrounds

#### 5. **GameOverScreen Widget** (`lib/widgets/game_over_screen.dart`)
- **Changes**:
  - Added import for `AvatarColorHelper`
  - Updated `_buildPodiumSpot()` to display color-coded avatars
  - Podium positions now show player initials on colored backgrounds

#### 6. **RoundTransition Widget** (`lib/widgets/round_transition.dart`)
- **Changes**:
  - Integrated `AvatarColorHelper` for next drawer display
  - Avatar colors now match the player's selected color
  - Updated avatar rendering in player grid

### Backend Changes

#### **WebSocket Handler** (`backend/wsHandler.js`)
- **Added Handler Case**: `update_player`
- **Functionality**:
  - Receives: `{ playerId, name, photoURL }`
  - Updates player object in game session
  - Broadcasts updated game state to all clients
  - Logs all player profile changes

## How It Works

### User Flow:
1. Player enters waiting room
2. Clicks profile icon (person icon) in top-right
3. Player Profile Editor dialog opens
4. Player edits name and/or selects new avatar color
5. Clicks "Save" button
6. Update sent to backend via WebSocket
7. Backend broadcasts updated game state
8. All players see the changes reflected instantly

### Data Flow:
```
PlayerProfileEditor 
  ↓ (onSave callback)
GameService.updatePlayer()
  ↓ (WebSocket message)
Backend wsHandler (update_player case)
  ↓ (updates game session)
Backend broadcast()
  ↓ (game_update message)
Frontend subscribeToGame() stream
  ↓ (stream listener updates UI)
All connected UI elements refresh
```

## Color Mapping
The 8 available avatar colors are:
1. **Red** - `Colors.red`
2. **Pink** - `Colors.pink`
3. **Orange** - `Colors.orange`
4. **Yellow** - `Colors.yellow`
5. **Green** - `Colors.green`
6. **Blue** - `Colors.blue` (default)
7. **Indigo** - `Colors.indigo`
8. **Purple** - `Colors.purple`

Colors are stored as string names (`photoURL` field) and converted to Color objects for display using `AvatarColorHelper`.

## Implementation Details

### Player Model
- Existing `photoURL` field is repurposed to store avatar color name (e.g., "red", "blue")
- No changes needed to Player model - maintains backward compatibility

### WebSocket Protocol
**New Message Type**: `update_player`
```javascript
{
  type: "update_player",
  gameId: "game-id-123",
  payload: {
    playerId: "player-id-456",
    name: "New Player Name",
    photoURL: "color-name" // e.g., "red", "blue", etc.
  }
}
```

### Screens Updated with Color Display:
- ✅ **Waiting Room** - PlayerAvatar components
- ✅ **Game Over Screen** - Podium display
- ✅ **Round Transition** - Next drawer preview
- ✅ **Game Board** - Player tiles (via player_tile.dart)
- ✅ **Chat Panel** - Player tiles (via player_tile.dart)

## Testing Checklist

- [ ] Click profile icon in waiting room to open editor
- [ ] Change player name and see it update live in preview
- [ ] Select different avatar colors and see preview update
- [ ] Save profile and verify changes appear in waiting room
- [ ] Verify changes persist when game starts
- [ ] Check that other players see your changes instantly
- [ ] Verify avatar colors display correctly in game over screen
- [ ] Verify avatar colors display in round transition screen
- [ ] Test with multiple players joining/leaving

## Notes

- Profile editing is only available in the **waiting room** state
- Name must be non-empty (validation in dialog)
- Color changes are broadcast to all players in real-time
- Changes persist for the duration of the game session
- Default avatar color is blue if not specified
