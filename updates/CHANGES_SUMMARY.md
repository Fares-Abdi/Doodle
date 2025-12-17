# Changes Summary - Direct Lobby & Dynamic Server IP

## Overview
The login/sign-up system has been completely removed. Users can now directly access the lobby to find and create game rooms. Additionally, the server IP address can be changed from within the app settings.

## Changes Made

### 1. **main.dart** - Removed Authentication Routes
- **Removed**: `SharedPreferences` import (no longer needed for tracking login state)
- **Updated**: `_determineInitialRoute()` function now always returns `'/lobby'` - skipping login/signup
- **Updated**: Routes map now only contains the `/lobby` route
- **Removed**: `/login`, `/signup`, and `/forgot_password` routes

**Key Change**: Users launch directly into the lobby screen without any authentication

### 2. **services/websocket_service.dart** - Dynamic Server URL Configuration
- **Added**: Import for `SharedPreferences`
- **Updated**: `connect()` method now:
  - First checks `SharedPreferences` for a saved WebSocket URL
  - Falls back to `assets/config.json` if no saved URL exists
  - Includes proper null checking to ensure URL is valid
- **Added**: `reconnectWithNewUrl(String newUrl)` method
  - Disconnects from current WebSocket
  - Saves new URL to `SharedPreferences`
  - Reconnects with the new URL
- **Added**: `disconnect()` method for graceful disconnection

**Key Change**: Server URL is now configurable without modifying config files

### 3. **screens/pages/scribble_lobby_screen.dart** - Removed Firebase Auth
- **Removed**: `firebase_auth` import and all Firebase authentication code
- **Added**: 
  - Imports for `WebSocketService`, `SharedPreferences`, and `uuid`
  - `_playerId` and `_playerName` fields (persisted to device)
  - `_webSocketUrl` field to track current server URL
- **Added**: `_initializePlayer()` method
  - Generates unique player ID on first launch using UUID
  - Stores player ID and name in `SharedPreferences`
  - Uses stored ID on subsequent launches
- **Added**: `_loadWebSocketUrl()` method
  - Loads current WebSocket URL from preferences
- **Updated**: `_createGame()` method
  - Uses `_playerId` and `_playerName` instead of Firebase user data
- **Updated**: `_joinGame()` method
  - Uses `_playerId` and `_playerName` instead of Firebase user data
- **Updated**: Game join button in `_buildAvailableGames()`
  - Uses local player ID instead of Firebase user
- **Added**: `_showServerSettingsDialog()` method
  - Shows a dialog to change WebSocket server URL
  - Updates the URL dynamically
  - Reconnects WebSocket with new URL
- **Updated**: `build()` method
  - Added `AppBar` with settings icon
  - Settings icon opens server configuration dialog

**Key Changes**: 
- No login required
- Player identification uses device-local UUID
- Server IP can be changed from settings menu

## User Experience Flow

### Before
1. App launches → Login/Sign-up screen
2. User authenticates with Firebase
3. User accesses lobby

### After
1. App launches → Directly to lobby
2. User sees server settings button (gear icon)
3. User can:
   - Create a new room
   - Join a public room
   - Join a private room with code
   - Change server IP via settings

## How to Change Server IP

Users can now change the WebSocket server IP by:
1. Tapping the settings icon (⚙️) in the top-right of the lobby screen
2. Entering the new WebSocket server URL (e.g., `ws://192.168.1.100:8080`)
3. Tapping "Save"

The app will automatically disconnect and reconnect to the new server.

## Player Identification

Instead of Firebase authentication, players are identified by:
- A unique UUID generated on first launch
- A default name of `Player XXXX` (first 4 chars of UUID) that can be customized in `SharedPreferences`

This UUID persists across app sessions but is device-specific.

## Files Modified
1. `lib/main.dart`
2. `lib/services/websocket_service.dart`
3. `lib/screens/pages/scribble_lobby_screen.dart`

## Dependencies Already Present
- `shared_preferences: ^2.3.3` ✓
- `uuid: ^4.5.1` ✓
- `web_socket_channel: ^3.0.2` ✓
