extends PlayerState

@export var move_speed: float = 8.0


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
	# Attack input - only if not staggered
	if Input.is_action_just_pressed("CombatAttack"):
		if not pawn.is_active_member_staggered():
			return [true, "attack"]
		else:
			print("[Locomotion] Cannot attack - active party member is staggered!")
	
	# Open decide menu - always allowed (to switch party members when staggered)
	if Input.is_action_just_pressed("CombatMenu"):
		return [true, "decide_menu"]
	
	return [false, ""]
