extends AIState


func on_enter() -> void:
	super.on_enter()
	print("[Idle] === ENTERING IDLE STATE ===")
	
	if animator and enemy_data:
		print("[Idle] Playing animation: %s" % enemy_data.anim_idle)
		animator.play(enemy_data.anim_idle)
	else:
		print("[Idle] WARNING: Cannot play animation - animator=%s, enemy_data=%s" % [animator != null, enemy_data != null])


func update(_delta: float) -> void:
	# Stay still during idle
	character.velocity = Vector3.ZERO
	character.move_and_slide()


func check_transition(_delta: float) -> Array:
	# Idle state transitions are handled externally by state machine
	# when commanded by EnemyManager
	return [false, ""]
