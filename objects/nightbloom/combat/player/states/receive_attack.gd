extends PlayerState

@export var stagger_duration: float = 0.6


func on_enter() -> void:
	super.on_enter()
	
	if animator:
		animator.play("HitReact")
	
	# Stop movement
	pawn.velocity = Vector3.ZERO


func update(_delta: float) -> void:
	pawn.velocity = Vector3.ZERO
	pawn.move_and_slide()


func check_transition(_delta: float) -> Array:
	if duration_longer_than(stagger_duration):
		# Return to appropriate locomotion state based on current turn
		# This is determined by the state machine listening to the combat manager
		return [true, "locomotion_slow"]
	
	return [false, ""]
