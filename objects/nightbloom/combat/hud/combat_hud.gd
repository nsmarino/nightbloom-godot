extends CanvasLayer
class_name CombatHud

@onready var player_health_bar: ProgressBar = $PlayerResourcesLeft/PlayerHealth
@onready var enemy_health_bar: ProgressBar = $EnemyResources/EnemyHealth
@onready var turn_bar: ProgressBar = $TurnBar
@onready var ap_container: HBoxContainer = $APContainer
@onready var decide_menu: PanelContainer = $DecideMenu
@onready var turn_indicator: Label = $TurnIndicator

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


func _ready() -> void:
	# Connect to Events signals
	Events.player_hp_changed.connect(_on_player_hp_changed)
	Events.player_ap_changed.connect(_on_player_ap_changed)
	Events.enemy_hp_changed.connect(_on_enemy_hp_changed)
	Events.turn_timer_updated.connect(_on_turn_timer_updated)
	Events.combat_paused.connect(_on_combat_paused)
	Events.combat_ended.connect(_on_combat_ended)
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


func _on_turn_started(is_player_turn: bool) -> void:
	if turn_indicator:
		turn_indicator.text = "PLAYER TURN" if is_player_turn else "ENEMY TURN"


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
	
	if turn_indicator:
		turn_indicator.text = "VICTORY!" if player_won else "DEFEAT..."


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
