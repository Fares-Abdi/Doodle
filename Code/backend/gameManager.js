const WebSocket = require('ws');
const { log } = require('./utils');

// Game storage
const games = new Map();
const clientToGame = new Map();
const clientToPlayerId = new Map();

// Timing & scoring constants
const ROUND_DURATION = 80000; // 80 seconds
const PREP_DURATION = 3000;   // 3 seconds
const ROUND_END_DURATION = 2000; // 2 seconds
const POINTS_FOR_CORRECT_GUESS = 100;
const POINTS_FOR_DRAWING = 50;

// Word list (French words)
const words = [
  'chat','chien','maison','voiture','arbre','fleur','soleil','lune',
  'livre','table','chaise','portes','fenetre','cuisine','salle',
  'telephone','ordinateur','souris','clavier','ecran','imprimante',
  'chaussures','chapeau','robe','pantalon','chemise','jupe',
  'pomme','orange','banane','fraise','cerise','pasteque','raisin',
  'pain','beurre','fromage','lait','eau','cafe','the',
  'montagne','riviere','plage','desert','foret','champ','colline',
  'oiseau','papillon','abeille','poisson','tortue','serpent','lion',
  'avion','train','bateau','velo','autobus','motocyclette','moto',
  'horloge','lampe','lit','couverture','oreiller','miroir','peine',
  'couleur','numero','lettre','mot','phrase','histoire','chanson',
  'danser','chanter','courir','sauter','nager','voler','marcher',
  'heureux','triste','fache','peur','amour','sourire','pleurer'
];

let wss = null;
function setWss(server) {
  wss = server;
  // Start periodic check for empty games
  startEmptyGameCheck();
}

// Check every 10 seconds for games that should be cleaned up
// Games in waiting state with no players will be marked and deleted after timeout
function startEmptyGameCheck() {
  const emptyGameTimestamps = new Map(); // Track when games became empty
  const EMPTY_GAME_TIMEOUT = 300000; // 5 minutes before auto-cleanup
  
  setInterval(() => {
    const gamesToDelete = [];
    const now = Date.now();
    
    for (const [gameId, game] of games.entries()) {
      // Check if game has no players
      if (!game.players || game.players.length === 0) {
        // If in waiting state, don't immediately delete - just mark the timestamp
        if (game.state === 'GameState.waiting') {
          if (!emptyGameTimestamps.has(gameId)) {
            emptyGameTimestamps.set(gameId, now);
            log('game', `Game ${gameId} is now empty (waiting state) - will delete after ${EMPTY_GAME_TIMEOUT/1000}s`);
          } else {
            // Check if enough time has passed
            const emptyDuration = now - emptyGameTimestamps.get(gameId);
            if (emptyDuration > EMPTY_GAME_TIMEOUT) {
              log('game', `Deleting empty game ${gameId} after timeout`);
              gamesToDelete.push(gameId);
            }
          }
        }
        // If in gameOver state, cleanup immediately
        else if (game.state === 'GameState.gameOver') {
          log('game', `Cleaning up game ${gameId} in gameOver state`);
          gamesToDelete.push(gameId);
        }
        // For other states, abort and cleanup
        else if (game.state !== 'GameState.aborted') {
          log('game', `Aborting empty game ${gameId} (state: ${game.state})`);
          game.state = 'GameState.aborted';
          broadcast(gameId, { type: 'game_update', gameId, payload: game });
          gamesToDelete.push(gameId);
        }
      } else {
        // Game has players again, clear the timestamp
        if (emptyGameTimestamps.has(gameId)) {
          emptyGameTimestamps.delete(gameId);
          log('game', `Game ${gameId} is no longer empty - reset cleanup timer`);
        }
      }
    }
    
    // Clean up all marked games
    gamesToDelete.forEach(gameId => {
      cleanupGame(gameId);
      emptyGameTimestamps.delete(gameId);
    });
  }, 10000);  // Check every 10 seconds
}

