extends Node
class_name PlayerState

@export var state_name: String

var pawn: CharacterBody3D
var animator: AnimationPlayer
var spawn_point: Vector3
var group_resources: Node
var hit_area: Area3D
var enemy_group: Node

var enter_state_time: float


func check_transition(_delta: float) -> Array:
	return [false, ""]


func update(_delta: float) -> void:
	pass
 

func on_enter() -> void:
	Events.player_state_changed.emit(state_name)


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


# Helper methods for input
func get_movement_input() -> Vector2:
	var input_dir := Vector2.ZERO
	input_dir.x = Input.get_axis("MoveLeft", "MoveRight")
	input_dir.y = Input.get_axis("MoveForward", "MoveBackward")
	return input_dir


func apply_movement(delta: float, speed: float) -> void:
	var input_dir := get_movement_input()
	if input_dir.length() > 0.1:
		# Get camera direction for movement relative to camera
		var camera: Camera3D = pawn.get_viewport().get_camera_3d()
		if camera:
			var cam_basis: Basis = camera.global_transform.basis
			var forward: Vector3 = -cam_basis.z
			forward.y = 0
			forward = forward.normalized()
			var right: Vector3 = cam_basis.x
			right.y = 0
			right = right.normalized()
			
			var direction: Vector3 = (right * input_dir.x + forward * -input_dir.y).normalized()
			pawn.velocity.x = direction.x * speed
			pawn.velocity.z = direction.z * speed
			
			# Rotate to face movement direction
			if direction.length() > 0.1:
				var target_rotation: float = atan2(direction.x, direction.z)
				pawn.rotation.y = lerp_angle(pawn.rotation.y, target_rotation, delta * 10.0)
	else:
		pawn.velocity.x = move_toward(pawn.velocity.x, 0, speed)
		pawn.velocity.z = move_toward(pawn.velocity.z, 0, speed)
	
	pawn.move_and_slide()
