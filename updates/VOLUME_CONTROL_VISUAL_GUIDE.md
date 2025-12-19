# Volume Control - Visual Reference & Usage Guide

## 1. Settings Dialog (Lobby Screen)

### Layout
```
┌─────────────────────────────────────┐
│                                     │
│          ⚙️ (gradient circle)       │
│                                     │
│         Settings                   │
│   Configure server connection       │
│           and audio                 │
│                                     │
├─────────────────────────────────────┤
│ 🔗 SERVER URL                       │
│ ┌─────────────────────────────────┐ │
│ │ ws://192.168.200.163:8080       │ │
│ └─────────────────────────────────┘ │
├─────────────────────────────────────┤
│ 🔊 AUDIO SETTINGS                   │
│                                     │
│ 🎵 Music                         50% │
│ ├──────●─────────────────────────┤  │
│                                     │
│ 🔊 Sound Effects                  70% │
│ ├──────────────────●──────────────┤  │
│                                     │
│ ┌──────────┬──────────┐             │
│ │ ✓ Music  │ ✓ SFX    │             │
│ └──────────┴──────────┘             │
│                                     │
├─────────────────────────────────────┤
│                                     │
│  [Cancel]     [Save Settings]       │
│                                     │
└─────────────────────────────────────┘
```

### Color Scheme
- **Dialog Background:** Deep Purple (deepPurple.shade800/900)
- **Music Icon:** Cyan
- **SFX Icon:** Green Accent
- **Active Slider:** Cyan (music) / Green (SFX)
- **Border:** Purple Accent with opacity

### Interaction
- Swipe left/right on sliders to adjust volume
- Tap toggle buttons to enable/disable audio
- View real-time percentage updates
- Save settings when done

---

## 2. Chat Panel Volume Control

### Layout
```
┌───────────────────────────────┐
│  Room #1    👥 2/3   Status   │  <- Header
├───────────────────────────────┤
│  Player: 100 pts ⭐          │
│  Player: 80 pts              │  <- Leaderboard
│  You: 60 pts                 │
├───────────────────────────────┤
│ 🎵 ├──●─────────────┤ 50%     │  <- Volume Controls
│ 🔊 ├───────────●────┤ 70%     │
├───────────────────────────────┤
│ ┌─────────────────────────┐   │
│ │ Player: Let's draw!     │   │
│ │ You: Nice!              │   │  <- Chat Messages
│ │                         │   │
│ └─────────────────────────┘   │
├───────────────────────────────┤
│ [Type a message...]           │  <- Input
└───────────────────────────────┘
```

### Compact Design
- **Height:** ~80px total (minimal)
- **Music Row:** Icon + slim slider + percentage
- **SFX Row:** Icon + slim slider + percentage
- **Spacing:** 8px vertical gap between rows

### Visual Elements
- Music icon: Cyan (shows music_note when enabled, music_off when disabled)
- SFX icon: Green (shows volume_up when enabled, volume_mute when disabled)
- Sliders: Extra thin (2px track), small thumb (6px)
- Percentage: 28px width, right-aligned

---

## 3. Visual Hierarchy

### Settings Dialog
```
Large Circular Icon (60x60)
        ↓
Title Text (22px)
        ↓
Description (14px, dim)
        ↓
Section Headers (14px, bold)
        ↓
Input Fields / Sliders
        ↓
Action Buttons (Full Width)
```

### Chat Panel Controls
```
Icon (16px)
  ↓
Slider (stretch)
  ↓
Percentage (10px, right)
```

---

## 4. Color Reference

### Primary Colors
- **Dialog Background:** `Colors.deepPurple.shade800.withOpacity(0.95)`
- **Dialog Border:** `Colors.purpleAccent.withOpacity(0.3)`
- **Dialog Shadow:** `Colors.deepPurple.withOpacity(0.5)`

### Status Colors
- **Music Controls:** `Colors.cyan`
- **SFX Controls:** `Colors.greenAccent`
- **Enabled Toggle:** `Colors.greenAccent.withOpacity(0.2)` bg, `Colors.greenAccent` text
- **Disabled Toggle:** `Colors.red.withOpacity(0.2)` bg, `Colors.red` text
- **Active Slider:** `Colors.cyan` (music) / `Colors.greenAccent` (SFX)
- **Inactive Slider:** `Colors.white.withOpacity(0.2)` (dialog) / `Colors.grey.shade300` (chat)

---

## 5. Usage Examples

### Accessing Settings Dialog
```
User taps Settings button (top-right, lobby screen)
  ↓
Dialog opens with backdrop blur
  ↓
User adjusts sliders/toggles
  ↓
User taps "Save Settings"
  ↓
Changes applied immediately
  ↓
Confirmation SnackBar shown
```

### Adjusting Volume in Chat
```
Chat panel visible during gameplay
  ↓
User sees volume sliders below leaderboard
  ↓
User drags slider to adjust
  ↓
Volume changes in real-time
  ↓
Percentage updates instantly
  ↓
No disruption to gameplay
```

---

## 6. Responsive Behavior

### Small Phones (< 390px)
- Dialog scales appropriately
- Sliders remain responsive
- Text truncates with ellipsis if needed

### Standard Phones (390px+)
- Dialog displays at normal width
- Full spacing maintained
- All controls clearly visible

### Tablets (768px+)
- Dialog maintains readable width
- Extra spacing for comfort
- Touch targets remain optimal (48px minimum)

---

## 7. State Persistence

Currently:
- ✅ Volume changes take effect immediately
- ✅ Changes persist during current session
- ⏳ Future: Could be saved to SharedPreferences

---

## 8. Accessibility Features

- **Large Touch Targets:** 48px minimum (buttons, toggles)
- **High Contrast:** Cyan/green on dark background
- **Icons + Text:** Every action labeled
- **Percentage Display:** Numeric feedback on slider position
- **Color + Shape:** Toggles show state via both color and icon
- **No Rapid Changes:** Smooth animations on state changes

---

## 9. Keyboard Integration

- **TextField:** Standard keyboard input (Android/iOS native)
- **Sliders:** Direct drag interaction
- **Toggles:** Tap to activate
- **Enter Key:** Not used (sliders are analog input)

---

## 10. Performance Considerations

- **StatefulBuilder:** Used for local state updates only
- **Minimal Rebuilds:** Only volume widget rebuilds on changes
- **No External API Calls:** All operations local to AudioService
- **Smooth Animations:** Slider transitions are hardware-accelerated

---

**Last Updated:** December 19, 2025
