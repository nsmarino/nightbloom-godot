extends PlayerState


func on_enter() -> void:
	super.on_enter()
	
	if animator:
		animator.play("HitReact")  # Placeholder for defeat animation
	
	pawn.velocity = Vector3.ZERO


func update(_delta: float) -> void:
	pawn.velocity = Vector3.ZERO
	pawn.move_and_slide()


func check_transition(_delta: float) -> Array:
	# Defeat is a terminal state
	return [false, ""]
