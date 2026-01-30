extends PlayerState

## State for selecting a spell target from available enemies

var selected_spell: SpellData
var selected_enemy_index: int = 0
var available_enemies: Array = []
var camera: Camera3D


func on_enter() -> void:
	super.on_enter()
	
	print("[SelectSpellTarget] Entering spell target selection")
	
	# Stop movement
	pawn.velocity = Vector3.ZERO
	
	if animator:
		animator.play("Idle")
	
	# Get list of enemies from enemy group
	# Note: enemy_group IS the EnemyManager (script attached to root node)
	available_enemies.clear()
	if enemy_group and enemy_group.active_enemies:
		available_enemies = enemy_group.active_enemies.duplicate()
	
	if available_enemies.is_empty():
		print("[SelectSpellTarget] No enemies available!")
		return
	
	# Find camera
	camera = pawn.get_node_or_null("FollowCamera")
	
	# Start looking at first enemy
	selected_enemy_index = 0
	_update_camera_target()


func on_exit() -> void:
	super.on_exit()
	
	# Clear camera override
	if camera and camera.has_method("clear_target_override"):
		camera.clear_target_override()
	
	# Resume combat
	Events.combat_paused.emit(false)


func update(_delta: float) -> void:
	# Keep player still
	pawn.velocity = Vector3.ZERO
	pawn.move_and_slide()


func check_transition(_delta: float) -> Array:
	# Navigate enemies with up/down
	if Input.is_action_just_pressed("MenuUp"):
		selected_enemy_index = max(0, selected_enemy_index - 1)
		_update_camera_target()
	
	if Input.is_action_just_pressed("MenuDown"):
		selected_enemy_index = min(available_enemies.size() - 1, selected_enemy_index + 1)
		_update_camera_target()
	
	# Confirm selection
	if Input.is_action_just_pressed("MenuConfirm"):
		if selected_enemy_index < available_enemies.size():
			var target_enemy: Node = available_enemies[selected_enemy_index]
			_cast_spell_on_target(target_enemy)
			return [true, "spell"]
	
	# Cancel - go back to decide menu
	if Input.is_action_just_pressed("MenuCancel"):
		return [true, "decide_menu"]
	
	return [false, ""]


func _update_camera_target() -> void:
	if available_enemies.is_empty():
		return
	
	if selected_enemy_index >= available_enemies.size():
		selected_enemy_index = available_enemies.size() - 1
	
	var target_enemy: Node = available_enemies[selected_enemy_index]
	
	if camera and camera.has_method("set_target_override"):
		camera.set_target_override(target_enemy)
	
	print("[SelectSpellTarget] Targeting: %s" % target_enemy.name)


func _cast_spell_on_target(target_enemy: Node) -> void:
	# Get reference to spell state and set its target
	var spell_state: Node = pawn.state_machine.states.get("spell")
	if spell_state:
		spell_state.set_target(target_enemy)
		spell_state.set_spell_data(selected_spell)
	
	# Spend MP for the spell
	if selected_spell:
		group_resources.spend_mp(selected_spell.mp_cost)
		group_resources.spend_ap(GroupResources.SPELL_COST)
	
	print("[SelectSpellTarget] Casting %s on %s" % [selected_spell.name if selected_spell else "spell", target_enemy.name])


func set_selected_spell(spell: SpellData) -> void:
	selected_spell = spell
