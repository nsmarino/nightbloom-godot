# Combat System Prototype

This document describes the JRPG-style turn-based combat system prototyped in `levels/arena.tscn`.

## Overview

The combat system features:
- **Turn-based combat** with alternating player and enemy turns
- **Shared health pools** - all party members share HP, all enemies share HP
- **State machine architecture** for both player and enemy behaviors
- **Action Points (AP)** system for special abilities
- **NavigationMesh pathfinding** for enemy movement

---

## Scene Structure

### Main Scene: `levels/arena.tscn`

```
Arena (Node3D) [arena_controller.gd]
├── CombatManager (Node) [combat_manager.gd]
├── Pawn (CharacterBody3D) [Pawn.tscn]
├── FollowCamera (Camera3D) [follow_camera.gd]
├── HUD/
│   └── CombatHud (CanvasLayer) [CombatHud.tscn]
├── Level/
│   └── Ground/
│       └── NavigationRegion3D
│           └── FloorBody (StaticBody3D)
├── Lighting/
│   └── DirectionalLight3D
├── EnemySpawns/ [Marker3D children]
└── EnemyGroup (Node) [EnemyGroup.tscn]
```

---

## Core Components

### 1. Arena Controller
**Script:** `levels/arena_controller.gd`

Wires up all combat components on scene load:
- Connects `CombatManager` to resource nodes
- Gives `Pawn` reference to `EnemyGroup`
- Gives `CombatHud` reference to player state machine

### 2. Combat Manager
**Script:** `objects/nightbloom/combat/combat_manager.gd`  
**Class:** `CombatManager`

Controls the overall combat flow using states:

| State | Description |
|-------|-------------|
| `INTRO` | Initial pause before combat begins |
| `PLAYER_TURN` | Player can move, attack, use abilities |
| `ENEMY_TURN` | Enemies pursue and attack |
| `VICTORY` | Player won (enemy HP = 0) |
| `DEFEAT` | Player lost (player HP = 0) |

**Key Properties:**
- `intro_duration: float` - Seconds before first turn (default: 2.0)
- `turn_duration: float` - Seconds per turn (default: 15.0)

---

## Player System

### Pawn
**Scene:** `objects/nightbloom/combat/player/Pawn.tscn`  
**Script:** `objects/nightbloom/combat/player/pawn.gd`  
**Class:** `CombatPawn`

The player-controlled character containing:
- `CollisionShape3D` - Physics collider
- `GroupResources` - Shared party resources (HP/MP/AP)
- `HitArea` (Area3D) - Attack detection
- `StateMachine` - Player state controller

**Key Methods:**
- `switch_party_member(index)` - Switch active party member
- `receive_attack(damage)` - Called when hit by enemy

### Group Resources
**Script:** `objects/nightbloom/combat/player/group_resources.gd`  
**Class:** `GroupResources`

Shared resources for the player's party:

| Resource | Default | Description |
|----------|---------|-------------|
| HP | 100 | Health Points |
| MP | 20 | Mana Points |
| AP | 0 (max 90) | Action Points |

**AP Costs:**
- Spell: 30 AP
- Item: 15 AP
- Party Switch: 15 AP
- Guard: 15 AP
- AP gained per hit: 5 AP

**Damage Modifiers:**
- Guard: 50% damage reduction
- Vulnerable: 150% damage taken

### Player States
**Location:** `objects/nightbloom/combat/player/states/`  
**Base Class:** `PlayerState` (`objects/nightbloom/combat/player/PlayerState.gd`)

| State | Description |
|-------|-------------|
| `idle` | Waiting (intro/outro) |
| `locomotion` | Full-speed movement (player turn) |
| `locomotion_slow` | Half-speed movement (enemy turn) |
| `attack` | Performing attack animation |
| `decide_menu` | Menu open, gameplay paused |
| `spell` | Casting a spell |
| `item` | Using an item |
| `guard` | Blocking (reduced damage) |
| `receive_attack` | Being hit by enemy |
| `vulnerable` | Stuck after attack during enemy turn |
| `victory` | Combat won |
| `defeat` | Combat lost |

### Party Member Data
**Script:** `objects/nightbloom/combat/player/PartyMemberData.gd`  
**Type:** Resource

Defines a party member:
- `display_name: StringName`
- `character_scene: PackedScene` - 3D character model

**Examples:** `party-members/Elena.tres`, `party-members/Asa.tres`

---

## Enemy System

### Enemy Group
**Scene:** `objects/nightbloom/combat/enemy/EnemyGroup.tscn`  
**Contains:**
- `EnemyManager` (Node) - Spawns and controls enemies
- `GroupResources` (Node) - Shared enemy HP

