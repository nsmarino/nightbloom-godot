extends CanvasLayer
class_name CombatHud

@onready var player_health_bar: ProgressBar = $PlayerResourcesLeft/PlayerHealth
@onready var player_mana_bar: ProgressBar = $PlayerResourcesLeft/PlayerMana
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
@onready var off_balance_label: Label = $OffBalanceLabel
@onready var party_members_container: HBoxContainer = $PartyMembers
@onready var party_select_menu: PanelContainer = $PartySelectMenu
@onready var spell_select_menu: PanelContainer = $SpellSelectMenu
@onready var enemy_select_menu: PanelContainer = $EnemySelectMenu

# AP segment references
var ap_segments: Array[ProgressBar] = []

# Party portrait references
var portrait_panels: Array[PanelContainer] = []
var portrait_stagger_bars: Array[ProgressBar] = []
var portrait_textures: Array[TextureRect] = []
var portrait_names: Array[Label] = []

# StyleBoxes for portrait active state
var portrait_active_style: StyleBox
var portrait_inactive_style: StyleBox

# Menu state
enum MenuState { MAIN, PARTY_SELECT, SPELL_SELECT, ENEMY_SELECT }
var menu_open: bool = false
var menu_index: int = 0
var menu_buttons: Array[Button] = []
var current_menu_state: MenuState = MenuState.MAIN

# Party select submenu
var party_select_buttons: Array[Button] = []
var party_select_index: int = 0

# Spell select submenu
var spell_select_buttons: Array[Button] = []
var spell_select_index: int = 0
var available_spells: Array = []

# Enemy select submenu
var enemy_select_buttons: Array[Button] = []
var enemy_select_index: int = 0
var available_enemies: Array = []
var pending_spell: SpellData  # The spell waiting to be cast on a target

# Camera reference for enemy targeting
var camera: Camera3D

# Reference to player state machine for menu actions
var player_state_machine: Node

# Reference to pawn for party member data
var pawn: Node

# Animation state
var transition_tween: Tween = null
var turn_intro_duration: float = 2.0  # Will be set from combat manager


func _ready() -> void:
	# Connect to Events signals
	Events.player_hp_changed.connect(_on_player_hp_changed)
	Events.player_mp_changed.connect(_on_player_mp_changed)
	Events.player_ap_changed.connect(_on_player_ap_changed)
	Events.enemy_hp_changed.connect(_on_enemy_hp_changed)
	Events.turn_timer_updated.connect(_on_turn_timer_updated)
	Events.combat_paused.connect(_on_combat_paused)
	Events.combat_ended.connect(_on_combat_ended)
	Events.turn_intro_started.connect(_on_turn_intro_started)
	Events.turn_started.connect(_on_turn_started)
	Events.player_off_balance_changed.connect(_on_player_off_balance_changed)
	Events.player_stagger_changed.connect(_on_player_stagger_changed)
	Events.active_party_member_changed.connect(_on_active_party_member_changed)
	
	# Collect AP segment bars
	if ap_container:
		for child in ap_container.get_children():
			if child is ProgressBar:
				ap_segments.append(child)
	
	# Collect portrait references
	_collect_portrait_references()
	
	# Set up menu buttons
	menu_buttons = [spell_button, item_button, switch_button]
	
	# Connect button signals
	if spell_button:
		spell_button.pressed.connect(_on_spell_selected)
	if item_button:
		item_button.pressed.connect(_on_item_selected)
	if switch_button:
		switch_button.pressed.connect(_open_party_select_menu)
	
	# Collect party select buttons
	if party_select_menu:
		for i in range(4):
			var button: Button = party_select_menu.get_node_or_null("VBoxContainer/Member%dButton" % i)
			if button:
				party_select_buttons.append(button)
				var member_index: int = i
				button.pressed.connect(func(): _on_party_member_selected(member_index))
	
	# Collect spell select buttons
	if spell_select_menu:
		for i in range(4):
			var button: Button = spell_select_menu.get_node_or_null("VBoxContainer/Spell%dButton" % i)
			if button:
				spell_select_buttons.append(button)
				var spell_index: int = i
				button.pressed.connect(func(): _on_spell_selected_from_menu(spell_index))
	
	# Collect enemy select buttons
	if enemy_select_menu:
		for i in range(4):
			var button: Button = enemy_select_menu.get_node_or_null("VBoxContainer/Enemy%dButton" % i)
			if button:
				enemy_select_buttons.append(button)
				var enemy_index: int = i
				button.pressed.connect(func(): _on_enemy_selected_from_menu(enemy_index))
	
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
		match current_menu_state:
			MenuState.MAIN:
				_handle_menu_input()
			MenuState.PARTY_SELECT:
				_handle_party_select_input()
			MenuState.SPELL_SELECT:
				_handle_spell_select_input()
			MenuState.ENEMY_SELECT:
				_handle_enemy_select_input()


