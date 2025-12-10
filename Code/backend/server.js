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
            roundTime: payload.roundTime || 80,
            roundStartTime: null,
            roundTimer: null,
            prepTimer: null,
          };
          games.set(gameId, game);
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

function startPrepPhase(gameId) {
  const game = games.get(gameId);
  if (!game || game.state === 'GameState.gameOver') return;

  game.state = 'GameState.preparing';
  game.currentWord = getRandomWord();
  game.roundStartTime = null;
  game.playersGuessedCorrect = [];
  game.drawing_data = null;
  
  const currentDrawer = game.players.find(p => p.isDrawing);
  log('game', `Prep phase started for game ${gameId}. Drawer: ${currentDrawer.name}, Word: ${game.currentWord}`);

  broadcast(gameId, {
    type: 'game_update',
    gameId,
    payload: game
  });

  // Clear any existing timers
  clearTimeout(game.prepTimer);
  clearTimeout(game.roundTimer);

  // Transition to drawing phase after prep duration
  game.prepTimer = setTimeout(() => {
    if (games.has(gameId)) {
      const currentGame = games.get(gameId);
      if (currentGame.state === 'GameState.preparing') {
        startDrawingPhase(gameId);
      }
    }
  }, PREP_DURATION);
}

function startDrawingPhase(gameId) {
  const game = games.get(gameId);
  if (!game || game.state === 'GameState.gameOver') return;

  game.state = 'GameState.drawing';
  game.roundStartTime = Date.now();
  
  const currentDrawer = game.players.find(p => p.isDrawing);
  log('game', `Drawing phase started for game ${gameId}. Drawer: ${currentDrawer.name}`);

  broadcast(gameId, {
    type: 'game_update',
    gameId,
    payload: game
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
      
      startPrepPhase(gameId);
    }, ROUND_END_DURATION);
  }
}

function endGame(gameId) {
  const game = games.get(gameId);
  if (!game) return;

  game.state = 'GameState.gameOver';
  game.players.sort((a, b) => b.score - a.score);
  
  log('game', `Game ${gameId} ended. Winner: ${game.players[0].name} with ${game.players[0].score} points`);

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
  log('event', `Server status: ${clientCount} clients connected, ${gameCount} active games`);
}, 30000);
