const os = require('os');

const colors = {
  reset: '\x1b[0m',
  bright: '\x1b[1m',
  green: '\x1b[32m',
  blue: '\x1b[34m',
  yellow: '\x1b[33m',
  red: '\x1b[31m',
  cyan: '\x1b[36m'
};

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

module.exports = {
  colors,
  getCurrentIPAddress,
  log
};
