extends PlayerState


func on_enter() -> void:
	super.on_enter()
	
	# Spend AP for guard
	group_resources.spend_ap(GroupResources.GUARD_COST)
	
	# Enable guard damage reduction
	group_resources.set_guarding(true)
	
	if animator:
		animator.play("Idle")  # Placeholder for guard pose animation
	
	# Stop movement
	pawn.velocity = Vector3.ZERO


func on_exit() -> void:
	super.on_exit()
	group_resources.set_guarding(false)


func update(_delta: float) -> void:
	# Stay in place while guarding
	pawn.velocity = Vector3.ZERO
	pawn.move_and_slide()


func check_transition(_delta: float) -> Array:
	# Guard state lasts for the entire enemy turn
	# Transitions are handled externally when turn changes
	return [false, ""]
