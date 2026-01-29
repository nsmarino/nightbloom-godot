extends AIState

## Fallback duration if we can't reach orbit position
@export var fallback_duration: float = 3.0
## Distance threshold to consider "arrived at orbit"
@export var arrival_threshold: float = 1.0

var reached_orbit: bool = false


func on_enter() -> void:
	super.on_enter()
	print("[Evade] === ENTERING EVADE STATE ===")
	reached_orbit = false
	
	if animator and enemy_data:
		print("[Evade] Playing animation: %s" % enemy_data.anim_locomotion)
		animator.play(enemy_data.anim_locomotion)
	
	# Log target orbit position
	var orbit_pos: Vector3 = character.get_orbit_position()
	print("[Evade] Returning to orbit position: %s (current: %s)" % [orbit_pos, character.global_position])


func on_exit() -> void:
	super.on_exit()
	print("[Evade] === EXITING EVADE STATE ===")


func update(delta: float) -> void:
	if reached_orbit:
		# Already at orbit, just wait
		stop_with_avoidance()
		face_player(delta)
		return
	
	# Get target orbit position from shared data on character
	var orbit_pos: Vector3 = character.get_orbit_position()
	var current_pos: Vector3 = character.global_position
	
	# Check if we've reached the orbit position
	var distance_to_orbit: float = Vector3(current_pos.x, 0, current_pos.z).distance_to(
		Vector3(orbit_pos.x, 0, orbit_pos.z)
	)
	
	if distance_to_orbit <= arrival_threshold:
		reached_orbit = true
		print("[Evade] Reached orbit position")
		stop_with_avoidance()
		face_player(delta)
		return
	
	# Move toward orbit position
	var speed: float = enemy_data.speed if enemy_data else 3.0
	var desired_velocity := _calculate_return_velocity(orbit_pos, speed)
	move_with_avoidance(desired_velocity)
	
	# Face movement direction while returning
	if desired_velocity.length() > 0.1:
		var target_rotation: float = atan2(desired_velocity.x, desired_velocity.z)
		character.rotation.y = lerp_angle(character.rotation.y, target_rotation, delta * 10.0)


func check_transition(_delta: float) -> Array:
	# Complete when we've reached orbit
	if reached_orbit:
		print("[Evade] Evade complete (reached orbit) - signaling and transitioning to IDLE")
		character.notify_attack_cycle_complete()
		return [true, "idle"]
	
	# Fallback: timer (in case we can't reach orbit)
	if fallback_duration > 0 and duration_longer_than(fallback_duration):
		print("[Evade] Evade complete (fallback timeout) - signaling and transitioning to IDLE")
		character.notify_attack_cycle_complete()
		return [true, "idle"]
	
	return [false, ""]


# Calculate desired velocity toward orbit position
func _calculate_return_velocity(target: Vector3, speed: float) -> Vector3:
	var ground_target: Vector3 = Vector3(target.x, character.global_position.y, target.z)
	var current_pos: Vector3 = character.global_position
	
	var direct_distance: float = current_pos.distance_to(ground_target)
	if direct_distance < 0.5:
		return Vector3.ZERO
	
	var direction: Vector3
	var use_direct_movement: bool = false
	
	# Try navigation if we have an agent
	if nav_agent:
		nav_agent.target_position = ground_target
		
		if nav_agent.is_target_reachable() and not nav_agent.is_navigation_finished():
			var next_pos: Vector3 = nav_agent.get_next_path_position()
			direction = (next_pos - current_pos)
			direction.y = 0
			
			if direction.length() < 0.1:
				use_direct_movement = true
			else:
				direction = direction.normalized()
		else:
			use_direct_movement = true
	else:
		use_direct_movement = true
	
	if use_direct_movement:
		direction = (ground_target - current_pos)
		direction.y = 0
		if direction.length() > 0.1:
			direction = direction.normalized()
		else:
			return Vector3.ZERO
	
	return direction * speed
