# Bug Fixes Summary - Waiting Room Issues

## Issues Addressed

### 1. Room Destruction Causing Disconnect
**Problem**: When all players exited the waiting room, the automatic room cleanup logic was closing all WebSocket connections, disconnecting everyone.

**Solution**: Modified the cleanup logic to:
- No longer automatically destroy waiting rooms immediately when they become empty
- Instead, mark empty waiting rooms for cleanup only after a 5-minute timeout
- Only close client connections if the game was in an active state (not waiting room)
- Allow games to exist empty so players can rejoin without being disconnected

### 2. Avatar Changes Not Persisted Across Games
**Problem**: When players changed their avatar/name in the waiting room, these changes were lost when joining a new game.

**Solution**: Implemented persistent player profile storage:
- Created `playerProfiles.js` module for managing player profile persistence
- Profiles are saved to `player_profiles.json` file on the backend
- When players join or create a game, their saved profile (name and avatar) is loaded and merged into the game state
- Profile updates are persisted whenever a player updates their profile

## Technical Changes

### Backend Changes

#### 1. `/Code/backend/gameManager.js`
- **Modified `startEmptyGameCheck()`**: 
  - Changed from checking every 1 second to every 10 seconds
  - Added timeout tracking for empty games (5 minute timeout before deletion)
  - Only games in waiting state are marked for delayed cleanup
  - Games in active states (drawing, prep, etc.) are cleaned up immediately when empty

- **Modified `cleanupGame()`**:
  - Added state check to only close connections for non-waiting games
  - For waiting room games, just clears the client mappings without closing connections
  - This allows players to stay connected and rejoin after leaving

#### 2. `/Code/backend/playerProfiles.js` (NEW FILE)
- **New module** for managing persistent player profiles
- Functions:
  - `getPlayerProfile(playerId)` - Retrieve saved profile
  - `savePlayerProfile(playerId, profile)` - Save/update profile
  - `getOrCreatePlayerProfile(playerId, defaultName)` - Get or create with defaults
  - `updatePlayerProfile(playerId, name, photoURL)` - Update name and avatar
- Profiles stored in JSON file with timestamps

#### 3. `/Code/backend/wsHandler.js`
- **Added import** for `playerProfiles` module
- **Modified `create_game` handler**: Loads saved profiles for game creator and merges them into players
- **Modified `join_game` handler**: Loads saved profile for joining player and merges it
- **Modified `update_player` handler**: Now calls `playerProfiles.updatePlayerProfile()` to persist changes
- **Added `destroy_room` handler**: New message type that:
  - Allows room creator to explicitly destroy the room
  - Broadcasts `game_destroyed` message to all clients
  - Immediately cleans up the game

### Frontend Changes

#### 1. `/Code/frontend/lib/services/game_service.dart`
- **Added `destroyRoom()` method**: Sends `destroy_room` message to backend

#### 2. `/Code/frontend/lib/widgets/waiting_room.dart`
- **Updated `_showExitConfirmation()`**:
  - Now checks if current player is the creator
  - Shows "Leave" option for all players
  - Shows "Destroy Room" option only for creator
  - Creator can explicitly destroy room without waiting for timeout

## Flow Diagrams

### Player Leaves Game (Without Disconnect)
1. Player clicks "Leave" in waiting room
2. Frontend sends `leave_game` message
3. Backend removes player from game.players array
4. If game still has players → broadcasts update to remaining players
5. If game is empty → marks for cleanup but doesn't disconnect anyone
6. Other players continue playing/waiting

### Avatar/Name Persistence Across Games
1. Player changes avatar in game 1
2. Frontend sends `update_player` message with new avatar
3. Backend updates game state AND persists to `player_profiles.json`
4. Player leaves and joins game 2
5. Backend loads saved profile from `player_profiles.json`
6. New game receives player with saved avatar/name

### Creator Destroys Room
1. Creator clicks "Destroy Room" button
2. Frontend sends `destroy_room` message
3. Backend verifies creator is authorized
4. Backend broadcasts `game_destroyed` message
5. All clients disconnect from room and return to lobby
6. Game is cleaned up immediately (not after timeout)

## Testing Recommendations

1. **Test Player Disconnect Scenario**:
   - Start game with 3 players
   - All players leave waiting room
   - Verify no unexpected disconnects occur
   - Verify players can rejoin the same game code later

2. **Test Avatar Persistence**:
   - Create game 1, set avatar to "red"
   - Leave game 1
   - Create game 2
   - Verify avatar is "red" in new game

3. **Test Creator Destroy**:
   - Creator clicks "Destroy Room"
   - Verify all other players are disconnected
   - Verify room doesn't appear in game list anymore

4. **Test Timeout Cleanup**:
   - Leave empty room
   - Wait 5 minutes
   - Verify room is cleaned up from server

## Files Modified
- `Code/backend/gameManager.js` - Cleanup logic changes
- `Code/backend/wsHandler.js` - Profile loading and destroy_room handler
- `Code/backend/playerProfiles.js` - NEW: Persistent profile storage
- `Code/frontend/lib/services/game_service.dart` - destroyRoom() method
- `Code/frontend/lib/widgets/waiting_room.dart` - Exit confirmation dialog update
