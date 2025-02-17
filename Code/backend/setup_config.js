const fs = require('fs');
const path = require('path');

// Define the source and destination paths
const sourcePath = path.join(__dirname, 'config.json');
const destinationDir = path.join(__dirname, '../frontend/assets');
const destinationPath = path.join(destinationDir, 'config.json');

// Ensure the destination directory exists
if (!fs.existsSync(destinationDir)) {
  fs.mkdirSync(destinationDir, { recursive: true });
}

// Copy the configuration file
fs.copyFileSync(sourcePath, destinationPath);

console.log(`Configuration file copied to ${destinationPath}`);