func _on_player_hp_changed(current: int, max_val: int) -> void:
	if player_health_bar:
		player_health_bar.max_value = max_val
		player_health_bar.value = current


func _on_player_mp_changed(current: int, max_val: int) -> void:
	if player_mana_bar:
		player_mana_bar.max_value = max_val
		player_mana_bar.value = current


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
	
	if paused:
		# Reset to main menu state
		current_menu_state = MenuState.MAIN
		menu_index = 0
		if decide_menu:
			decide_menu.visible = true
		if party_select_menu:
			party_select_menu.visible = false
		if spell_select_menu:
			spell_select_menu.visible = false
		if enemy_select_menu:
			enemy_select_menu.visible = false
		_update_menu_highlight()
	else:
		# Hide all menus
		if decide_menu:
			decide_menu.visible = false
		if party_select_menu:
			party_select_menu.visible = false
		if spell_select_menu:
			spell_select_menu.visible = false
		if enemy_select_menu:
			enemy_select_menu.visible = false


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
			_open_party_select_menu()


func _on_spell_selected() -> void:
	if not player_state_machine or not pawn:
		return
	
	# Check if player can afford spell (just AP check here - MP is checked per spell)
	var decide_state: Variant = player_state_machine.states.get("decide_menu")
	if not decide_state or not decide_state.has_method("select_spell"):
		return
	
	if not decide_state.select_spell():
		return
	
	# Open spell select submenu
	_open_spell_select_menu()


func _on_item_selected() -> void:
	if player_state_machine:
		var decide_state: Variant = player_state_machine.states.get("decide_menu")
		if decide_state and decide_state.has_method("select_item"):
			if decide_state.select_item():
				player_state_machine.switch_to("item")


func _open_party_select_menu() -> void:
	if not player_state_machine:
		return
	
	var decide_state: Variant = player_state_machine.states.get("decide_menu")
	if not decide_state or not decide_state.has_method("select_party_switch"):
		return
	
	# Check if we can afford it
	if not decide_state.select_party_switch():
		return
	
	# Switch to party select submenu
	current_menu_state = MenuState.PARTY_SELECT
	party_select_index = 0
	
	if decide_menu:
		decide_menu.visible = false
	if party_select_menu:
		party_select_menu.visible = true
		_update_party_select_buttons()
		_update_party_select_highlight()


func _handle_party_select_input() -> void:
	if Input.is_action_just_pressed("MenuUp"):
		party_select_index = max(0, party_select_index - 1)
		_update_party_select_highlight()
	
	if Input.is_action_just_pressed("MenuDown"):
		party_select_index = min(party_select_buttons.size() - 1, party_select_index + 1)
		_update_party_select_highlight()
	
	if Input.is_action_just_pressed("MenuConfirm"):
		_on_party_member_selected(party_select_index)
	
	if Input.is_action_just_pressed("MenuCancel"):
		_return_to_main_menu()


