extends PlayerState

## Fallback duration if animation is missing
@export var fallback_duration: float = 0.6

var animation_finished: bool = false
var hit_animation: String = "HitReact"


func on_enter() -> void:
	super.on_enter()
	animation_finished = false
	
	if animator:
		# Connect to animation_finished signal
		if not animator.animation_finished.is_connected(_on_animation_finished):
			animator.animation_finished.connect(_on_animation_finished)
		animator.play(hit_animation)
	
	# Stop movement
	pawn.velocity = Vector3.ZERO


func on_exit() -> void:
	super.on_exit()
	# Disconnect signal to avoid issues when re-entering
	if animator and animator.animation_finished.is_connected(_on_animation_finished):
		animator.animation_finished.disconnect(_on_animation_finished)


func update(_delta: float) -> void:
	pawn.velocity = Vector3.ZERO
	pawn.move_and_slide()


func _on_animation_finished(anim_name: StringName) -> void:
	if anim_name == hit_animation:
		animation_finished = true


func check_transition(_delta: float) -> Array:
	# Primary: animation finished
	if animation_finished:
		return [true, _get_appropriate_locomotion_state()]
	
	# Fallback: timer (in case animation is missing or looping)
	if fallback_duration > 0 and duration_longer_than(fallback_duration):
		print("[ReceiveAttack] WARNING: Using fallback duration")
		return [true, _get_appropriate_locomotion_state()]
	
	return [false, ""]


func _get_appropriate_locomotion_state() -> String:
	# Check which turn it is via combat manager
	var combat_manager: Node = pawn.get_tree().get_first_node_in_group("combat_manager")
	if combat_manager and combat_manager.has_method("is_player_turn"):
		if combat_manager.is_player_turn():
			return "locomotion"  # Full speed during player turn
		else:
			return "locomotion_slow"  # Half speed during enemy turn
	
	# Default to slow if we can't determine turn
	return "locomotion_slow"
