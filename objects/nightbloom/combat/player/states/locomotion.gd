extends PlayerState

@export var move_speed: float = 8.0


func on_enter() -> void:
	super.on_enter()
	if animator:
		animator.play("Idle")


func update(delta: float) -> void:
	apply_rotation(delta)
	apply_movement(delta, move_speed)


func check_transition(_delta: float) -> Array:
	# Attack input
	if Input.is_action_just_pressed("CombatAttack"):
		return [true, "attack"]
	
	# Open decide menu
	if Input.is_action_just_pressed("CombatMenu"):
		return [true, "decide_menu"]
	
	return [false, ""]