func _return_to_main_menu() -> void:
	current_menu_state = MenuState.MAIN
	if decide_menu:
		decide_menu.visible = true
	if party_select_menu:
		party_select_menu.visible = false
	_update_menu_highlight()


func _update_party_select_buttons() -> void:
	# Update button text with party member names and status
	if not pawn or not pawn.PartyMembers:
		return
	
	for i in range(min(4, pawn.PartyMembers.size())):
		if i < party_select_buttons.size() and party_select_buttons[i]:
			var member_data: PartyMemberData = pawn.PartyMembers[i]
			var button_text: String = str(member_data.display_name)
			
			# Add indicator for active member
			if i == pawn.active_member_index:
				button_text += " [ACTIVE]"
			
			# Add indicator for staggered member
			if pawn.is_member_staggered(i):
				button_text += " [STAGGERED]"
			
			party_select_buttons[i].text = button_text
			# Disable button for active member
			party_select_buttons[i].disabled = (i == pawn.active_member_index)


func _update_party_select_highlight() -> void:
	for i in range(party_select_buttons.size()):
		if i == party_select_index:
			party_select_buttons[i].grab_focus()


func _on_party_member_selected(member_index: int) -> void:
	if not player_state_machine or not pawn:
		return
	
	# Don't switch to same member
	if member_index == pawn.active_member_index:
		return
	
	# Attempt to switch
	if pawn.switch_party_member(member_index):
		# Close menu after successful switch
		player_state_machine.switch_to("locomotion")
	else:
		# Switch failed (not enough AP), return to main menu
		_return_to_main_menu()


# Spell select menu functions
func _open_spell_select_menu() -> void:
	# Get spells from active party member
	if not pawn:
		return
	
	var active_member: PartyMemberData = pawn.get_active_member()
	if not active_member:
		return
	
	available_spells = active_member.spells.duplicate()
	
	if available_spells.is_empty():
		print("[CombatHud] No spells available for this party member")
		return
	
	# Switch to spell select submenu
	current_menu_state = MenuState.SPELL_SELECT
	spell_select_index = 0
	
	if decide_menu:
		decide_menu.visible = false
	if spell_select_menu:
		spell_select_menu.visible = true
		_update_spell_select_buttons()
		_update_spell_select_highlight()


func _handle_spell_select_input() -> void:
	if Input.is_action_just_pressed("MenuUp"):
		spell_select_index = max(0, spell_select_index - 1)
		_update_spell_select_highlight()
	
	if Input.is_action_just_pressed("MenuDown"):
		var max_index: int = min(spell_select_buttons.size(), available_spells.size()) - 1
		spell_select_index = min(max_index, spell_select_index + 1)
		_update_spell_select_highlight()
	
	if Input.is_action_just_pressed("MenuConfirm"):
		_on_spell_selected_from_menu(spell_select_index)
	
	if Input.is_action_just_pressed("MenuCancel"):
		_return_to_main_menu()


func _update_spell_select_buttons() -> void:
	if not pawn or not pawn.group_resources:
		return
	
	for i in range(spell_select_buttons.size()):
		if i < available_spells.size():
			var spell: SpellData = available_spells[i]
			var button_text: String = "%s (%d MP)" % [spell.name, spell.mp_cost]
			
			# Check if can afford
			var can_afford: bool = pawn.group_resources.can_afford_mp(spell.mp_cost)
			spell_select_buttons[i].text = button_text
			spell_select_buttons[i].disabled = not can_afford
			spell_select_buttons[i].visible = true
		else:
			spell_select_buttons[i].visible = false


func _update_spell_select_highlight() -> void:
	for i in range(spell_select_buttons.size()):
		if i == spell_select_index and i < available_spells.size():
			spell_select_buttons[i].grab_focus()


func _on_spell_selected_from_menu(spell_index: int) -> void:
	if spell_index >= available_spells.size():
		return
	
	var selected_spell: SpellData = available_spells[spell_index]
	
	# Check if can afford MP
	if not pawn.group_resources.can_afford_mp(selected_spell.mp_cost):
		return
	
	# Store the pending spell and open enemy select menu
	pending_spell = selected_spell
	_open_enemy_select_menu()


