extends PlayerState


func on_enter() -> void:
	super.on_enter()
	if animator:
		animator.play("Idle")


func update(_delta: float) -> void:
	# Stay still during idle
	pawn.velocity = Vector3.ZERO
	pawn.move_and_slide()


func check_transition(_delta: float) -> Array:
	# Idle state transitions are handled externally by state machine
	# when turn_started signal is received
	return [false, ""]
