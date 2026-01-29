extends PlayerState

@export var move_speed: float = 4.0  # Half speed


func on_enter() -> void:
	super.on_enter()
	if animator:
		animator.play("Idle")


func update(delta: float) -> void:
	apply_rotation(delta)
	apply_movement(delta, move_speed)


func check_transition(_delta: float) -> Array:
	# Guard input during enemy turn
	if Input.is_action_just_pressed("CombatGuard"):
		if group_resources.can_afford_ap(GroupResources.GUARD_COST):
			return [true, "guard"]
	
	return [false, ""]
