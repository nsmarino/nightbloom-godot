extends PlayerState

@export var move_speed: float = 4.0  # Half speed
@export var animation_speed: float = 0.5


func on_enter() -> void:
	super.on_enter()
	if animator:
		animator.play("RUN")
		animator.speed_scale = animation_speed


func on_exit() -> void:
	super.on_exit()
	if animator:
		animator.speed_scale = 1.0


func update(delta: float) -> void:
	apply_movement(delta, move_speed)
	
	# Update animation based on movement
	var input_dir := get_movement_input()
	if animator:
		if input_dir.length() > 0.1:
			if animator.current_animation != "RUN":
				animator.play("RUN")
		else:
			if animator.current_animation != "Idle":
				animator.play("Idle")


func check_transition(_delta: float) -> Array:
	# Guard input during enemy turn
	if Input.is_action_just_pressed("CombatGuard"):
		if group_resources.can_afford_ap(GroupResources.GUARD_COST):
			return [true, "guard"]
	
	return [false, ""]
