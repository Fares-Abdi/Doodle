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

// Word list (cleaned up)
const words = [
  'couscous','chorba','bourek','zlabia','kalb elouz','makrout','baklawa','tchektchouka',
  'hrira','dolma','garantita','mahjeb','kesra',
  'koursi','tabla','tberna','sebta','gandoura','burnous','hayek','tarbouche',
  'chta','chems','rih','bhar','djebel','sahara','khemsin','ghabra','kharif','ghaba','trab','wad','rmel','njoum',
  'souk','hammam','hanut','dar','zouj','qahoua','jame3','zanka','cartier','houma','baladia','saha','mdrassa','melha','chra3','marsa',
  'derbouka','gasba','oud','keskas','tajin','mhrez','meqla',
  'tilifoun','tomobile','telefision','radio','portable','ordinateur','internet','facebook','taxi','karossa','camion','metro','tram','train','bus',
  'kelb','djaj','begra','himar','khrouf','marza','serdouk','fakroun','dib','arneb','jrana'
];

let wss = null;
function setWss(server) {
  wss = server;
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
