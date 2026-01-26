extends AIState

@export var stagger_duration: float = 0.5


func on_enter() -> void:
	super.on_enter()
	if animator and enemy_data:
		animator.play(enemy_data.anim_receive_hit)


func update(_delta: float) -> void:
	# Stop movement while staggered
	character.velocity = Vector3.ZERO
	character.move_and_slide()


func check_transition(_delta: float) -> Array:
	if duration_longer_than(stagger_duration):
		# Return to locomotion_slow during player turn
		return [true, "locomotion_slow"]
	
	return [false, ""]
