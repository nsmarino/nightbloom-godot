extends PlayerState

# Vulnerable state: player was mid-attack when enemy turn started
# Cannot move and takes increased damage


func on_enter() -> void:
	super.on_enter()
	
	if animator:
		animator.play("Idle")  # Placeholder for staggered/exhausted pose
	
	# Stop movement
	pawn.velocity = Vector3.ZERO


func update(_delta: float) -> void:
	pawn.velocity = Vector3.ZERO
	pawn.move_and_slide()


func check_transition(_delta: float) -> Array:
	# Vulnerable state lasts for entire enemy turn
	# Transitions are handled externally when turn changes
	return [false, ""]


# Called when taking damage in vulnerable state
func take_vulnerable_damage(amount: int) -> void:
	group_resources.take_damage_vulnerable(amount)
