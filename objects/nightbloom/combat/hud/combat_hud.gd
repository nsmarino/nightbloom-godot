extends CanvasLayer
class_name CombatHud

@onready var player_health_bar: ProgressBar = $PlayerResourcesLeft/PlayerHealth
@onready var enemy_health_bar: ProgressBar = $EnemyResources/EnemyHealth
@onready var turn_bar: ProgressBar = $TurnBar
@onready var ap_container: HBoxContainer = $APContainer
@onready var decide_menu: PanelContainer = $DecideMenu

# Turn indicator labels
@onready var turn_indicator_container: Control = $TurnIndicatorContainer
@onready var player_turn_label: Label = $TurnIndicatorContainer/PlayerTurnLabel
@onready var enemy_turn_label: Label = $TurnIndicatorContainer/EnemyTurnLabel
@onready var victory_label: Label = $TurnIndicatorContainer/VictoryLabel
@onready var defeat_label: Label = $TurnIndicatorContainer/DefeatLabel

@onready var spell_button: Button = $DecideMenu/VBoxContainer/SpellButton
@onready var item_button: Button = $DecideMenu/VBoxContainer/ItemButton
@onready var switch_button: Button = $DecideMenu/VBoxContainer/SwitchButton

# AP segment references
var ap_segments: Array[ProgressBar] = []

# Menu state
var menu_open: bool = false
var menu_index: int = 0
var menu_buttons: Array[Button] = []

# Reference to player state machine for menu actions
var player_state_machine: Node

# Animation state
var transition_tween: Tween = null
var turn_intro_duration: float = 2.0  # Will be set from combat manager


func _ready() -> void:
	# Connect to Events signals
	Events.player_hp_changed.connect(_on_player_hp_changed)
	Events.player_ap_changed.connect(_on_player_ap_changed)
	Events.enemy_hp_changed.connect(_on_enemy_hp_changed)
	Events.turn_timer_updated.connect(_on_turn_timer_updated)
	Events.combat_paused.connect(_on_combat_paused)
	Events.combat_ended.connect(_on_combat_ended)
	Events.turn_intro_started.connect(_on_turn_intro_started)
	Events.turn_started.connect(_on_turn_started)
	
	# Collect AP segment bars
	if ap_container:
		for child in ap_container.get_children():
			if child is ProgressBar:
				ap_segments.append(child)
	
	# Set up menu buttons
	menu_buttons = [spell_button, item_button, switch_button]
	
	# Connect button signals
	if spell_button:
		spell_button.pressed.connect(_on_spell_selected)
	if item_button:
		item_button.pressed.connect(_on_item_selected)
	if switch_button:
		switch_button.pressed.connect(_on_party_switch_selected)
	
	# Initially hide decide menu
	if decide_menu:
		decide_menu.visible = false
	
	# Get turn intro duration from combat manager
	await get_tree().process_frame
	var combat_manager: Node = get_tree().get_first_node_in_group("combat_manager")
	if combat_manager and combat_manager.has_method("get_turn_intro_duration"):
		turn_intro_duration = combat_manager.get_turn_intro_duration()
	
	# Initial state - show player turn (combat starts with player turn)
	_set_label_alpha(player_turn_label, 1.0)
	_set_label_alpha(enemy_turn_label, 0.0)


func _process(_delta: float) -> void:
	if menu_open:
		_handle_menu_input()


func _on_player_hp_changed(current: int, max_val: int) -> void:
	if player_health_bar:
		player_health_bar.max_value = max_val
		player_health_bar.value = current


func _on_player_ap_changed(current: int, _max_val: int) -> void:
	# Update AP segments (each segment represents 30 AP)
	var segment_value: int = 30
	for i in range(ap_segments.size()):
		var segment_start: int = i * segment_value
		var segment_end: int = (i + 1) * segment_value
		
		if current >= segment_end:
			ap_segments[i].value = ap_segments[i].max_value
		elif current > segment_start:
			ap_segments[i].value = float(current - segment_start)
		else:
			ap_segments[i].value = 0


func _on_enemy_hp_changed(current: int, max_val: int) -> void:
	if enemy_health_bar:
		enemy_health_bar.max_value = max_val
		enemy_health_bar.value = current


func _on_turn_timer_updated(time_remaining: float, turn_duration: float) -> void:
	if turn_bar:
		turn_bar.max_value = turn_duration
		turn_bar.value = time_remaining


func _on_turn_intro_started(is_player_turn: bool) -> void:
	# Play the transition animation during turn intro
	_play_turn_transition(is_player_turn)


func _on_turn_started(_is_player_turn: bool) -> void:
	# Turn has actually started (after intro) - ensure correct label is shown
	pass


