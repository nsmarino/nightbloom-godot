extends Node
class_name CombatManager

enum CombatState {
	INTRO,
	PLAYER_TURN,
	ENEMY_TURN,
	VICTORY,
	DEFEAT,
}

@export var intro_duration: float = 2.0
@export var turn_duration: float = 15.0

var current_state: CombatState = CombatState.INTRO
var turn_timer: float = 0.0
var is_paused: bool = false

# References set by arena
var player_resources: Node
var enemy_resources: Node

func _ready() -> void:
	print("[CombatManager] Initialized")
	# Connect to resource signals for victory/defeat detection
	Events.player_hp_changed.connect(_on_player_hp_changed)
	Events.enemy_hp_changed.connect(_on_enemy_hp_changed)
	Events.combat_paused.connect(_on_combat_paused)
	
	# Start the intro
	_enter_state(CombatState.INTRO)


func _physics_process(delta: float) -> void:
	if is_paused:
		return
	
	match current_state:
		CombatState.INTRO:
			_process_intro(delta)
		CombatState.PLAYER_TURN:
			_process_turn(delta)
		CombatState.ENEMY_TURN:
			_process_turn(delta)
		CombatState.VICTORY:
			pass
		CombatState.DEFEAT:
			pass


func _process_intro(delta: float) -> void:
	turn_timer += delta
	if turn_timer >= intro_duration:
		# START WITH ENEMY TURN FOR DEBUGGING
		print("[CombatManager] Intro complete - starting ENEMY TURN first for debugging")
		_switch_to_enemy_turn()


func _process_turn(delta: float) -> void:
	turn_timer -= delta
	Events.turn_timer_updated.emit(turn_timer, turn_duration)
	
	if turn_timer <= 0:
		_end_current_turn()


func _switch_to_player_turn() -> void:
	print("[CombatManager] === SWITCHING TO PLAYER TURN ===")
	_enter_state(CombatState.PLAYER_TURN)
	turn_timer = turn_duration
	Events.turn_started.emit(true)
	Events.turn_timer_updated.emit(turn_timer, turn_duration)


func _switch_to_enemy_turn() -> void:
	print("[CombatManager] === SWITCHING TO ENEMY TURN ===")
	_enter_state(CombatState.ENEMY_TURN)
	turn_timer = turn_duration
	Events.turn_started.emit(false)
	Events.turn_timer_updated.emit(turn_timer, turn_duration)


func _end_current_turn() -> void:
	match current_state:
		CombatState.PLAYER_TURN:
			print("[CombatManager] Player turn ended")
			Events.turn_ended.emit(true)
			_switch_to_enemy_turn()
		CombatState.ENEMY_TURN:
			print("[CombatManager] Enemy turn ended")
			Events.turn_ended.emit(false)
			_switch_to_player_turn()


func _enter_state(new_state: CombatState) -> void:
	current_state = new_state
	match new_state:
		CombatState.INTRO:
			turn_timer = 0.0
			Events.combat_started.emit()
		CombatState.VICTORY:
			Events.combat_ended.emit(true)
		CombatState.DEFEAT:
			Events.combat_ended.emit(false)


func _on_player_hp_changed(current: int, _max_val: int) -> void:
	if current <= 0 and current_state != CombatState.DEFEAT:
		_enter_state(CombatState.DEFEAT)


func _on_enemy_hp_changed(current: int, _max_val: int) -> void:
	if current <= 0 and current_state != CombatState.VICTORY:
		_enter_state(CombatState.VICTORY)


func _on_combat_paused(paused: bool) -> void:
	is_paused = paused


func is_player_turn() -> bool:
	return current_state == CombatState.PLAYER_TURN


func is_enemy_turn() -> bool:
	return current_state == CombatState.ENEMY_TURN


func get_current_state() -> CombatState:
	return current_state
