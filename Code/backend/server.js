const WebSocket = require('ws');
const { v4: uuidv4 } = require('uuid');
const os = require('os');
const fs = require('fs');
const path = require('path');

// Run setup_config.js
require('./setup_config');

// Add colors for console logs
const colors = {
  reset: '\x1b[0m',
  bright: '\x1b[1m',
  green: '\x1b[32m',
  blue: '\x1b[34m',
  yellow: '\x1b[33m',
  red: '\x1b[31m',
  cyan: '\x1b[36m'
};

// Function to get the current IP address, prioritizing Wi-Fi interface
function getCurrentIPAddress() {
  const interfaces = os.networkInterfaces();
  let wifiAddress = null;
  let fallbackAddress = null;

  for (const name of Object.keys(interfaces)) {
    for (const iface of interfaces[name]) {
      if (iface.family === 'IPv4' && !iface.internal) {
        if (name.toLowerCase().includes('wi-fi') || name.toLowerCase().includes('wifi')) {
          wifiAddress = iface.address;
        } else if (!wifiAddress) {
          fallbackAddress = iface.address;
        }
      }
    }
  }
  return wifiAddress || fallbackAddress || '127.0.0.1';
}

const currentIP = getCurrentIPAddress();
const webSocketServerUrl = `ws://${currentIP}:8080`;

// Write the WebSocket server URL to the configuration file
const configPath = path.join(__dirname, 'config.json');
fs.writeFileSync(configPath, JSON.stringify({ webSocketServerUrl }, null, 2));

const wss = new WebSocket.Server({ port: 8080 });

log('event', `WebSocket server is running on ${webSocketServerUrl}`);

// Game state storage
const games = new Map();
const clientToGame = new Map(); // maps ws -> gameId
const clientToPlayerId = new Map(); // maps ws -> playerId (for disconnect handling)

const words = [
  // Food & Cuisine
  'couscous', 'chorba', 'bourek', 'zlabia', 'kalb elouz', 'makrout', 'baklawa', 'tchektchouka',
  'hrira', 'dolma',  'garantita', 'mahjeb', 'kesra',

  // Daily Life & Objects
  'koursi', 'tabla', 'tberna','sebta', 'gandoura', 'burnous', 'hayek','tarbouche',

  // Nature & Weather
  'chta', 'chems', 'rih', 'bhar', 'djebel', 'sahara', 'khemsin', 'ghabra',
  ,'kharif','ghaba', 'trab', 'wad', 'rmel', 'njoum',

  // Places & Locations
  'souk', 'hammam', 'hanut', 'dar', 'zouj', 'qahoua', 'jame3', 'zanka',
  'cartier', 'houma', 'baladia', 'saha', 'mdrassa', 'melha', 'chra3', 'marsa',

  // Traditional Items
 'derbouka', 'gasba',  'oud',
  'keskas', 'tajin', 'mhrez', 'meqla', 

  // Modern Life
  'tilifoun', 'tomobile', 'telefision', 'radio', 'portable', 'ordinateur', 'internet', 'facebook',
  'taxi','karossa', 'camion', 'metro', 'tram', 'train', 'bus',

  // Animals
  'kelb', 'djaj', 'begra', 'himar', 'khrouf', 'marza', 'serdouk',
   'fakroun', 'dib',  'arneb', 'jrana'
];

function log(type, message) {
  const timestamp = new Date().toISOString();
  switch(type) {
    case 'connection':
      console.log(`${colors.green}[${timestamp}] 🔌 ${message}${colors.reset}`);
      break;
    case 'game':
      console.log(`${colors.blue}[${timestamp}] 🎮 ${message}${colors.reset}`);
      break;
    case 'error':
      console.log(`${colors.red}[${timestamp}] ❌ ${message}${colors.reset}`);
      break;
    case 'event':
      console.log(`${colors.yellow}[${timestamp}] 📢 ${message}${colors.reset}`);
      break;
    default:
      console.log(`[${timestamp}] ${message}`);
  }
}

const ROUND_DURATION = 80000; // 80 seconds per round
const PREP_DURATION = 3000;   // 3 seconds preparation time
const ROUND_END_DURATION = 2000; // 2 seconds between rounds
const POINTS_FOR_CORRECT_GUESS = 100;
const POINTS_FOR_DRAWING = 50;

function cleanGameDataForBroadcast(game) {
  // Create a clean copy without circular references
  return {
    id: game.id,
    players: game.players,
    state: game.state,
    currentWord: game.currentWord,
    currentRound: game.currentRound,
    maxRounds: game.maxRounds,
    roundStartTime: game.roundStartTime,
    playersGuessedCorrect: game.playersGuessedCorrect,
    drawing_data: game.drawing_data
  };
}

