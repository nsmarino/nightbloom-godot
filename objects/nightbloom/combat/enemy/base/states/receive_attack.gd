extends AIState

## Fallback duration if animation is missing (set to 0 to require animation)
@export var fallback_duration: float = 0.5

var animation_finished: bool = false
var hit_animation: String = ""


func on_enter() -> void:
	super.on_enter()
	animation_finished = false
	
	if animator and enemy_data:
		hit_animation = enemy_data.anim_receive_hit
		# Connect to animation_finished signal
		if not animator.animation_finished.is_connected(_on_animation_finished):
			animator.animation_finished.connect(_on_animation_finished)
		animator.play(hit_animation)


func on_exit() -> void:
	super.on_exit()
	# Disconnect signal to avoid issues when re-entering
	if animator and animator.animation_finished.is_connected(_on_animation_finished):
		animator.animation_finished.disconnect(_on_animation_finished)


func update(_delta: float) -> void:
	# Stop movement while staggered (but participate in avoidance)
	stop_with_avoidance()


func _on_animation_finished(anim_name: StringName) -> void:
	if anim_name == hit_animation:
		animation_finished = true


func check_transition(_delta: float) -> Array:
	# Primary: animation finished
	if animation_finished:
		return [true, "locomotion_slow"]
	
	# Fallback: timer (in case animation is missing or looping)
	if fallback_duration > 0 and duration_longer_than(fallback_duration):
		print("[ReceiveAttack] WARNING: Using fallback duration, animation may not have finished signal")
		return [true, "locomotion_slow"]
	
	return [false, ""]
