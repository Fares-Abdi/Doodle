# Visual Reference Guide - New Chat Panel Design

## Full Layout Overview

```
┌────────────────────────────────┐
│     Chat Panel (Side Panel)    │
│                                │
│ ┌──────────────────────────┐   │
│ │ Players Online    [2]     │   │ <- Header (14px padding)
│ │ Game in progress          │   │
│ └──────────────────────────┘   │
│ ───────────────────────────────│ <- Light divider
│                                │
│ ┌────────────────────────────┐ │
│ │ 🥇 Michael    100 pts     │ │ <- Leaderboard (max 25% height)
│ │ 🥈 Sarah       85 pts     │ │
│ │ 🥉 James       70 pts     │ │
│ └────────────────────────────┘ │
│ ───────────────────────────────│ <- Light divider
│                                │
│ ┌────────────────────────────┐ │
│ │ M │ Michael        │ avatar │ │ <- Chat messages
│ │   │ That's correct! 🎉    │ │    (main section)
│ │   │ (purple gradient)     │ │
│ │   │                       │ │
│ │ S │ Sarah          │avatar │ │
│ │   │ Nice drawing!        │ │
│ │   │ (grey background)    │ │
│ │   │                       │ │
│ │ M │ Michael        │avatar │ │
│ │   │ Thanks!              │ │
│ │   │ (purple gradient)    │ │
│ │                         │ │
│ │ [Input field..] [→]     │ │ <- Input area (8px padding)
│ └────────────────────────────┘ │
└────────────────────────────────┘
```

## Responsive Widths

### Small Phone (375px - iPhone SE)
```
┌────────── Panel (85% = 319px) ──────────┐
│  Compact spacing, readable layout       │
│  Perfect for small hands                │
│  All content fits without scrolling     │
└────────────────────────────────────────┘
```

### Standard Phone (390px - iPhone 12)
```
┌───────────── Panel (75% = 293px) ────────────┐
│  Optimal size for most users               │
│  Good balance of content and space         │
│  Comfortable interaction                   │
└──────────────────────────────────────────────┘
```

### Large Phone (428px - iPhone 12 Pro Max)
```
┌─────────────── Panel (75% = 321px) ──────────────┐
│  Spacious layout                                 │
│  Larger touch targets                           │
│  Professional appearance                        │
└────────────────────────────────────────────────────┘
```

### Tablet (768px - iPad)
```
┌──────────────── Panel (max 420px) ──────────────┐
│  Prevents excessive stretching                 │
│  Maintains optimal width                       │
│  Professional appearance on large screens      │
└────────────────────────────────────────────────┘
```

## Message Bubble Anatomy

### Your Message (Current User)
```
┌─────────────────────────────────┐
│ Avatar │ Bubble                  │
│   M    │ ┌──────────────────────┐│
│        │ │ Michael            │ ││
│        │ │ That's correct!    │ ││
│        │ │ (purple gradient)  │ ││
│        │ └──────────────────────┘│
│        │    ↑
│        │    └─ 16px corner radius
│        │
│        └─ 8px space
│
└─ Avatar (32px diameter, colored initial)
```

**Dimensions**:
- Avatar radius: 16px
- Avatar to bubble: 8px
- Bubble padding: 14px horizontal, 10px vertical
- Corner radius: 16px
- Bubble gap: 6px vertical
- Text height: Name (12px) + 4px space + Message (14px)

### Other User's Message
```
┌─────────────────────────────────┐
│ Avatar │ Bubble                  │
│   S    │ ┌──────────────────────┐│
│        │ │ Sarah              │ ││
│        │ │ Nice drawing!      │ ││
│        │ │ (grey background)  │ ││
│        │ └──────────────────────┘│
│
└─ Same dimensions, different colors
```

## Text Styling

### Username in Bubble
```
Font Size:     12px
Font Weight:   600 (Semi-bold)
Color:         White (90% opacity) for your message
               Grey.shade700 for others
Line Height:   Single
Max Lines:     1 with ellipsis
Spacing:       0.2 letter spacing
```

### Message Text
```
Font Size:     14px
Font Weight:   500 (Medium)
Color:         White for your message
               Black87 for others
Line Height:   1.4 (good spacing)
Max Lines:     5 with ellipsis
Word Wrap:     Enabled
```

## System Message (Correct Guess)

```
        ┌──────────────────────────┐
        │ 🎉 Correct guess! 🎉     │ <- Centered
        │ (green gradient)         │    Bold, 13px
        │ Subtle shadow            │    All caps friendly
        └──────────────────────────┘

Colors:
- Gradient: green.shade400 → green.shade500
- Text: White, bold
- Shadow: 8px blur, 2px offset, 30% opacity
```

## Input Area

