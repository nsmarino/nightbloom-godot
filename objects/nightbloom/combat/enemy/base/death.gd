extends AIState


@export var death_timer : float = 3


func on_enter() -> void:
	pass
	

func check_transition(delta) -> Array:
	if duration_longer_than(death_timer):
		character.queue_free()
	return [false, ""]
