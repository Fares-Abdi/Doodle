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
const clientToGame = new Map();

const words = [
  'cat', 'dog', 'house', 'tree', 'car', 'sun', 'moon', 'star',
  'book', 'phone', 'computer', 'pizza', 'flower', 'bird', 'fish',
  // ... add more words
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

function broadcast(gameId, message) {
  let count = 0;
  wss.clients.forEach(client => {
    if (client.readyState === WebSocket.OPEN && clientToGame.get(client) === gameId) {
      client.send(JSON.stringify(message));
      count++;
    }
  });
  log('event', `Broadcasted to ${count} clients in game ${gameId}`);
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
          games.set(gameId, payload);
          clientToGame.set(ws, gameId);
          log('game', `Game ${gameId} created by ${payload.players[0].name}`);
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
            game.state = 'GameState.drawing';
            game.currentWord = getRandomWord();
            game.roundStartTime = Date.now();
            game.currentRound = 0;
            broadcast(gameId, {
              type: 'game_update',
              gameId,
              payload: game
            });
          }
          break;

        case 'submit_guess':
          if (games.has(gameId)) {
            const game = games.get(gameId);
            if (game.currentWord?.toLowerCase() === payload.guess.toLowerCase()) {
              const playerIndex = game.players.findIndex(p => p.id === payload.playerId);
              if (playerIndex !== -1) {
                game.players[playerIndex].score += 100;
                
                // Handle round end
                endRound(gameId);
                setTimeout(() => startNewRound(gameId), 3000);
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
            game.drawing_data = payload;
            log('event', `Received drawing update for game ${gameId}`);
            broadcast(gameId, {
              type: 'drawing_update',  // Changed from 'game_update'
              gameId,
              payload: game.drawing_data
            });
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

        default:
          log('error', `Unknown message type: ${type}`);
      }
    } catch (error) {
      log('error', `Failed to process message: ${error.message}`);
    }
  });

  ws.on('close', () => {
    const gameId = clientToGame.get(ws);
    log('connection', `Client ${clientId} disconnected${gameId ? ` from game ${gameId}` : ''}`);
    if (gameId && games.has(gameId)) {
      const game = games.get(gameId);
      // Handle player disconnection
      // You might want to implement reconnection logic here
    }
    clientToGame.delete(ws);
  });

  ws.on('error', (error) => {
    log('error', `WebSocket error for client ${clientId}: ${error.message}`);
  });
});

function endRound(gameId) {
  const game = games.get(gameId);
  if (!game) return;

  game.currentRound++;
  game.state = 'GameState.roundEnd';
  game.drawing_data = null;
  game.currentWord = null;
  game.roundStartTime = null;
  game.playersGuessedCorrect = [];

  // Rotate drawer
  const currentDrawerIndex = game.players.findIndex(p => p.isDrawing);
  game.players[currentDrawerIndex].isDrawing = false;
  const nextDrawerIndex = (currentDrawerIndex + 1) % game.players.length;
  game.players[nextDrawerIndex].isDrawing = true;

  if (game.currentRound >= game.maxRounds) {
    game.state = 'GameState.gameOver';
  }

  broadcast(gameId, {
    type: 'game_update',
    gameId,
    payload: game
  });
}

function startNewRound(gameId) {
  const game = games.get(gameId);
  if (!game || game.state === 'GameState.gameOver') return;

  game.state = 'GameState.drawing';
  game.currentWord = getRandomWord();
  game.roundStartTime = Date.now();
  game.playersGuessedCorrect = [];

  broadcast(gameId, {
    type: 'game_update',
    gameId,
    payload: game
  });
}

// Add server status logging every 30 seconds
setInterval(() => {
  const gameCount = games.size;
  const clientCount = wss.clients.size;
  log('status', `Server status: ${clientCount} clients connected, ${gameCount} active games`);
}, 30000);