### Enemy Manager
**Script:** `objects/nightbloom/combat/enemy/enemy_manager.gd`  
**Class:** `EnemyManager`

**Exports:**
- `Spawns: Node` - Container of Marker3D spawn points
- `Pawn: CharacterBody3D` - Reference to player
- `EnemyScene: PackedScene` - Enemy template to spawn
- `EnemyDataResource: EnemyData` - Enemy configuration
- `enemy_count: int` - Number of enemies to spawn

**Turn Behavior:**
- **Player Turn:** All enemies enter `locomotion_slow` state
- **Enemy Turn:** One random enemy enters `pursue`, others enter `idle`

### Base Enemy
**Scene:** `objects/nightbloom/combat/enemy/base/BaseEnemy.tscn`  
**Script:** `objects/nightbloom/combat/enemy/base/base_enemy.gd`  
**Class:** `BaseEnemy`

Structure:
- `Collider` (CollisionShape3D)
- `NavigationAgent3D` - Pathfinding
- `AttackArea` (Area3D) - Hit detection
- `StateMachine` - Enemy AI states

### Enemy Data
**Script:** `objects/nightbloom/combat/enemy/EnemyData.gd`  
**Class:** `EnemyData`  
**Type:** Resource

| Property | Default | Description |
|----------|---------|-------------|
| `display_name` | - | Enemy name |
| `character_scene` | - | 3D model PackedScene |
| `speed` | 3.0 | Movement speed |
| `attack_power` | 10 | Damage dealt |
| `attack_range` | 2.0 | Distance to trigger attack |
| `pursue_range` | 15.0 | Detection range |

**Animation Names:**
- `anim_idle`: "Idle"
- `anim_locomotion`: "RUN"
- `anim_attack`: "Combo1"
- `anim_receive_hit`: "HitReact"

**Example:** `enemies/goblin.tres`

### Enemy States
**Location:** `objects/nightbloom/combat/enemy/base/states/`  
**Base Class:** `AIState` (`objects/nightbloom/combat/enemy/base/AIState.gd`)

| State | Description |
|-------|-------------|
| `idle` | Standing still |
| `locomotion_slow` | Slow wandering (player turn) |
| `pursue` | Chasing player using navmesh |
| `attack` | Performing attack |
| `evade` | Retreating after attack |
| `receive_attack` | Being hit |
| `death` | Dying |

### Enemy Group Resources
**Script:** `objects/nightbloom/combat/enemy/enemy_group_resources.gd`  
**Class:** `EnemyGroupResources`

Shared HP pool for all enemies (default: 100 HP).

---

## HUD System

### Combat HUD
**Scene:** `objects/nightbloom/combat/hud/CombatHud.tscn`  
**Script:** `objects/nightbloom/combat/hud/combat_hud.gd`  
**Class:** `CombatHud`

UI Elements:
- `PlayerResourcesLeft/PlayerHealth` - Player HP bar
- `EnemyResources/EnemyHealth` - Enemy HP bar
- `TurnBar` - Turn timer progress
- `APContainer` - AP segment bars
- `TurnIndicator` - "PLAYER TURN" / "ENEMY TURN" label
- `DecideMenu` - Menu panel with Spell/Item/Switch buttons

---

## Navigation System

### NavigationRegion3D
Located at `Level/Ground/NavigationRegion3D`

**NavigationMesh Settings:**
- `geometry_parsed_geometry_type`: Static Colliders (1)
- `cell_height`: 0.05
- `agent_height`: 2.0

**Floor Collider:**
- `BoxShape3D` size: (40, 1, 40)
- Position: (0, -0.5, 6.5) - top surface at Y=0

### NavigationAgent3D
On each `BaseEnemy`:
- `path_desired_distance`: 0.5
- `target_desired_distance`: 1.0

---

## Events (Signals)

**Autoload:** `autoloads/events.gd`

### Combat Phase Signals
| Signal | Parameters | Description |
|--------|------------|-------------|
| `combat_started` | - | Combat begins |
| `turn_started` | `is_player_turn: bool` | New turn begins |
| `turn_ended` | `is_player_turn: bool` | Turn ends |
| `combat_paused` | `paused: bool` | Menu opened/closed |
| `combat_ended` | `player_won: bool` | Combat finished |

### Resource Signals
| Signal | Parameters | Description |
|--------|------------|-------------|
| `player_hp_changed` | `current, max_val` | Player HP updated |
| `player_mp_changed` | `current, max_val` | Player MP updated |
| `player_ap_changed` | `current, max_val` | Player AP updated |
| `player_damaged` | `amount` | Player took damage |
| `enemy_hp_changed` | `current, max_val` | Enemy HP updated |
| `enemy_damaged` | `amount` | Enemy took damage |

