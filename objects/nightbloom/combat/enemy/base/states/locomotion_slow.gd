extends AIState

@export var speed_multiplier: float = 0.5
@export var animation_speed: float = 0.5
@export var base_orbit_radius: float = 5.0  # Base distance from player to orbit at
@export var orbit_radius_variance: float = 1.5  # Random variance (+/- this value)
@export var orbit_speed: float = 0.3  # Radians per second around orbit
@export var resample_interval: float = 5.0  # Base interval to resample player position
@export var resample_variance: float = 1.5  # Random variance for resample timing

var nav_failed: bool = false  # If true, stand still

# Resample timer
var resample_timer: float = 0.0
var next_resample_time: float = 0.0


func on_enter() -> void:
	super.on_enter()
	print("[LocomotionSlow] === ENTERING LOCOMOTION_SLOW STATE ===")
	
	nav_failed = false
	
	if animator and enemy_data:
		animator.play(enemy_data.anim_locomotion)
		animator.speed_scale = animation_speed
	
	# Setup initial orbit (stores data on character for sharing with evade state)
	_setup_orbit()
	
	# Reset resample timer with random offset
	resample_timer = 0.0
	next_resample_time = _get_random_resample_time()


func on_exit() -> void:
	super.on_exit()
	print("[LocomotionSlow] === EXITING LOCOMOTION_SLOW STATE ===")
	if animator:
		animator.speed_scale = 1.0


func update(delta: float) -> void:
	# If navigation failed, stand still and face player
	if nav_failed:
		stop_with_avoidance()
		face_player(delta)
		
		if animator and enemy_data:
			if animator.current_animation != enemy_data.anim_idle:
				animator.play(enemy_data.anim_idle)
		return
	
	# Check if it's time to resample player position
	resample_timer += delta
	if resample_timer >= next_resample_time:
		_resample_orbit()
		resample_timer = 0.0
		next_resample_time = _get_random_resample_time()
	
	# Advance angle along orbit (updates shared data on character)
	character.advance_orbit(delta, orbit_speed)
	
	# Calculate target position on orbit circle
	var target_pos: Vector3 = character.get_orbit_position()
	
	# Move toward orbit position using avoidance
	var speed: float = enemy_data.speed * speed_multiplier if enemy_data else 1.5
	var desired_velocity := _calculate_orbit_velocity(target_pos, speed)
	move_with_avoidance(desired_velocity)
	
	# Always face the player while orbiting
	face_player(delta)

	# Update animation based on movement
	if animator and enemy_data:
		animator.play(enemy_data.anim_locomotion)


func check_transition(_delta: float) -> Array:
	# Locomotion slow transitions are handled externally
	return [false, ""]


# Setup orbit with randomized radius (stores on character for sharing)
func _setup_orbit() -> void:
	if not player:
		nav_failed = true
		print("[LocomotionSlow] No player found, standing still")
		return
	
	# Capture player's position as orbit center
	var center := Vector3(player.global_position.x, 0.0, player.global_position.z)
	
	# Randomize orbit radius within range
	var radius: float = base_orbit_radius + randf_range(-orbit_radius_variance, orbit_radius_variance)
	radius = maxf(radius, 1.0)  # Minimum radius of 1
	
	# Random orbit direction (clockwise or counter-clockwise)
	var direction: float = 1.0 if randf() > 0.5 else -1.0
	
	# Store orbit data on character (BaseEnemy) for sharing with evade state
	character.setup_orbit(center, radius, direction)
	
	print("[LocomotionSlow] Orbiting player at center %s, radius %.1f (base %.1f), direction %s" % [
		center, radius, base_orbit_radius, "CCW" if direction > 0 else "CW"
	])
	
	# Check if we can navigate to our first orbit point
	var first_target: Vector3 = character.get_orbit_position()
	if not _test_nav_reachable(first_target):
		print("[LocomotionSlow] Nav failed for initial orbit point, standing still")
		nav_failed = true


# Resample player position and recalculate orbit
func _resample_orbit() -> void:
	if not player:
		return
	
	# Update orbit center to current player position
	var old_center: Vector3 = character.orbit_center
	var new_center := Vector3(player.global_position.x, 0.0, player.global_position.z)
	
	# Optionally randomize radius again
	var new_radius: float = base_orbit_radius + randf_range(-orbit_radius_variance, orbit_radius_variance)
	new_radius = maxf(new_radius, 1.0)
	character.orbit_radius = new_radius
	
	# 50% chance to switch orbit direction
	var old_direction: float = character.orbit_direction
	if randf() > 0.5:
		character.orbit_direction *= -1.0
	
	# Update center (this also recalculates angle)
	character.update_orbit_center(new_center)
	
	var direction_changed: bool = old_direction != character.orbit_direction
	print("[LocomotionSlow] Resampled orbit: center %s -> %s, radius %.1f%s" % [
		old_center, new_center, new_radius,
		" (direction flipped!)" if direction_changed else ""
	])


# Get random resample time with variance
func _get_random_resample_time() -> float:
	return resample_interval + randf_range(-resample_variance, resample_variance)


# Test if navigation can reach a target
func _test_nav_reachable(target: Vector3) -> bool:
	if not nav_agent:
		return false
	nav_agent.target_position = target
	return nav_agent.is_target_reachable()


# Calculate desired velocity toward orbit position (avoidance will modify this)
func _calculate_orbit_velocity(target: Vector3, speed: float) -> Vector3:
	var ground_target: Vector3 = Vector3(target.x, character.global_position.y, target.z)
	var current_pos: Vector3 = character.global_position
	
	# Check if we're already close enough
	var direct_distance: float = current_pos.distance_to(ground_target)
	if direct_distance < 0.5:
		return Vector3.ZERO
	
	var direction: Vector3
	var use_direct_movement: bool = false
	
	# Try navigation if we have an agent
	if nav_agent:
		nav_agent.target_position = ground_target
		
		# Check if navigation is viable
		if nav_agent.is_target_reachable() and not nav_agent.is_navigation_finished():
			# Use navmesh pathfinding
			var next_pos: Vector3 = nav_agent.get_next_path_position()
			direction = (next_pos - current_pos)
			direction.y = 0
			
			if direction.length() < 0.1:
				use_direct_movement = true
			else:
				direction = direction.normalized()
		else:
			# Nav failed during orbit - stop moving
			return Vector3.ZERO
	else:
		use_direct_movement = true
	
	# Fallback: direct movement toward target
	if use_direct_movement:
		direction = (ground_target - current_pos)
		direction.y = 0
		if direction.length() > 0.1:
			direction = direction.normalized()
		else:
			return Vector3.ZERO
	
	return direction * speed
