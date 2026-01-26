extends AIState

@export var speed_multiplier: float = 0.5
@export var animation_speed: float = 0.5

var wander_target: Vector3
var wander_timer: float = 0.0
@export var wander_interval: float = 2.0
@export var wander_radius: float = 3.0


func on_enter() -> void:
	super.on_enter()
	print("[LocomotionSlow] === ENTERING LOCOMOTION_SLOW STATE ===")
	
	if animator and enemy_data:
		print("[LocomotionSlow] Playing animation: %s at speed %.2f" % [enemy_data.anim_locomotion, animation_speed])
		animator.play(enemy_data.anim_locomotion)
		animator.speed_scale = animation_speed
	
	wander_timer = 0.0
	_pick_new_wander_target()
	print("[LocomotionSlow] Initial wander target: %s" % wander_target)


func on_exit() -> void:
	super.on_exit()
	print("[LocomotionSlow] === EXITING LOCOMOTION_SLOW STATE ===")
	if animator:
		animator.speed_scale = 1.0


func update(delta: float) -> void:
	wander_timer += delta
	
	if wander_timer >= wander_interval:
		wander_timer = 0.0
		_pick_new_wander_target()
		print("[LocomotionSlow] New wander target: %s" % wander_target)
	
	# Move toward wander target at half speed
	var speed: float = enemy_data.speed * speed_multiplier if enemy_data else 1.5
	navigate_to(wander_target, speed, delta)
	
	# Update animation based on movement
	if animator and enemy_data:
		if character.velocity.length() > 0.1:
			if animator.current_animation != enemy_data.anim_locomotion:
				animator.play(enemy_data.anim_locomotion)
		else:
			if animator.current_animation != enemy_data.anim_idle:
				animator.play(enemy_data.anim_idle)


func _pick_new_wander_target() -> void:
	# Pick a random point near spawn position
	var random_offset := Vector3(
		randf_range(-wander_radius, wander_radius),
		0,
		randf_range(-wander_radius, wander_radius)
	)
	wander_target = spawn_point + random_offset


func check_transition(_delta: float) -> Array:
	# Locomotion slow transitions are handled externally
	return [false, ""]
