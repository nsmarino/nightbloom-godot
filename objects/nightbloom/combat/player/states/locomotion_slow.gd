extends PlayerState

@export var move_speed: float = 4.0  # Half speed


func on_enter() -> void:
	super.on_enter()
	if animator:
		animator.play("Idle")


func update(delta: float) -> void:
	# If active member is staggered, can't move
	if pawn.is_active_member_staggered():
		pawn.velocity = Vector3.ZERO
		pawn.move_and_slide()
		return
	
	apply_rotation(delta)
	apply_movement(delta, move_speed)


func check_transition(_delta: float) -> Array:
	# Guard input during enemy turn
	if Input.is_action_just_pressed("CombatGuard"):
		if group_resources.can_afford_ap(GroupResources.GUARD_COST):
			return [true, "guard"]
	
	# Allow menu only if active party member is staggered (to switch members)
	if Input.is_action_just_pressed("CombatMenu"):
		if pawn.is_active_member_staggered():
			return [true, "decide_menu"]
		else:
			print("[LocomotionSlow] Cannot open menu during enemy turn unless staggered")
	
	return [false, ""]
