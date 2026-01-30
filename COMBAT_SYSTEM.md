# Combat System Prototype

This document describes the JRPG-style turn-based combat system prototyped in `levels/arena.tscn`.

## Overview

The combat system features:
- **Turn-based combat** with alternating player and enemy turns
- **Turn intro phases** - 2-second transition period at the start of each turn where everyone idles
- **Shared health pools** - all party members share HP, all enemies share HP
- **State machine architecture** for both player and enemy behaviors
- **Action Points (AP)** system for special abilities
- **NavigationMesh pathfinding** with RVO avoidance for enemy movement
- **Sequential enemy attacks** - enemies attack one at a time during enemy turn
- **Orbit-based enemy behavior** - enemies circle the player during player turn

---

## Scene Structure

### Main Scene: `levels/arena.tscn`

```
Arena (Node3D) [arena_controller.gd]
├── CombatManager (Node) [combat_manager.gd]
├── Pawn (CharacterBody3D) [Pawn.tscn]
│   └── FollowCamera (Camera3D) [follow_camera.gd] - child of Pawn
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
| `PLAYER_TURN_INTRO` | 2-second transition, everyone idles, HUD animates |
| `PLAYER_TURN` | Player can move, attack, use abilities |
| `ENEMY_TURN_INTRO` | 2-second transition, everyone idles, HUD animates |
| `ENEMY_TURN` | Enemies attack sequentially |
| `VICTORY` | Player won (enemy HP = 0) |
| `DEFEAT` | Player lost (player HP = 0) |

**Key Properties:**
- `intro_duration: float` - Seconds before first turn (default: 2.0)
- `turn_intro_duration: float` - Seconds for turn intro phase (default: 2.0)
- `turn_duration: float` - Seconds per turn (default: 15.0)

**Key Methods:**
- `is_player_turn()` - Returns true during PLAYER_TURN state
- `is_enemy_turn()` - Returns true during ENEMY_TURN state
- `is_in_turn_intro()` - Returns true during either turn intro state
- `get_turn_time_remaining()` - Returns seconds left in current turn
- `get_turn_intro_duration()` - Returns turn intro duration for HUD animation

### 3. Follow Camera
**Script:** `levels/follow_camera.gd`

Simple camera that is a **child of the Pawn**. It maintains a fixed local offset and looks at a target marker (also child of Pawn). Since it's a child, it automatically follows and rotates with the Pawn.

**Key Properties:**
- `target_path: NodePath` - Path to look-at target (CameraTarget marker)
- `offset: Vector3` - Local position offset from Pawn

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
- `FollowCamera` (Camera3D) - Child camera that follows Pawn

**Key Methods:**
- `switch_party_member(index)` - Switch active party member
- `receive_attack(damage)` - Called when hit by enemy

### Player State Machine
**Script:** `objects/nightbloom/combat/player/state_machine.gd`  
**Class:** `PlayerStateMachine`

Handles state transitions and responds to combat events:
- `turn_intro_started` → Immediately snaps to `idle` state
- `turn_started(true)` → Switches to `locomotion` state
- `turn_started(false)` → Switches to `locomotion_slow` state

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

### Player State Base Class
**Script:** `objects/nightbloom/combat/player/PlayerState.gd`  
**Class:** `PlayerState`

Base class for all player states with:
- **Timing helpers:** `duration_longer_than()`, `duration_between()`, etc.
- **Movement:** `apply_movement(delta, speed)` - Moves relative to Pawn's facing direction
- **Rotation:** `apply_rotation(delta)` - Rotates Pawn based on right stick input

**Movement Controls:**
- **Left Stick:** Forward/backward/strafe relative to Pawn's facing
- **Right Stick (horizontal):** Rotates Pawn left/right

### Player States
**Location:** `objects/nightbloom/combat/player/states/`

| State | Description |
|-------|-------------|
| `idle` | Waiting (intro/outro), no movement allowed |
| `locomotion` | Full-speed movement (8.0) during player turn |
| `locomotion_slow` | Half-speed movement (4.0) during enemy turn |
| `attack` | Performing attack animation, uses animation_finished signal |
| `decide_menu` | Menu open, gameplay paused |
| `spell` | Casting a spell |
| `item` | Using an item |
| `guard` | Blocking (reduced damage) |
| `receive_attack` | Being hit, returns to appropriate locomotion based on turn |
| `vulnerable` | Stuck after attack during enemy turn |
| `victory` | Combat won |
| `defeat` | Combat lost |

### Animation-Driven State Timing (Player Attack)
**Script:** `objects/nightbloom/combat/player/states/attack.gd`

Player attack state uses **animation-driven timing**:
- Connects to `animator.animation_finished` signal
- Transitions when animation completes
- `fallback_duration` export as safety net if animation is missing/looping
- Hitbox timing (`hitbox_start`, `hitbox_end`) uses timers for precise control

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
- `delay_between_attacks: float` - Delay after each enemy attack (default: 0.5)

**Turn Intro Behavior:**
- `turn_intro_started` signal → All enemies snap to `idle` state
- Attack queue is cleared, state is reset

**Player Turn Behavior:**
- All enemies enter `locomotion_slow` state
- Enemies orbit around the player at randomized distances

**Enemy Turn Behavior (Sequential Attacks):**
1. Creates a **shuffled attack queue** of all enemies
2. All enemies start in `idle` state
3. First enemy checks if enough turn time remains (vs `fallback_duration`)
4. If enough time: enemy enters `pursue` → `attack` → `evade` → `idle`
5. Enemy emits `attack_cycle_complete` signal when done
6. After `delay_between_attacks`, next enemy attacks
7. Continues until queue empty or insufficient time remains

### Base Enemy
**Scene:** `objects/nightbloom/combat/enemy/base/BaseEnemy.tscn`  
**Script:** `objects/nightbloom/combat/enemy/base/base_enemy.gd`  
**Class:** `BaseEnemy`

Structure:
- `Collider` (CollisionShape3D)
- `NavigationAgent3D` - Pathfinding with RVO avoidance
- `AttackArea` (Area3D) - Hit detection
- `StateMachine` - Enemy AI states

**Orbit Data (Shared between states):**
Stored on BaseEnemy so both `locomotion_slow` and `evade` states can access:
- `orbit_center: Vector3` - Center point (player position)
- `orbit_radius: float` - Distance from center
- `orbit_angle: float` - Current angle on circle
- `orbit_direction: float` - 1.0 = CCW, -1.0 = CW

**Orbit Helper Methods:**
- `setup_orbit(center, radius, direction)` - Initialize orbit data
- `update_orbit_center(new_center)` - Update center and recalculate angle
- `get_orbit_position()` - Get current target position on orbit circle
- `advance_orbit(delta, speed)` - Move along orbit
- `notify_attack_cycle_complete()` - Emit signal when attack sequence done

**Signals:**
- `attack_cycle_complete` - Emitted when enemy finishes attack+evade cycle

### NavigationAgent3D Settings (with RVO Avoidance)
On each `BaseEnemy`:
- `path_desired_distance`: 0.5
- `avoidance_enabled`: true
- `radius`: 0.6 (agent collision radius)
- `neighbor_distance`: 5.0 (detection range for other agents)
- `max_neighbors`: 5
- `time_horizon_agents`: 1.0

The avoidance system uses the `velocity_computed` signal pattern:
1. State calculates desired velocity
2. Calls `nav_agent.set_velocity(desired_velocity)`
3. NavigationAgent3D computes safe velocity avoiding other agents
4. `BaseEnemy._on_velocity_computed()` applies the safe velocity

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

### AI State Base Class
**Script:** `objects/nightbloom/combat/enemy/base/AIState.gd`  
**Class:** `AIState`

Base class for enemy states with avoidance-aware helpers:
- `navigate_to(target, speed, delta)` - Move toward target using navmesh with avoidance
- `move_away_from(target, speed, delta)` - Move away from target with avoidance
- `face_player(delta)` - Rotate to face player
- `move_with_avoidance(desired_velocity)` - Set velocity for RVO processing
- `stop_with_avoidance()` - Stop while still participating in avoidance

### Enemy States
**Location:** `objects/nightbloom/combat/enemy/base/states/`

| State | Description |
|-------|-------------|
| `idle` | Standing still, uses `stop_with_avoidance()` |
| `locomotion_slow` | **Orbits player** during player turn (see below) |
| `pursue` | Chasing player using navmesh |
| `attack` | Performing attack, animation-driven timing |
| `evade` | **Returns to orbit position** after attack |
| `receive_attack` | Being hit, animation-driven timing |
| `death` | Dying |

### Locomotion Slow (Orbit Behavior)
**Script:** `objects/nightbloom/combat/enemy/base/states/locomotion_slow.gd`

During player turn, enemies **orbit around the player**:

**Exports:**
- `base_orbit_radius: float` - Base distance from player (default: 5.0)
- `orbit_radius_variance: float` - Random variance ±1.5 (total range of 3)
- `orbit_speed: float` - Radians per second (default: 0.3)
- `resample_interval: float` - Base time to resample player position (default: 5.0)
- `resample_variance: float` - Random variance for timing (default: 1.5)

**Behavior:**
1. On enter: captures player position, picks random radius and direction
2. Stores orbit data on `character` (BaseEnemy) for sharing with evade state
3. Advances along orbit circle each frame
4. Every ~5 seconds (randomized): resamples player position, new random radius, 50% chance to flip direction
5. Always faces player while orbiting
6. Uses RVO avoidance to prevent collisions with other enemies

### Evade State (Return to Orbit)
**Script:** `objects/nightbloom/combat/enemy/base/states/evade.gd`

After attacking, enemy **returns to their orbit position**:
- Reads orbit data from `character` (BaseEnemy)
- Navigates back to `character.get_orbit_position()`
- Transitions to `idle` when within `arrival_threshold` (default: 1.0)
- Falls back to timer if can't reach position
- Calls `character.notify_attack_cycle_complete()` on exit

### Animation-Driven State Timing (Enemy Attack)
**Script:** `objects/nightbloom/combat/enemy/base/states/attack.gd`

Enemy attack state uses **animation-driven timing**:
- Connects to `animator.animation_finished` signal
- Transitions when animation completes
- `fallback_duration` export used for:
  - Safety net if animation missing
  - **Time checking** before attack starts (enemy manager checks this)

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
- `APContainer` - AP segment bars (3 segments of 30 AP each)
- `TurnIndicatorContainer` - Contains turn labels:
  - `PlayerTurnLabel` - Blue "PLAYER TURN" text
  - `EnemyTurnLabel` - Red "ENEMY TURN" text
  - `VictoryLabel` - Gold "VICTORY!" text
  - `DefeatLabel` - Dark red "DEFEAT..." text
- `DecideMenu` - Menu panel with Spell/Item/Switch buttons

### Turn Indicator Animation
During turn intro phases, the HUD plays a **transition animation**:
- Old turn label scales up (1.5x) and fades out
- New turn label scales in from small (0.5x) and fades in
- Animation duration matches `turn_intro_duration` (2 seconds)
- Uses Tween for smooth transitions

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

### RVO Avoidance
Enemies use Godot's built-in **Reciprocal Velocity Obstacle** avoidance:
- Enabled on `NavigationAgent3D` with `avoidance_enabled = true`
- Agents calculate velocities that naturally steer around each other
- Prevents enemies from bumping into each other while orbiting

---

## Events (Signals)

**Autoload:** `autoloads/events.gd`

### Combat Phase Signals
| Signal | Parameters | Description |
|--------|------------|-------------|
| `combat_started` | - | Combat begins |
| `turn_intro_started` | `is_player_turn: bool` | Turn intro phase begins (everyone idles) |
| `turn_intro_ended` | `is_player_turn: bool` | Turn intro phase ends |
| `turn_started` | `is_player_turn: bool` | Actual turn gameplay begins |
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

### Movement
- `MoveForward`, `MoveBackward`, `MoveLeft`, `MoveRight` - Left stick (relative to Pawn facing)
- `LookLeft`, `LookRight` - Right stick horizontal (rotates Pawn)

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
4. After `intro_duration`, enters `PLAYER_TURN_INTRO`

### Turn Intro Phase (Both Turns)
1. `turn_intro_started` signal emitted
2. Player snaps to `idle` state (no input accepted)
3. All enemies snap to `idle` state
4. HUD plays turn label transition animation
5. After `turn_intro_duration` (2 seconds), actual turn begins

### Player Turn
1. `turn_started(true)` emitted
2. Player enters `locomotion` state (full speed, can attack)
3. Enemies enter `locomotion_slow` state (orbit player)
4. Turn timer counts down
5. Player can: move, rotate, attack, open menu
6. On attack hit: gain 5 AP, enemy takes damage, enemy enters `receive_attack`
7. Turn ends when timer expires → `ENEMY_TURN_INTRO`

### Enemy Turn
1. `turn_started(false)` emitted
2. Player enters `locomotion_slow` (half speed, can guard)
3. Enemy manager creates shuffled attack queue
4. All enemies start in `idle`
5. Sequential attack flow:
   - Check if enough time remains for next attack
   - If yes: enemy enters `pursue` → navigates to player
   - When in range: enemy enters `attack`
   - After attack animation: enemy enters `evade` (returns to orbit)
   - After evade: enemy enters `idle`, signals completion
   - Wait `delay_between_attacks`, start next enemy
6. Player hit → enters `receive_attack` → returns to `locomotion_slow`
7. Turn ends when timer expires → `PLAYER_TURN_INTRO`

### Combat End
- **Victory:** Enemy HP reaches 0, `combat_ended(true)` emitted
- **Defeat:** Player HP reaches 0, `combat_ended(false)` emitted

---

## Key Implementation Details

### Animation-Driven State Timing
Both player and enemy attack/receive_attack states use animation signals:
1. Connect to `animator.animation_finished` signal on state enter
2. Set `animation_finished = true` when animation completes
3. Check `animation_finished` in `check_transition()`
4. Fall back to `fallback_duration` timer if animation never finishes
5. Disconnect signal on state exit

### Orbit System
Enemies share orbit data through the `BaseEnemy` class:
- `locomotion_slow` state sets up orbit (center, radius, direction)
- Data stored on `character` (BaseEnemy instance)
- `evade` state reads orbit data to return to position
- Prevents state coupling while sharing necessary information

### RVO Avoidance Pattern
States use avoidance-aware movement:
```gdscript
# Calculate desired velocity
var desired_velocity: Vector3 = direction * speed

# Let avoidance system modify it
move_with_avoidance(desired_velocity)

# Actual movement happens in BaseEnemy._on_velocity_computed()
```

---

## Future Extensions

The system is designed to support:
- Additional enemy types (new `EnemyData` resources)
- More party members (new `PartyMemberData` resources)
- Spell and item systems (placeholder states exist)
- Multiple combat arenas (reusable components)
- Guard and vulnerable state refinements (noted for next update)