```
┌──────────────────────────────────┐
│ [Input field text...] [Send →]   │
│  └─────────────────┘ └─────────┘ │
│   Auto-expanding    Compact icon  │
│   up to maxLines    (18px)        │
│   Hint text changes              │
│   based on role                  │
└──────────────────────────────────┘

Input Field:
- Min height: 40px (with padding)
- Max lines: null (auto-expand)
- Min lines: 1
- Padding: 14px horizontal, 10px vertical
- Border radius: 24px (pill shape)
- Background: grey.shade100

Send Button:
- Width: 40px (10px padding + 20px min)
- Height: 40px
- Icon size: 18px
- Gradient: deepPurple.shade400 → deepPurple.shade600
- Borderless, rounded
```

## Spacing Measurements

### Horizontal Padding
```
Panel Edge
│
└─ 10px (panel padding on chat section)
   │
   └─ 8px (between avatar and bubble)
      │
      └─ 14px (inside bubble padding)
         │
         └─ Text content
```

### Vertical Spacing
```
Header
├─ 14px padding
├─ Header content (title + subtitle)
├─ 14px padding
│
Divider (0.5px line, grey.shade200)
│
Leaderboard
├─ 10px padding top
├─ Entry 1
├─ 8px gap
├─ Entry 2
├─ 8px gap
├─ Entry 3
├─ 10px padding bottom
│
Divider (0.5px line, grey.shade200)
│
Chat Messages
├─ 12px padding top
├─ Message bubble 1
├─ 6px gap
├─ Message bubble 2
├─ 6px gap
├─ Message bubble 3
├─ 12px padding bottom
│
Divider (0.5px line, grey.shade200)
│
Input Area
├─ 8px padding vertical
├─ 10px padding horizontal
├─ Input field + send button
├─ 8px padding vertical
```

## Color Palette

### Your Messages
```
┌─────────────────────────────────────┐
│ Gradient Background                 │
│ From: Colors.deepPurple.shade400    │
│       #7C3AED (Vibrant Purple)      │
│ To:   Colors.deepPurple.shade500    │
│       #6D28D9 (Deeper Purple)       │
│                                     │
│ Text Color: Colors.white (100%)     │
│ Avatar Color: Varies by user        │
└─────────────────────────────────────┘
```

### Other Messages
```
┌─────────────────────────────────────┐
│ Background: Colors.grey.shade100    │
│            #F3F4F6 (Light Grey)     │
│                                     │
│ Text Color: Colors.black87          │
│ Name: Colors.grey.shade700          │
│ Avatar Color: Varies by user        │
└─────────────────────────────────────┘
```

### System Messages
```
┌─────────────────────────────────────┐
│ Gradient Background                 │
│ From: Colors.green.shade400         │
│       #4ADE80 (Light Green)         │
│ To:   Colors.green.shade500         │
│       #22C55E (Normal Green)        │
│                                     │
│ Text Color: Colors.white (100%)     │
│ Font Weight: Bold                   │
└─────────────────────────────────────┘
```

### Avatar Colors (from AvatarColorHelper)
```
[Blue, Red, Green, Orange, Purple, Pink, Teal, Amber, Indigo, Cyan]
- Automatically assigned based on username
- Consistent across the app
- Vibrant, easily distinguishable
```

## Shadow Effects

### Message Bubbles
```
Color:    Colors.black (or specific color)
Opacity:  20% (for you) / 6% (for others)
Blur:     8px
Spread:   0px
Offset:   (0, 2) - slight downward shadow
Effect:   Subtle depth, not overwhelming
```

### Header & Footer
```
Color:    Colors.black
Opacity:  15%
Blur:     24px
Spread:   0px
Offset:   (-8, 0) - leftward for side panel
Effect:   Smooth panel appearance
```

## Animation Details

### Auto-Scroll
```
Duration: 300ms
Curve: Curves.easeOut
Trigger: Every new message (with 100ms debounce)
Effect: Smooth, natural scrolling to latest message
```

### Message List
```
Type: ListView.builder
Rebuild: Only affected items
Performance: O(1) on message add
Scroll Physics: BouncingScrollPhysics (iOS-like)
```

## Breakpoint Values

| Metric | Small (<400px) | Standard (400px+) | Large (>600px) |
|--------|---|---|---|
| Panel Width | 85% | 75% | Max 420px |
| Panel Min Width | 280px | 280px | 280px |
| Header Font | 16px | 18px | 18px |
| Subtitle Font | 11px | 12px | 12px |
| Message Font | 14px | 14px | 14px |
| Avatar Radius | 16px | 16px | 16px |
| Padding H | 10px | 16px | 16px |
| Padding V | 12px | 14px | 14px |

---

**Note**: All measurements are in density-independent pixels (dp) that scale with device density.