func _on_combat_paused(paused: bool) -> void:
	menu_open = paused
	if decide_menu:
		decide_menu.visible = paused
	
	if paused:
		menu_index = 0
		_update_menu_highlight()


func _on_combat_ended(player_won: bool) -> void:
	if decide_menu:
		decide_menu.visible = false
	menu_open = false
	
	# Kill any running transition
	if transition_tween:
		transition_tween.kill()
	
	# Hide turn labels, show victory/defeat
	_set_label_alpha(player_turn_label, 0.0)
	_set_label_alpha(enemy_turn_label, 0.0)
	
	if player_won:
		victory_label.visible = true
		defeat_label.visible = false
	else:
		victory_label.visible = false
		defeat_label.visible = true


func _play_turn_transition(to_player_turn: bool) -> void:
	# Kill any existing tween
	if transition_tween:
		transition_tween.kill()
	
	# Ensure victory/defeat labels are hidden
	victory_label.visible = false
	defeat_label.visible = false
	
	# Create new tween for transition animation
	transition_tween = create_tween()
	transition_tween.set_parallel(true)
	
	var from_label: Label = enemy_turn_label if to_player_turn else player_turn_label
	var to_label: Label = player_turn_label if to_player_turn else enemy_turn_label
	
	# Animation timing - use full intro duration
	var half_duration: float = turn_intro_duration * 0.4
	var hold_duration: float = turn_intro_duration * 0.2
	
	# Phase 1: Scale up and fade out the old label
	transition_tween.tween_property(from_label, "modulate:a", 0.0, half_duration).set_ease(Tween.EASE_IN)
	transition_tween.tween_property(from_label, "scale", Vector2(1.5, 1.5), half_duration).set_ease(Tween.EASE_IN)
	transition_tween.tween_property(from_label, "position", from_label.position - Vector2(25, 10), half_duration)
	
	# Phase 2: After a moment, scale in and fade in the new label
	to_label.scale = Vector2(0.5, 0.5)
	to_label.position = to_label.position + Vector2(25, 10)
	_set_label_alpha(to_label, 0.0)
	
	transition_tween.tween_property(to_label, "modulate:a", 1.0, half_duration).set_delay(half_duration + hold_duration * 0.5).set_ease(Tween.EASE_OUT)
	transition_tween.tween_property(to_label, "scale", Vector2(1.0, 1.0), half_duration).set_delay(half_duration + hold_duration * 0.5).set_ease(Tween.EASE_OUT)
	transition_tween.tween_property(to_label, "position", Vector2(-100, -20), half_duration).set_delay(half_duration + hold_duration * 0.5)
	
	# Reset old label position for next transition
	transition_tween.tween_callback(func(): 
		from_label.scale = Vector2(1.0, 1.0)
		from_label.position = Vector2(-100, -20)
	).set_delay(turn_intro_duration)


func _set_label_alpha(label: Label, alpha: float) -> void:
	if label:
		label.modulate.a = alpha


func _handle_menu_input() -> void:
	if Input.is_action_just_pressed("MenuUp"):
		menu_index = max(0, menu_index - 1)
		_update_menu_highlight()
	
	if Input.is_action_just_pressed("MenuDown"):
		menu_index = min(menu_buttons.size() - 1, menu_index + 1)
		_update_menu_highlight()
	
	if Input.is_action_just_pressed("MenuConfirm"):
		_select_menu_item(menu_index)


func _update_menu_highlight() -> void:
	# Update visual highlight on menu items
	for i in range(menu_buttons.size()):
		if i == menu_index:
			menu_buttons[i].grab_focus()


func _select_menu_item(index: int) -> void:
	match index:
		0:
			_on_spell_selected()
		1:
			_on_item_selected()
		2:
			_on_party_switch_selected()


func _on_spell_selected() -> void:
	if player_state_machine:
		var decide_state: Variant = player_state_machine.states.get("decide_menu")
		if decide_state and decide_state.has_method("select_spell"):
			if decide_state.select_spell():
				player_state_machine.switch_to("spell")


func _on_item_selected() -> void:
	if player_state_machine:
		var decide_state: Variant = player_state_machine.states.get("decide_menu")
		if decide_state and decide_state.has_method("select_item"):
			if decide_state.select_item():
				player_state_machine.switch_to("item")


func _on_party_switch_selected() -> void:
	if player_state_machine:
		var pawn: Variant = player_state_machine.pawn
		if pawn and pawn.has_method("switch_to_next_party_member"):
			pawn.switch_to_next_party_member()
			# Close menu after switch
			player_state_machine.switch_to("locomotion")


func set_player_state_machine(sm: Node) -> void:
	player_state_machine = sm
