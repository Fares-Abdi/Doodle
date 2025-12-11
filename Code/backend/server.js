const fs = require('fs');
const path = require('path');

// Keep any setup script
require('./setup_config');

const { getCurrentIPAddress, log } = require('./utils');

const currentIP = getCurrentIPAddress();
const webSocketServerUrl = `ws://${currentIP}:8080`;

// Write the WebSocket server URL to the configuration file
const configPath = path.join(__dirname, 'config.json');
fs.writeFileSync(configPath, JSON.stringify({ webSocketServerUrl }, null, 2));

// Start WebSocket handler (creates server on port 8080)
require('./wsHandler');

log('event', `WebSocket server configured in ${configPath} -> ${webSocketServerUrl}`);