function broadcast(gameId, message) {
  let count = 0;
  
  // Clean up payload if it's a game object
  if (message.type === 'game_update' && message.payload) {
    message.payload = cleanGameDataForBroadcast(message.payload);
  }

  wss.clients.forEach(client => {
    if (client.readyState === WebSocket.OPEN && clientToGame.get(client) === gameId) {
      client.send(JSON.stringify(message));
      count++;
    }
  });
  log('event', `Broadcasted ${message.type} to ${count} clients in game ${gameId}`);
}

function getRandomWord() {
  return words[Math.floor(Math.random() * words.length)];
}

wss.on('connection', (ws) => {
  const clientId = uuidv4().substring(0, 8);
  log('connection', `Client ${clientId} connected`);

  ws.on('message', (data) => {
    try {
      const message = JSON.parse(data);
      const { type, gameId, payload } = message;
      log('event', `Received ${type} from ${clientId} for game ${gameId || 'N/A'}`);

      switch (type) {
        case 'create_game':
          // Ensure all required properties are set
          const game = {
            ...payload,
            id: gameId,
            state: payload.state || 'GameState.waiting',
            roundTime: payload.roundTime || 80,
            roundStartTime: null,
            roundTimer: null,
            prepTimer: null,
            cleanupTimer: null,
          };
          // Ensure players array exists
          game.players = game.players || [];
          games.set(gameId, game);
          clientToGame.set(ws, gameId);
          // If creator included in payload.players[0], map their ws to their player id
          if (payload.players && payload.players[0] && payload.players[0].id) {
            clientToPlayerId.set(ws, payload.players[0].id);
          }
          log('game', `Game ${gameId} created by ${payload.players?.[0]?.name || 'unknown'}`);
          broadcast(gameId, {
            type: 'game_update',
            gameId,
            payload: games.get(gameId)
          });
          break;

        case 'join_game':
          if (games.has(gameId)) {
            const game = games.get(gameId);
            if (!game.players.some(p => p.id === payload.player.id)) {
              game.players.push(payload.player);
              log('game', `${payload.player.name} joined game ${gameId}`);
              if (game.players.length === 3) {
                game.maxRounds = 3;
                log('game', `Game ${gameId} is now full (3 players)`);
              }
            }
            clientToGame.set(ws, gameId);
            clientToPlayerId.set(ws, payload.player.id);
            broadcast(gameId, {
              type: 'game_update',
              gameId,
              payload: game
            });
          } else {
            log('error', `Failed to join game ${gameId} - game not found`);
          }
          break;

        case 'start_game':
          if (games.has(gameId)) {
            const game = games.get(gameId);
            // Set maxRounds equal to number of players
            game.maxRounds = game.players.length;
            // Initialize first drawer
            game.players.forEach((p, i) => p.isDrawing = i === 0);
            game.currentRound = 1;
            game.playersGuessedCorrect = [];
            game.state = 'GameState.preparing';
            log('game', `Game ${gameId} started. Total rounds: ${game.maxRounds}`);
            
            // Start the first round properly
            startPrepPhase(gameId);
          }
          break;

        case 'submit_guess':
          if (games.has(gameId)) {
            const game = games.get(gameId);
            if (game.state === 'GameState.drawing' && game.currentWord?.toLowerCase() === payload.guess.toLowerCase()) {
              const playerIndex = game.players.findIndex(p => p.id === payload.playerId);
              if (playerIndex !== -1) {
                game.players[playerIndex].score += 100;
              }
            }
            broadcast(gameId, {
              type: 'game_update',
              gameId,
              payload: game
            });
          }
          break;

        case 'drawing_update':
          if (games.has(gameId)) {
            const game = games.get(gameId);
            if (game.state === 'GameState.drawing') {
              game.drawing_data = payload;
              log('event', `Received drawing update for game ${gameId}`);
              broadcast(gameId, {
                type: 'drawing_update',
                gameId,
                payload: game.drawing_data
              });
            }
          }
          break;

        case 'get_games':
          const availableGames = Array.from(games.values())
            .filter(game => game.state === 'GameState.waiting' && game.players.length < 3);
          ws.send(JSON.stringify({
            type: 'games_list',
            payload: availableGames
          }));
          break;

        case 'correct_guess':
          if (games.has(gameId)) {
            const game = games.get(gameId);
            if (game.state !== 'GameState.drawing') break; // Ignore guesses outside drawing phase
            
            const { playerId } = payload;
            
            // Check if player hasn't already guessed correctly
            if (!game.playersGuessedCorrect.includes(playerId)) {
              // Add player to correct guesses
              game.playersGuessedCorrect.push(playerId);
              
              // Award points to the guesser
              const guesser = game.players.find(p => p.id === playerId);
              if (guesser) {
                guesser.score += POINTS_FOR_CORRECT_GUESS;
              }
              
              // Award points to the drawer if someone guessed correctly
              const drawer = game.players.find(p => p.isDrawing);
              if (drawer) {
                drawer.score += POINTS_FOR_DRAWING;
              }
  
              log('game', `${guesser?.name} correctly guessed the word in game ${gameId}`);
  
              // Check if everyone except drawer has guessed
              const nonDrawingPlayers = game.players.filter(p => !p.isDrawing);
              if (game.playersGuessedCorrect.length === nonDrawingPlayers.length) {
                // End round early if everyone guessed
                clearTimeout(game.roundTimer);
                transitionToRoundEnd(gameId);
              }
  
              broadcast(gameId, {
                type: 'game_update',
                gameId,
                payload: game
              });
            }
          }
          break;

        case 'end_round':
          if (games.has(gameId)) {
            const game = games.get(gameId);
            if (game.state === 'GameState.drawing') {
              log('game', `End round triggered for game ${gameId}`);
              clearTimeout(game.roundTimer);
              transitionToRoundEnd(gameId);
            }
          }
          break;

        case 'chat_message':
          if (games.has(gameId)) {
            const game = games.get(gameId);
            log('event', `Chat message in game ${gameId}: ${payload.message}`);
            broadcast(gameId, {
              type: 'chat_message',
              gameId,
              payload: payload
            });
          }
          break;

        default:
          log('error', `Unknown message type: ${type}`);
      }
    } catch (error) {
      log('error', `Failed to process message: ${error.message}`);
    }
  });

  ws.on('close', () => {
    const gameId = clientToGame.get(ws);
    const playerId = clientToPlayerId.get(ws);
    log('connection', `Client ${clientId} disconnected${gameId ? ` from game ${gameId}` : ''}`);
    if (gameId && games.has(gameId)) {
      const game = games.get(gameId);
      if (playerId) {
        const idx = game.players.findIndex(p => p.id === playerId);
        if (idx !== -1) {
          const playerName = game.players[idx].name;
          game.players.splice(idx, 1);
          log('game', `Player ${playerName} (${playerId}) removed from game ${gameId} due to disconnect`);
          // If the disconnected player was drawing, rotate drawing flag
          if (game.players.length > 0 && game.players.every(p => !p.isDrawing)) {
            // Ensure there's always a drawer (pick first)
            game.players[0].isDrawing = true;
          }

          // Broadcast updated game state
          broadcast(gameId, {
            type: 'game_update',
            gameId,
            payload: game
          });

          // If no players left, cleanup immediately
          if (game.players.length === 0) {
            cleanupGame(gameId);
          } else if (game.players.length < 2 && game.state !== 'GameState.gameOver') {
            // Mark as aborted if not enough players to continue
            game.state = 'GameState.aborted';
            log('game', `Game ${gameId} aborted due to insufficient players`);
            broadcast(gameId, {
              type: 'game_update',
              gameId,
              payload: game
            });
            // Schedule cleanup after short delay
            clearTimeout(game.cleanupTimer);
            game.cleanupTimer = setTimeout(() => cleanupGame(gameId), 30000);
          }
        }
      }
    }
    clientToGame.delete(ws);
    clientToPlayerId.delete(ws);
  });

  ws.on('error', (error) => {
    log('error', `WebSocket error for client ${clientId}: ${error.message}`);
  });
});

