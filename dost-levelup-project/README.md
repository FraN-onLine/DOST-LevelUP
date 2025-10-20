# 🌆 CITYSURGE — Build. Survive. Outlast.

A competitive multiplayer strategy-survival game where players build a city one tile at a time while facing waves of climate disasters and environmental crises.

## 🎯 Game Overview

**Genre:** Competitive Strategy / Party Survival  
**Platform:** PC (LAN Multiplayer)  
**Players:** 2–4  
**Match Type:** Round-Based Tactical Arena  
**Core Loop:** Build → Survive → Adapt

*CitySurge* transforms real-world climate challenges into an interactive competition where strategic planning, smart infrastructure, and sustainability lead to survival.

## 🎮 Core Gameplay

## 🎮 Core Gameplay

### 1. **Build Phase (Turn-Based)**
- Each player gets **1 random structure tile** per round
- Place tiles strategically on a shared grid (5×5, 7×7, or 10×10)
- Tiles include: Smart Tower, Solar Farm, Flood Barrier, Watchtower, Data Center, Pollution Plant, Drone Hub
- Each tile has different point values and abilities
- **30 seconds** per turn or until all players place their tile
- **3 rounds** of building before disaster strikes

### 2. **Preparation Phase (5 seconds)**
- **5-second countdown** before disaster begins
- Players spawn on center tiles (up, down, left, right)
- Camera zooms in to focus on the grid
- Get ready for the incoming disaster!

### 3. **Disaster Phase (Real-Time)**
- Random disasters strike: Flood, Wildfire, Tornado, Blackout, Radiation Storm
- **30 seconds** to complete survival tasks
- Press **1** to complete the main disaster task (+120 points)
- Press **Space** for emergency actions (+50 points)
- Visual effects show the disaster type
- **Surviving the disaster = +200 points**

### 4. **Resolution Phase**
- Calculate scores and damage
- Update leaderboard rankings
- Start next round or declare winner

## 🏗️ Tile Types & Strategy

| Tile | Points | Color | Description |
|------|--------|-------|-------------|
| **Smart Tower** | +10 | Blue | Height advantage |
| **Solar Farm** | +8 | Yellow | Powers shield networks |
| **Flood Barrier** | +6 | Cyan | Protects from floods |
| **Watchtower** | +7 | Green | Early warning system |
| **Data Center** | +12 | Magenta | Synergy with energy |
| **Pollution Plant** | -5 | Red | Sabotage opponent |
| **Drone Hub** | +9 | Orange | Mobility and defense |

## 🌪️ Disaster Events

- **Flood**: Rising waters threaten your city
- **Wildfire**: Fire spreads across the grid
- **Tornado**: Destructive winds approach
- **Blackout**: Power grid failure
- **Radiation Storm**: Dangerous radiation detected

## 🎯 Victory Conditions

- **3-7 rounds** total (configurable in settings)
- Highest score after all rounds wins
- Points earned from:
  - Placing tiles (+6 to +12 points)
  - Completing disaster tasks (+120 points)
  - Emergency actions (+50 points)
  - Surviving disasters (+200 points)
  - Sabotage tiles (-5 points for opponents)

## 🚀 How to Play

### Setting Up LAN Multiplayer

1. **Host Setup:**
   - Click "Host Game" on main menu
   - Share your IP address (shown in bottom-right corner)
   - Wait for players to join in lobby
   - Click "Start Game" when ready

2. **Player Setup:**
   - Click "Join Game"
   - Enter host's IP address
   - Click "Connect"
   - Wait in lobby for game to start

3. **Finding IP Address:**
   - **Windows**: Command Prompt → `ipconfig`
   - **Mac**: System Preferences → Network
   - **Linux**: Terminal → `ipconfig`

### Controls

**Build Phase:**
- **Mouse**: Click tiles to select, click grid to place
- **30 seconds** per turn to place your tile

**Preparation Phase:**
- **5 seconds** to get ready
- Players spawn on center tiles
- Camera zooms in automatically

**Disaster Phase:**
- **1**: Complete main disaster task (+120 points)
- **Space**: Emergency action (+50 points)
- **Survive**: Automatic +200 points

**General:**
- **Enter**: Confirm name changes in lobby
- **Back to Menu**: Return to main menu

## 🔧 Technical Features

- **Real-time Multiplayer**: Up to 4 players (1 host + 3 clients)
- **LAN Support**: Play over local WiFi/router
- **Turn-based Building**: Strategic tile placement with timer
- **Real-time Survival**: Quick reaction tasks during disasters
- **Visual Effects**: Disaster-themed overlays and animations
- **Live Leaderboard**: Side panel with ranked scores
- **Camera System**: Automatic zoom when entering map
- **Settings Menu**: Configurable grid size and round count
- **Name Customization**: Change player names in lobby

## 🛠️ Troubleshooting

**Connection Issues:**
- Ensure all computers are on same WiFi/router
- Check Windows Firewall settings
- Try "localhost" for testing on same computer
- Port 12345 must be open

**Game Issues:**
- Make sure at least 2 players are connected
- Only host can start the game
- Each player controls their own character
- Use correct input keys (1, 2, Space during disasters)

## 📁 Project Structure

```
dost-levelup-project/
├── scenes/
│   ├── MainMenu.tscn              # Main menu with Host/Join
│   ├── JoinGame.tscn              # Join game interface
│   ├── Lobby.tscn                 # Player waiting room
│   ├── CitySurgeGame.tscn         # Main game scene
│   └── Player.tscn                # Player character
├── scripts/
│   ├── Network.gd                 # Network management
│   ├── MainMenu.gd                # Main menu logic
│   ├── JoinGame.gd                # Join game logic
│   ├── Lobby.gd                   # Lobby management
│   ├── CitySurgeGame.gd           # Core game logic
│   └── Player.gd                  # Player movement
└── project.godot                  # Project settings
```

## 🎯 Game Balance & Strategy

**High-Value Tiles:**
- Data Center (+12) - Best point value
- Smart Tower (+10) - Height advantage
- Drone Hub (+9) - Mobility

**Defensive Strategy:**
- Flood Barriers for water disasters
- Watchtowers for early warning
- Solar Farms for power systems

**Offensive Strategy:**
- Pollution Plants to sabotage opponents
- Strategic tile placement to block expansion
- Synergy networks for combo effects

## 🌟 Future Enhancements

- **More Tile Types**: Teleporters, Shield Generators, Weather Stations
- **Advanced Disasters**: Earthquake, Cyber Attack, Pandemic
- **Synergy System**: Connected facilities create combo effects
- **Tournament Mode**: Best of 3/5 matches
- **Spectator Mode**: Watch ongoing games
- **Custom Maps**: Different grid sizes and layouts

---

**Build smart, survive smarter — because in this city, every decision shapes your destiny!** 🌆⚡
