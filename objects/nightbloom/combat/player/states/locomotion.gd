extends PlayerState

@export var move_speed: float = 8.0


func on_enter() -> void:
	super.on_enter()
	if animator:
		animator.play("RUN")


func update(delta: float) -> void:
	apply_movement(delta, move_speed)
	
	# Update animation based on movement
	var input_dir := get_movement_input()
	if animator:
		if input_dir.length() > 0.1:
			if not animator.is_playing() or animator.current_animation != "RUN":
				animator.play("RUN")
		else:
			if not animator.is_playing() or animator.current_animation != "Idle":
				animator.play("Idle")


func check_transition(_delta: float) -> Array:
	# Attack input
	if Input.is_action_just_pressed("CombatAttack"):
		return [true, "attack"]
	
	# Open decide menu
	if Input.is_action_just_pressed("CombatMenu"):
		return [true, "decide_menu"]
	
	return [false, ""]
