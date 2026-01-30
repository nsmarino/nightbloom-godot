extends Node
class_name PlayerStateMachine

@export var pawn: CharacterBody3D
@export var group_resources: Node
@export var default_state: String = "idle"

var states: Dictionary
var current_state: Node
var animator: AnimationPlayer
var hit_area: Area3D
var enemy_group: Node


func _ready() -> void:
	await get_tree().process_frame
	
	collect_states()
	
	if states.has(default_state):
		current_state = states[default_state]
		current_state.mark_enter_state()
		current_state.on_enter()
	
	Events.turn_intro_started.connect(_on_turn_intro_started)
	Events.turn_started.connect(_on_turn_started)
	Events.turn_ended.connect(_on_turn_ended)
	Events.combat_ended.connect(_on_combat_ended)


func _physics_process(delta: float) -> void:
	if current_state == null:
		return
	
	var verdict: Array = current_state.check_transition(delta)
	if verdict[0]:
		switch_to(verdict[1])
	
	current_state.update(delta)


func switch_to(next_state_name: String) -> void:
	if not states.has(next_state_name):
		push_warning("PlayerStateMachine: State not found: " + next_state_name)
		return
	
	if current_state:
		current_state.on_exit()
	
	current_state = states[next_state_name]
	current_state.mark_enter_state()
	current_state.on_enter()


func force_switch_to(next_state_name: String) -> void:
	switch_to(next_state_name)


func collect_states() -> void:
	for child in get_children():
		if child is PlayerState:
			states[child.state_name] = child
			child.pawn = pawn
			child.spawn_point = pawn.global_position
			child.group_resources = group_resources
			child.animator = animator
			child.hit_area = hit_area
			child.enemy_group = enemy_group


func set_animator(anim_player: AnimationPlayer) -> void:
	animator = anim_player
	for state in states.values():
		state.animator = animator


func set_hit_area(area: Area3D) -> void:
	hit_area = area
	for state in states.values():
		state.hit_area = area


func set_enemy_group(group: Node) -> void:
	enemy_group = group
	for state in states.values():
		state.enemy_group = group


func _on_turn_intro_started(_is_player_turn: bool) -> void:
	# During turn intro, snap to idle immediately regardless of current state
	print("[PlayerStateMachine] Turn intro started - snapping to idle")
	switch_to("idle")


func _on_turn_started(is_player_turn: bool) -> void:
	# This is called AFTER the turn intro phase completes
	if is_player_turn:
		# Clear off-balance at start of player turn
		if pawn.is_active_off_balance():
			pawn.set_active_off_balance(false)
			print("[PlayerStateMachine] Off-balance cleared at start of player turn")
		switch_to("locomotion")
	else:
		switch_to("locomotion_slow")


func _on_turn_ended(is_player_turn: bool) -> void:
	# Check if player was still attacking when player turn ended
	if is_player_turn:
		if current_state and current_state.state_name == "attack":
			pawn.set_active_off_balance(true)
			print("[PlayerStateMachine] Player was attacking at turn end - now OFF BALANCE!")


func _on_combat_ended(player_won: bool) -> void:
	if player_won:
		switch_to("victory")
	else:
		switch_to("defeat")


func get_current_state_name() -> String:
	if current_state:
		return current_state.state_name
	return ""


func receive_attack(damage: int) -> void:
	if current_state and current_state.state_name == "vulnerable":
		group_resources.take_damage_vulnerable(damage)
	else:
		group_resources.take_damage(damage)
	
	if not group_resources.is_guarding:
		switch_to("receive_attack")