### Combat Action Signals
| Signal | Parameters | Description |
|--------|------------|-------------|
| `turn_timer_updated` | `time_remaining, turn_duration` | Timer tick |
| `attack_hit` | `attacker, target, damage` | Attack connected |
| `player_state_changed` | `new_state` | Player state transition |
| `enemy_state_changed` | `enemy, new_state` | Enemy state transition |

---

## Input Actions

Defined in `project.godot`:

### Combat Actions
| Action | Default Binding | Description |
|--------|-----------------|-------------|
| `CombatAttack` | Joypad Button 0 (A/Cross) | Attack |
| `CombatMenu` | Joypad Button 3 (Y/Triangle) | Open menu |
| `CombatGuard` | Joypad Button 1 (B/Circle) | Guard |

### Menu Navigation
| Action | Default Binding | Description |
|--------|-----------------|-------------|
| `MenuUp` | D-pad Up | Navigate up |
| `MenuDown` | D-pad Down | Navigate down |
| `MenuLeft` | D-pad Left | Navigate left |
| `MenuRight` | D-pad Right | Navigate right |
| `MenuConfirm` | Joypad Button 0 (A/Cross) | Confirm selection |
| `MenuCancel` | Joypad Button 1 (B/Circle) | Cancel/back |

### Movement (Standard)
- `MoveForward`, `MoveBackward`, `MoveLeft`, `MoveRight` - Left stick
- `LookLeft`, `LookRight`, `LookUp`, `LookDown` - Right stick (camera, not yet implemented)

---

## File Structure

```
objects/nightbloom/combat/
├── combat_manager.gd
├── player/
│   ├── pawn.gd
│   ├── Pawn.tscn
│   ├── state_machine.gd
│   ├── PlayerState.gd
│   ├── group_resources.gd
│   ├── PartyMemberData.gd
│   ├── party-members/
│   │   ├── Elena.tres
│   │   └── Asa.tres
│   └── states/
│       ├── idle.gd
│       ├── locomotion.gd
│       ├── locomotion_slow.gd
│       ├── attack.gd
│       ├── decide_menu.gd
│       ├── spell.gd
│       ├── item.gd
│       ├── guard.gd
│       ├── receive_attack.gd
│       ├── vulnerable.gd
│       ├── victory.gd
│       └── defeat.gd
├── enemy/
│   ├── enemy_manager.gd
│   ├── EnemyGroup.tscn
│   ├── enemy_group_resources.gd
│   ├── EnemyData.gd
│   ├── enemies/
│   │   └── goblin.tres
│   └── base/
│       ├── base_enemy.gd
│       ├── BaseEnemy.tscn
│       ├── state_machine.gd
│       ├── AIState.gd
│       └── states/
│           ├── idle.gd
│           ├── locomotion_slow.gd
│           ├── pursue.gd
│           ├── attack.gd
│           ├── evade.gd
│           ├── receive_attack.gd
│           └── death.gd
└── hud/
    ├── combat_hud.gd
    └── CombatHud.tscn

levels/
├── arena.tscn
├── arena_controller.gd
└── follow_camera.gd

autoloads/
└── events.gd
```

---

## Turn Flow

### Combat Start
1. `CombatManager` enters `INTRO` state
2. `combat_started` signal emitted
3. All enemies commanded to `idle` state
4. After `intro_duration`, first turn begins

### Player Turn
1. `turn_started(true)` emitted
2. Player enters `locomotion` state
3. Enemies enter `locomotion_slow` state
4. Turn timer counts down
5. Player can: move, attack, open menu
6. On attack hit: gain 5 AP, enemy takes damage
7. Turn ends when timer expires

### Enemy Turn
1. `turn_started(false)` emitted
2. Player enters `locomotion_slow` (or `vulnerable` if mid-attack)
3. One random enemy enters `pursue` state
4. Other enemies enter `idle` state
5. Pursuing enemy navigates to player
6. When in range, enemy attacks
7. After attack, enemy enters `evade` state
8. Turn ends when timer expires

### Combat End
- **Victory:** Enemy HP reaches 0, `combat_ended(true)` emitted
- **Defeat:** Player HP reaches 0, `combat_ended(false)` emitted

---

## Future Extensions

The system is designed to support:
- Additional enemy types (new `EnemyData` resources)
- More party members (new `PartyMemberData` resources)
- Spell and item systems (placeholder states exist)
- Orbit camera control (input actions defined)
- Multiple combat arenas (reusable components)
