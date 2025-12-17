const fs = require('fs');
const path = require('path');

const PROFILES_FILE = path.join(__dirname, 'player_profiles.json');

// Load profiles from file
function loadProfiles() {
  try {
    if (fs.existsSync(PROFILES_FILE)) {
      const data = fs.readFileSync(PROFILES_FILE, 'utf-8');
      return JSON.parse(data);
    }
  } catch (error) {
    console.error('Error loading player profiles:', error);
  }
  return {};
}

// Save profiles to file
function saveProfiles(profiles) {
  try {
    fs.writeFileSync(PROFILES_FILE, JSON.stringify(profiles, null, 2), 'utf-8');
  } catch (error) {
    console.error('Error saving player profiles:', error);
  }
}

// Get a player's saved profile
function getPlayerProfile(playerId) {
  const profiles = loadProfiles();
  return profiles[playerId] || null;
}

// Save or update a player's profile
function savePlayerProfile(playerId, profile) {
  const profiles = loadProfiles();
  profiles[playerId] = {
    ...profiles[playerId],
    ...profile,
    lastUpdated: new Date().toISOString(),
  };
  saveProfiles(profiles);
  return profiles[playerId];
}

// Get or create a player profile with defaults
function getOrCreatePlayerProfile(playerId, defaultName = null) {
  const profiles = loadProfiles();
  
  if (!profiles[playerId]) {
    profiles[playerId] = {
      id: playerId,
      name: defaultName || 'Player',
      photoURL: 'blue',
      createdAt: new Date().toISOString(),
      lastUpdated: new Date().toISOString(),
    };
    saveProfiles(profiles);
  }
  
  return profiles[playerId];
}

// Update player name and avatar
function updatePlayerProfile(playerId, name, photoURL) {
  const profile = getOrCreatePlayerProfile(playerId);
  return savePlayerProfile(playerId, {
    name: name || profile.name,
    photoURL: photoURL || profile.photoURL,
  });
}

module.exports = {
  getPlayerProfile,
  savePlayerProfile,
  getOrCreatePlayerProfile,
  updatePlayerProfile,
  loadProfiles,
  saveProfiles,
};