function cleanGameDataForBroadcast(game) {
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
  if (!wss) {
    log('error', 'Broadcast called but WebSocket server not set');
    return;
  }

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

function startPrepPhase(gameId) {
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

  clearTimeout(game.prepTimer);
  clearTimeout(game.roundTimer);

  const delay = skipPrep ? 300 : PREP_DURATION;
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
  log('game', `Drawing phase started for game ${gameId}. Drawer: ${currentDrawer?.name}`);

  const payload = cleanGameDataForBroadcast(game);
  payload.serverTime = Date.now();

  broadcast(gameId, {
    type: 'game_update',
    gameId,
    payload: payload
  });

  clearTimeout(game.roundTimer);

  game.roundTimer = setTimeout(() => {
    if (games.has(gameId)) {
      const currentGame = games.get(gameId);
      if (currentGame.state === 'GameState.drawing' && currentGame.roundStartTime === game.roundStartTime) {
        log('game', `Round time expired in game ${gameId}`);
        transitionToRoundEnd(gameId);
      }
    }
  }, ROUND_DURATION);
}

function transitionToRoundEnd(gameId) {
  const game = games.get(gameId);
  if (!game) return;

  clearTimeout(game.roundTimer);
  clearTimeout(game.prepTimer);

  game.state = 'GameState.roundEnd';
  game.drawing_data = null;
  game.roundStartTime = null;

  const currentDrawerIndex = game.players.findIndex(p => p.isDrawing);
  const currentDrawer = game.players[currentDrawerIndex];

  log('game', `Round ${game.currentRound} ended in game ${gameId}. Drawer was: ${currentDrawer?.name}`);

  broadcast(gameId, {
    type: 'game_update',
    gameId,
    payload: game
  });

  if (game.currentRound >= game.maxRounds) {
    setTimeout(() => endGame(gameId), ROUND_END_DURATION);
  } else {
    setTimeout(() => {
      game.currentRound++;
      const nextDrawerIndex = (currentDrawerIndex + 1) % game.players.length;
      game.players[currentDrawerIndex].isDrawing = false;
      game.players[nextDrawerIndex].isDrawing = true;

      const nextDrawer = game.players[nextDrawerIndex];
      log('game', `Rotating drawer for game ${gameId}. New drawer: ${nextDrawer.name} (Round ${game.currentRound}/${game.maxRounds})`);

      startPrepPhase(gameId, true);
    }, ROUND_END_DURATION);
  }
}

function endGame(gameId) {
  const game = games.get(gameId);
  if (!game) return;
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

  clearTimeout(game.cleanupTimer);
  game.cleanupTimer = setTimeout(() => cleanupGame(gameId), 60000);
}

function cleanupGame(gameId) {
  const game = games.get(gameId);
  if (!game) return;

  clearTimeout(game.roundTimer);
  clearTimeout(game.prepTimer);
  clearTimeout(game.cleanupTimer);

  // Only close connections if game was in an active state (not waiting room)
  // This prevents disconnecting everyone when the waiting room is empty
  if (game.state !== 'GameState.waiting') {
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
  } else {
    // For waiting room games, just clear the mappings without closing connections
    for (const [client, gid] of clientToGame.entries()) {
      if (gid === gameId) {
        clientToGame.delete(client);
        clientToPlayerId.delete(client);
      }
    }
  }

  games.delete(gameId);
  log('event', `Cleaned up game ${gameId}`);
}

// Periodic status log handled by wsHandler (optional), but keep helper export

module.exports = {
  setWss,
  games,
  clientToGame,
  clientToPlayerId,
  getRandomWord,
  cleanGameDataForBroadcast,
  broadcast,
  startPrepPhase,
  startDrawingPhase,
  transitionToRoundEnd,
  endGame,
  cleanupGame,
  // constants
  ROUND_DURATION,
  PREP_DURATION,
  ROUND_END_DURATION,
  POINTS_FOR_CORRECT_GUESS,
  POINTS_FOR_DRAWING
};