function startPrepPhase(gameId) {
  // legacy signature supported: startPrepPhase(gameId) or startPrepPhase(gameId, skipPrep)
  const skipPrep = arguments[1] === true;
  const game = games.get(gameId);
  if (!game || game.state === 'GameState.gameOver') return;

  game.state = 'GameState.preparing';
  game.currentWord = getRandomWord();
  game.roundStartTime = null;
  game.playersGuessedCorrect = [];
  game.drawing_data = null;
  
  const currentDrawer = game.players.find(p => p.isDrawing) || { name: 'unknown' };
  log('game', `Prep phase started for game ${gameId}. Drawer: ${currentDrawer.name}, Word: ${game.currentWord}`);

  broadcast(gameId, {
    type: 'game_update',
    gameId,
    payload: game
  });

  // Clear any existing timers
  clearTimeout(game.prepTimer);
  clearTimeout(game.roundTimer);

  const delay = skipPrep ? 300 : PREP_DURATION;

  // Transition to drawing phase after prep duration (shorter between rounds if skipPrep)
  game.prepTimer = setTimeout(() => {
    if (games.has(gameId)) {
      const currentGame = games.get(gameId);
      if (currentGame.state === 'GameState.preparing') {
        startDrawingPhase(gameId);
      }
    }
  }, delay);
}

