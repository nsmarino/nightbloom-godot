extends Node
class_name AIState

@export var state_name: String
@export var animation: String

var player: CharacterBody3D
var character: CharacterBody3D
var animator: AnimationPlayer
var spawn_point: Vector3
var nav_agent: NavigationAgent3D
var attack_area: Area3D
var enemy_data: EnemyData
var enemy_manager: Node

var enter_state_time: float


func check_transition(_delta: float) -> Array:
	return [false, ""]


func update(_delta: float) -> void:
	pass
 

func on_enter() -> void:
	Events.enemy_state_changed.emit(character, state_name)


func on_exit() -> void:
	pass


# Timestamps framework for timing logic
func mark_enter_state() -> void:
	enter_state_time = Time.get_unix_time_from_system()


func get_progress() -> float:
	var now: float = Time.get_unix_time_from_system()
	return now - enter_state_time


func duration_longer_than(time: float) -> bool:
	return get_progress() >= time


func duration_less_than(time: float) -> bool:
	return get_progress() < time


func duration_between(start: float, finish: float) -> bool:
	var progress: float = get_progress()
	return progress >= start and progress <= finish


# Helper: get distance to player
func get_distance_to_player() -> float:
	if player:
		return character.global_position.distance_to(player.global_position)
	return 999.0


# Helper: move toward target position using navigation
func navigate_to(target: Vector3, speed: float, delta: float) -> void:
	# Project target to ground level (navmesh is typically at Y=0)
	var ground_target: Vector3 = Vector3(target.x, character.global_position.y, target.z)
	var current_pos: Vector3 = character.global_position
	
	# Check if we're already close enough
	var direct_distance: float = current_pos.distance_to(ground_target)
	if direct_distance < 0.5:
		character.velocity = Vector3.ZERO
		character.move_and_slide()
		return
	
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
				# Waypoint too close, use direct movement
				use_direct_movement = true
			else:
				direction = direction.normalized()
				
				# Debug output every ~0.5 seconds
				if Engine.get_physics_frames() % 30 == 0:
					print("[AIState:%s] NAV: pos=%s -> waypoint=%s, target=%s" % [
						state_name, current_pos, next_pos, ground_target
					])
		else:
			use_direct_movement = true
			if Engine.get_physics_frames() % 30 == 0:
				print("[AIState:%s] Nav unavailable, using direct movement. Reachable=%s, Finished=%s" % [
					state_name, nav_agent.is_target_reachable(), nav_agent.is_navigation_finished()
				])
	else:
		use_direct_movement = true
	
	# Fallback: direct movement toward target
	if use_direct_movement:
		direction = (ground_target - current_pos)
		direction.y = 0
		if direction.length() > 0.1:
			direction = direction.normalized()
		else:
			character.velocity = Vector3.ZERO
			character.move_and_slide()
			return
		
		if Engine.get_physics_frames() % 30 == 0:
			print("[AIState:%s] DIRECT: pos=%s -> target=%s, dist=%.2f" % [
				state_name, current_pos, ground_target, direct_distance
			])
	
	# Apply velocity
	character.velocity = direction * speed
	
	# Rotate to face movement direction
	var target_rotation: float = atan2(direction.x, direction.z)
	character.rotation.y = lerp_angle(character.rotation.y, target_rotation, delta * 10.0)
	
	# Move
	character.move_and_slide()


# Helper: move away from target position
func move_away_from(target: Vector3, speed: float, delta: float) -> void:
	var direction: Vector3 = (character.global_position - target).normalized()
	direction.y = 0
	
	var evade_target: Vector3 = character.global_position + direction * 5.0
	navigate_to(evade_target, speed, delta)


# Helper: face the player
func face_player(delta: float) -> void:
	if player:
		var direction: Vector3 = (player.global_position - character.global_position).normalized()
		direction.y = 0
		if direction.length() > 0.1:
			var target_rotation: float = atan2(direction.x, direction.z)
			character.rotation.y = lerp_angle(character.rotation.y, target_rotation, delta * 10.0)
