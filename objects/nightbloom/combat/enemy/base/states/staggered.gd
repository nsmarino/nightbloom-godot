extends AIState

## State for when enemy is staggered (stunned)
## Cannot move or attack for the duration


func on_enter() -> void:
	super.on_enter()
	print("[Staggered] === ENEMY %s STAGGERED ===" % character.name)
	
	# Play idle animation (placeholder until we have a staggered animation)
	if animator and enemy_data:
		animator.play(enemy_data.anim_idle)
	
	# Notify enemy manager this enemy can't attack
	if enemy_manager and enemy_manager.has_method("on_enemy_staggered"):
		enemy_manager.on_enemy_staggered(character)


func on_exit() -> void:
	super.on_exit()
	print("[Staggered] === ENEMY %s RECOVERED FROM STAGGER ===" % character.name)


func update(_delta: float) -> void:
	# Stay still during stagger (but still participate in avoidance)
	stop_with_avoidance()


func check_transition(_delta: float) -> Array:
	# Check if stagger has ended via the stagger component
	if character.stagger_component and not character.stagger_component.is_staggered:
		# Stagger ended, return to appropriate state based on combat phase
		var combat_manager: Node = character.get_tree().get_first_node_in_group("combat_manager")
		if combat_manager:
			if combat_manager.is_player_turn():
				return [true, "locomotion_slow"]
			else:
				return [true, "idle"]
		return [true, "idle"]
	
	return [false, ""]