func set_player_state_machine(sm: Node) -> void:
	player_state_machine = sm


# Enemy select menu functions
func _open_enemy_select_menu() -> void:
	# Get enemies from enemy group
	if not pawn:
		return
	
	var enemy_group: Node = pawn.enemy_group
	if not enemy_group or not enemy_group.active_enemies:
		print("[CombatHud] No enemy group or active enemies!")
		return
	
	available_enemies = enemy_group.active_enemies.duplicate()
	
	if available_enemies.is_empty():
		print("[CombatHud] No enemies available to target!")
		return
	
	# Get camera reference from pawn
	camera = pawn.get_node_or_null("FollowCamera")
	
	# Switch to enemy select submenu
	current_menu_state = MenuState.ENEMY_SELECT
	enemy_select_index = 0
	
	if spell_select_menu:
		spell_select_menu.visible = false
	if enemy_select_menu:
		enemy_select_menu.visible = true
		_update_enemy_select_buttons()
		_update_enemy_select_highlight()
		_update_camera_to_enemy()


func _handle_enemy_select_input() -> void:
	if Input.is_action_just_pressed("MenuUp"):
		enemy_select_index = max(0, enemy_select_index - 1)
		_update_enemy_select_highlight()
		_update_camera_to_enemy()
	
	if Input.is_action_just_pressed("MenuDown"):
		var max_index: int = min(enemy_select_buttons.size(), available_enemies.size()) - 1
		enemy_select_index = min(max_index, enemy_select_index + 1)
		_update_enemy_select_highlight()
		_update_camera_to_enemy()
	
	if Input.is_action_just_pressed("MenuConfirm"):
		_on_enemy_selected_from_menu(enemy_select_index)
	
	if Input.is_action_just_pressed("MenuCancel"):
		_return_to_spell_select_menu()


func _return_to_spell_select_menu() -> void:
	current_menu_state = MenuState.SPELL_SELECT
	pending_spell = null
	if enemy_select_menu:
		enemy_select_menu.visible = false
	if spell_select_menu:
		spell_select_menu.visible = true
	_update_spell_select_highlight()
	
	# Clear camera override
	if camera and camera.has_method("clear_target_override"):
		camera.clear_target_override()


func _update_enemy_select_buttons() -> void:
	for i in range(enemy_select_buttons.size()):
		if i < available_enemies.size():
			var enemy: Node = available_enemies[i]
			var enemy_name: String = "Enemy"
			
			# Try to get display name from enemy data
			if enemy.has_method("get_display_name"):
				enemy_name = enemy.get_display_name()
			elif "enemy_data" in enemy and enemy.enemy_data:
				enemy_name = enemy.enemy_data.display_name
			else:
				enemy_name = enemy.name
			
			# Check if this enemy can be pressured by the pending spell
			var pressure_indicator: String = ""
			if pending_spell and "enemy_data" in enemy and enemy.enemy_data:
				if enemy.enemy_data.spell_weakness_type == pending_spell.spell_type:
					pressure_indicator = " [color=red]P[/color]"
					# Since buttons don't support BBCode, use plain text
					pressure_indicator = " (P)"
			
			enemy_select_buttons[i].text = enemy_name + pressure_indicator
			enemy_select_buttons[i].disabled = false
			enemy_select_buttons[i].visible = true
		else:
			enemy_select_buttons[i].visible = false


func _update_enemy_select_highlight() -> void:
	for i in range(enemy_select_buttons.size()):
		if i == enemy_select_index and i < available_enemies.size():
			enemy_select_buttons[i].grab_focus()


func _update_camera_to_enemy() -> void:
	if available_enemies.is_empty():
		return
	
	if enemy_select_index >= available_enemies.size():
		return
	
	var target_enemy: Node = available_enemies[enemy_select_index]
	
	if camera and camera.has_method("set_target_override"):
		camera.set_target_override(target_enemy)