function startDrawingPhase(gameId) {
  const game = games.get(gameId);
  if (!game || game.state === 'GameState.gameOver') return;

  game.state = 'GameState.drawing';
  game.roundStartTime = Date.now();
  
  const currentDrawer = game.players.find(p => p.isDrawing);
  log('game', `Drawing phase started for game ${gameId}. Drawer: ${currentDrawer.name}`);

  // Create payload with serverTime reference for accurate client-side timer
  const payload = cleanGameDataForBroadcast(game);
  payload.serverTime = Date.now(); // Include server time for client sync

  broadcast(gameId, {
    type: 'game_update',
    gameId,
    payload: payload
  });

  // Clear any existing timers
  clearTimeout(game.roundTimer);

  // Set up timer for round end
  game.roundTimer = setTimeout(() => {
    if (games.has(gameId)) {
      const currentGame = games.get(gameId);
      if (currentGame.state === 'GameState.drawing' && 
          currentGame.roundStartTime === game.roundStartTime) {
        log('game', `Round time expired in game ${gameId}`);
        transitionToRoundEnd(gameId);
      }
    }
  }, ROUND_DURATION);
}

function transitionToRoundEnd(gameId) {
  const game = games.get(gameId);
  if (!game) return;

  // Clear timers
  clearTimeout(game.roundTimer);
  clearTimeout(game.prepTimer);

  game.state = 'GameState.roundEnd';
  game.drawing_data = null;
  game.roundStartTime = null;

  const currentDrawerIndex = game.players.findIndex(p => p.isDrawing);
  const currentDrawer = game.players[currentDrawerIndex];
  
  log('game', `Round ${game.currentRound} ended in game ${gameId}. Drawer was: ${currentDrawer.name}`);

  broadcast(gameId, {
    type: 'game_update',
    gameId,
    payload: game
  });

  // Check if game should end
  if (game.currentRound >= game.maxRounds) {
    setTimeout(() => endGame(gameId), ROUND_END_DURATION);
  } else {
    // Rotate to next round
    setTimeout(() => {
      game.currentRound++;
      const nextDrawerIndex = (currentDrawerIndex + 1) % game.players.length;
      game.players[currentDrawerIndex].isDrawing = false;
      game.players[nextDrawerIndex].isDrawing = true;
      
      const nextDrawer = game.players[nextDrawerIndex];
      log('game', `Rotating drawer for game ${gameId}. New drawer: ${nextDrawer.name} (Round ${game.currentRound}/${game.maxRounds})`);
      
      // Use a short prep between rounds to avoid showing a long "start game" screen
      startPrepPhase(gameId, true);
    }, ROUND_END_DURATION);
  }
}

function endGame(gameId) {
  const game = games.get(gameId);
  if (!game) return;
  // clear timers
  clearTimeout(game.roundTimer);
  clearTimeout(game.prepTimer);

  game.state = 'GameState.gameOver';
  game.players.sort((a, b) => b.score - a.score);
  
  log('game', `Game ${gameId} ended. Winner: ${game.players[0]?.name || 'none'} with ${game.players[0]?.score || 0} points`);

  broadcast(gameId, {
    type: 'game_update',
    gameId,
    payload: game
  });

  // Schedule cleanup after some time so clients can see results
  clearTimeout(game.cleanupTimer);
  game.cleanupTimer = setTimeout(() => cleanupGame(gameId), 60000);
}

function cleanupGame(gameId) {
  const game = games.get(gameId);
  if (!game) return;

  clearTimeout(game.roundTimer);
  clearTimeout(game.prepTimer);
  clearTimeout(game.cleanupTimer);

  // Remove client mappings and try to close connections that are associated with this game
  for (const [client, gid] of clientToGame.entries()) {
    if (gid === gameId) {
      clientToGame.delete(client);
      clientToPlayerId.delete(client);
      try {
        if (client && client.readyState === WebSocket.OPEN) client.close();
      } catch (e) {
        // ignore
      }
    }
  }

  games.delete(gameId);
  log('event', `Cleaned up game ${gameId}`);
}

// Add server status logging every 30 seconds
setInterval(() => {
  const gameCount = games.size;
  const clientCount = wss.clients.size;
  log('event', `Server status: ${clientCount} clients connected, ${gameCount} active games`);
}, 30000);
