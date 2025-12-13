const WebSocket = require('ws');
const { v4: uuidv4 } = require('uuid');
const { log } = require('./utils');
const gm = require('./gameManager');

const wss = new WebSocket.Server({ port: 8080 });
gm.setWss(wss);

log('event', `WebSocket server is running on ws://<server_ip>:8080`);

wss.on('connection', (ws) => {
  const clientId = uuidv4().substring(0, 8);
  log('connection', `Client ${clientId} connected`);

  ws.on('message', (data) => {
    try {
      const message = JSON.parse(data);
      const { type, gameId, payload } = message;
      log('event', `Received ${type} from ${clientId} for game ${gameId || 'N/A'}`);

      switch (type) {
        case 'create_game': {
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
          game.players = game.players || [];
          gm.games.set(gameId, game);
          gm.clientToGame.set(ws, gameId);
          if (payload.players && payload.players[0] && payload.players[0].id) {
            gm.clientToPlayerId.set(ws, payload.players[0].id);
          }
          log('game', `Game ${gameId} created by ${payload.players?.[0]?.name || 'unknown'}`);
          gm.broadcast(gameId, { type: 'game_update', gameId, payload: gm.games.get(gameId) });
          break;
        }

        case 'join_game': {
          if (gm.games.has(gameId)) {
            const game = gm.games.get(gameId);
            if (!game.players.some(p => p.id === payload.player.id)) {
              game.players.push(payload.player);
              log('game', `${payload.player.name} joined game ${gameId}`);
              if (game.players.length === 3) {
                game.maxRounds = 3;
                log('game', `Game ${gameId} is now full (3 players)`);
              }
            }
            gm.clientToGame.set(ws, gameId);
            gm.clientToPlayerId.set(ws, payload.player.id);
            gm.broadcast(gameId, { type: 'game_update', gameId, payload: game });
          } else {
            log('error', `Failed to join game ${gameId} - game not found`);
          }
          break;
        }

        case 'leave_game': {
          if (gameId && gm.games.has(gameId)) {
            const game = gm.games.get(gameId);
            const playerId = gm.clientToPlayerId.get(ws);
            if (playerId) {
              const idx = game.players.findIndex(p => p.id === playerId);
              if (idx !== -1) {
                const playerName = game.players[idx].name;
                const wasCreator = game.players[idx].isCreator;
                game.players.splice(idx, 1);
                log('game', `Player ${playerName} (${playerId}) left game ${gameId}`);
                
                // If creator left, pass the creator role to the next player
                if (wasCreator && game.players.length > 0) {
                  game.players[0].isCreator = true;
                  log('game', `Creator role passed to ${game.players[0].name} in game ${gameId}`);
                }
                
                // Handle completely empty game only
                if (game.players.length === 0) {
                  log('game', `Game ${gameId} is now empty - cleanup`);
                  gm.cleanupGame(gameId);
                }
                // Game continues with remaining players - broadcast update
                else {
                  log('game', `Game ${gameId} continues with ${game.players.length} players`);
                  gm.broadcast(gameId, { type: 'game_update', gameId, payload: game });
                }
              }
            }
          }
          break;
        }

        case 'start_game': {
          if (gm.games.has(gameId)) {
            const game = gm.games.get(gameId);
            game.maxRounds = game.players.length;
            game.players.forEach((p, i) => p.isDrawing = i === 0);
            game.currentRound = 1;
            game.playersGuessedCorrect = [];
            game.state = 'GameState.preparing';
            log('game', `Game ${gameId} started. Total rounds: ${game.maxRounds}`);
            gm.startPrepPhase(gameId);
          }
          break;
        }

        case 'submit_guess': {
          if (gm.games.has(gameId)) {
            const game = gm.games.get(gameId);
            if (game.state === 'GameState.drawing' && game.currentWord?.toLowerCase() === payload.guess.toLowerCase()) {
              const playerIndex = game.players.findIndex(p => p.id === payload.playerId);
              if (playerIndex !== -1) {
                game.players[playerIndex].score += 100;
              }
            }
            gm.broadcast(gameId, { type: 'game_update', gameId, payload: game });
          }
          break;
        }

        case 'drawing_update': {
          if (gm.games.has(gameId)) {
            const game = gm.games.get(gameId);
            if (game.state === 'GameState.drawing') {
              game.drawing_data = payload;
              log('event', `Received drawing update for game ${gameId}`);
              gm.broadcast(gameId, { type: 'drawing_update', gameId, payload: game.drawing_data });
            }
          }
          break;
        }

        case 'get_games': {
          const availableGames = Array.from(gm.games.values()).filter(game => 
            game.state === 'GameState.waiting' && 
            game.players && 
            game.players.length > 0 &&
            game.players.length < 8
          );
          log('event', `Retrieved ${availableGames.length} available games`);
          ws.send(JSON.stringify({ type: 'games_list', payload: availableGames }));
          break;
        }

        case 'correct_guess': {
          if (gm.games.has(gameId)) {
            const game = gm.games.get(gameId);
            if (game.state !== 'GameState.drawing') break;

            const { playerId } = payload;
            if (!game.playersGuessedCorrect.includes(playerId)) {
              game.playersGuessedCorrect.push(playerId);
              const guesser = game.players.find(p => p.id === playerId);
              if (guesser) {
                // Calculate speed-based points
                // Faster guesses = more points
                const timeElapsed = Date.now() - new Date(game.roundStartTime).getTime();
                const totalRoundTime = game.roundTime * 1000; // Convert to ms
                const timeRemaining = Math.max(0, totalRoundTime - timeElapsed);
                const speedPercentage = timeRemaining / totalRoundTime; // 1.0 = instant, 0.0 = timeout
                
                // Points scale: 100-300 based on speed
                // 100% speed (instant) = 300 points
                // 50% speed (half time) = 200 points  
                // 0% speed (timeout) = 100 points
                const speedPoints = Math.round(100 + (speedPercentage * 200));
                guesser.score += speedPoints;
                
                log('game', `${guesser?.name} guessed correctly in ${(timeElapsed/1000).toFixed(1)}s, earned ${speedPoints} points`);
              }
              
              const drawer = game.players.find(p => p.isDrawing);
              if (drawer) {
                // Drawer always gets 50 bonus points when someone guesses
                drawer.score += 50;
              }

              const nonDrawingPlayers = game.players.filter(p => !p.isDrawing);
              if (game.playersGuessedCorrect.length === nonDrawingPlayers.length) {
                clearTimeout(game.roundTimer);
                gm.transitionToRoundEnd(gameId);
              }

              gm.broadcast(gameId, { type: 'game_update', gameId, payload: game });
            }
          }
          break;
        }

        case 'end_round': {
          if (gm.games.has(gameId)) {
            const game = gm.games.get(gameId);
            if (game.state === 'GameState.drawing') {
              log('game', `End round triggered for game ${gameId}`);
              clearTimeout(game.roundTimer);
              gm.transitionToRoundEnd(gameId);
            }
          }
          break;
        }

        case 'chat_message': {
          if (gm.games.has(gameId)) {
            const game = gm.games.get(gameId);
            log('event', `Chat message in game ${gameId}: ${payload.message}`);
            gm.broadcast(gameId, { type: 'chat_message', gameId, payload: payload });
          }
          break;
        }

        case 'update_player': {
          if (gm.games.has(gameId)) {
            const game = gm.games.get(gameId);
            const { playerId, name, photoURL } = payload;
            const playerIndex = game.players.findIndex(p => p.id === playerId);
            if (playerIndex !== -1) {
              game.players[playerIndex].name = name;
              game.players[playerIndex].photoURL = photoURL;
              log('game', `Player ${playerId} updated: name=${name}, avatar=${photoURL}`);
              gm.broadcast(gameId, { type: 'game_update', gameId, payload: game });
            }
          }
          break;
        }

        default:
          log('error', `Unknown message type: ${type}`);
      }
    } catch (error) {
      log('error', `Failed to process message: ${error.message}`);
    }
  });

  ws.on('close', () => {
    const gameId = gm.clientToGame.get(ws);
    const playerId = gm.clientToPlayerId.get(ws);
    log('connection', `Client ${clientId} disconnected${gameId ? ` from game ${gameId}` : ''}`);
    
    if (gameId && gm.games.has(gameId)) {
      const game = gm.games.get(gameId);
      if (playerId) {
        const idx = game.players.findIndex(p => p.id === playerId);
        if (idx !== -1) {
          const playerName = game.players[idx].name;
          const wasCreator = game.players[idx].isCreator;
          game.players.splice(idx, 1);
          log('game', `Player ${playerName} (${playerId}) removed from game ${gameId} due to disconnect`);
          
          // If creator left, pass the creator role to the next player
          if (wasCreator && game.players.length > 0) {
            game.players[0].isCreator = true;
            log('game', `Creator role passed to ${game.players[0].name} in game ${gameId}`);
          }
          
          // Handle completely empty game only
          if (game.players.length === 0) {
            log('game', `Game ${gameId} is now empty - cleanup`);
            gm.cleanupGame(gameId);
          }
          // Game continues with remaining players - broadcast update
          else {
            log('game', `Game ${gameId} continues with ${game.players.length} players`);
            gm.broadcast(gameId, { type: 'game_update', gameId, payload: game });
          }
        }
      }
    }
    
    gm.clientToGame.delete(ws);
    gm.clientToPlayerId.delete(ws);
  });

  ws.on('error', (error) => {
    log('error', `WebSocket error for client ${clientId}: ${error.message}`);
  });
});

// Server status logging every 30 seconds
setInterval(() => {
  const gameCount = gm.games.size;
  const clientCount = wss.clients.size;
  log('event', `Server status: ${clientCount} clients connected, ${gameCount} active games`);
}, 30000);

module.exports = wss;