func _on_enemy_selected_from_menu(enemy_index: int) -> void:
	if enemy_index >= available_enemies.size():
		return
	
	if not pending_spell:
		print("[CombatHud] No pending spell to cast!")
		return
	
	var target_enemy: Node = available_enemies[enemy_index]
	
	# Get reference to spell state and set its target
	var spell_state: Node = player_state_machine.states.get("spell")
	if spell_state:
		spell_state.set_target(target_enemy)
		spell_state.set_spell_data(pending_spell)
	
	# Spend MP and AP for the spell
	pawn.group_resources.spend_mp(pending_spell.mp_cost)
	pawn.group_resources.spend_ap(GroupResources.SPELL_COST)
	
	print("[CombatHud] Casting %s on %s" % [pending_spell.name, target_enemy.name])
	
	# Clear camera override
	if camera and camera.has_method("clear_target_override"):
		camera.clear_target_override()
	
	# Clear pending spell and transition to spell state
	pending_spell = null
	player_state_machine.switch_to("spell")


func _on_player_off_balance_changed(is_off_balance: bool) -> void:
	if off_balance_label:
		off_balance_label.visible = is_off_balance


func _collect_portrait_references() -> void:
	if not party_members_container:
		return
	
	# Get the StyleBoxes from the first portrait (active) and second (inactive)
	var portrait0: PanelContainer = party_members_container.get_node_or_null("Portrait0")
	var portrait1: PanelContainer = party_members_container.get_node_or_null("Portrait1")
	
	if portrait0:
		portrait_active_style = portrait0.get_theme_stylebox("panel")
	if portrait1:
		portrait_inactive_style = portrait1.get_theme_stylebox("panel")
	
	# Collect all portrait references
	for i in range(4):
		var panel_path: String = "Portrait%d" % i
		var panel: PanelContainer = party_members_container.get_node_or_null(panel_path)
		
		if panel:
			portrait_panels.append(panel)
			
			var stagger_bar: ProgressBar = panel.get_node_or_null("VBox/StaggerBar")
			var portrait_tex: TextureRect = panel.get_node_or_null("VBox/Portrait")
			var name_label: Label = panel.get_node_or_null("VBox/NameLabel")
			
			portrait_stagger_bars.append(stagger_bar)
			portrait_textures.append(portrait_tex)
			portrait_names.append(name_label)


func initialize_party_portraits(party_pawn: Node) -> void:
	pawn = party_pawn
	
	if not pawn or not pawn.PartyMembers:
		return
	
	for i in range(min(4, pawn.PartyMembers.size())):
		var member_data: PartyMemberData = pawn.PartyMembers[i]
		
		if i < portrait_textures.size() and portrait_textures[i]:
			if member_data.character_portrait:
				portrait_textures[i].texture = member_data.character_portrait
		
		if i < portrait_names.size() and portrait_names[i]:
			portrait_names[i].text = str(member_data.display_name)
		
		if i < portrait_stagger_bars.size() and portrait_stagger_bars[i]:
			portrait_stagger_bars[i].value = 0.0
	
	# Set initial active state
	_update_portrait_active_state(pawn.active_member_index)


func _update_portrait_active_state(active_index: int) -> void:
	for i in range(portrait_panels.size()):
		if portrait_panels[i]:
			if i == active_index:
				portrait_panels[i].add_theme_stylebox_override("panel", portrait_active_style)
			else:
				portrait_panels[i].add_theme_stylebox_override("panel", portrait_inactive_style)


func _on_player_stagger_changed(member_index: int, current: float, max_val: float) -> void:
	if member_index < portrait_stagger_bars.size() and portrait_stagger_bars[member_index]:
		portrait_stagger_bars[member_index].max_value = max_val
		portrait_stagger_bars[member_index].value = current


func _on_active_party_member_changed(member_index: int) -> void:
	_update_portrait_active_state(member_index)
