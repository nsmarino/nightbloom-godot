extends AIState

@export var death_timer: float = 2.0


func on_enter() -> void:
	super.on_enter()
	if animator and enemy_data:
		animator.play(enemy_data.anim_receive_hit)  # Placeholder for death animation
	
	# Notify enemy manager
	if enemy_manager and enemy_manager.has_method("on_enemy_died"):
		enemy_manager.on_enemy_died(character)


func update(_delta: float) -> void:
	# Stay still
	character.velocity = Vector3.ZERO
	character.move_and_slide()


func check_transition(_delta: float) -> Array:
	if duration_longer_than(death_timer):
		character.queue_free()
	return [false, ""]
