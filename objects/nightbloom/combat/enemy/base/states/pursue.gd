extends AIState


func on_enter() -> void:
	super.on_enter()
	print("[Pursue] === ENTERING PURSUE STATE ===")
	print("[Pursue] Character: %s at position %s" % [character.name if character else "NULL", character.global_position if character else "N/A"])
	print("[Pursue] Player: %s at position %s" % [player.name if player else "NULL", player.global_position if player else "N/A"])
	print("[Pursue] NavAgent: %s" % [nav_agent if nav_agent else "NULL"])
	print("[Pursue] EnemyData: %s" % [enemy_data.display_name if enemy_data else "NULL"])
	
	if nav_agent:
		print("[Pursue] NavAgent target_desired_distance: %.2f" % nav_agent.target_desired_distance)
		print("[Pursue] NavAgent path_desired_distance: %.2f" % nav_agent.path_desired_distance)
		print("[Pursue] NavAgent max_speed: %.2f" % nav_agent.max_speed)
	
	if animator and enemy_data:
		print("[Pursue] Playing animation: %s" % enemy_data.anim_locomotion)
		animator.play(enemy_data.anim_locomotion)
	else:
		print("[Pursue] WARNING: Cannot play animation - animator=%s, enemy_data=%s" % [animator != null, enemy_data != null])


func update(delta: float) -> void:
	if not player:
		print("[Pursue] ERROR: No player reference!")
		return
	
	if not character:
		print("[Pursue] ERROR: No character reference!")
		return
	
	var speed: float = enemy_data.speed if enemy_data else 3.0
	var distance: float = get_distance_to_player()
	
	# Log every ~0.5 seconds
	if Engine.get_physics_frames() % 30 == 0:
		print("[Pursue] Distance to player: %.2f, Speed: %.2f" % [distance, speed])
	
	navigate_to(player.global_position, speed, delta)


func check_transition(_delta: float) -> Array:
	var attack_range: float = enemy_data.attack_range if enemy_data else 2.0
	var distance: float = get_distance_to_player()
	
	if distance <= attack_range:
		print("[Pursue] In attack range (%.2f <= %.2f) - transitioning to ATTACK" % [distance, attack_range])
		return [true, "attack"]
	
	return [false, ""]
