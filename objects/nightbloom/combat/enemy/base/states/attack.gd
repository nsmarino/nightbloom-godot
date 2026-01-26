extends AIState

@export var attack_duration: float = 0.8
@export var hitbox_start: float = 0.2
@export var hitbox_end: float = 0.5

var has_hit_player: bool = false


func on_enter() -> void:
	super.on_enter()
	has_hit_player = false
	
	print("[Attack] === ENTERING ATTACK STATE ===")
	print("[Attack] Duration: %.2f, Hitbox active: %.2f - %.2f" % [attack_duration, hitbox_start, hitbox_end])
	
	if animator and enemy_data:
		print("[Attack] Playing animation: %s" % enemy_data.anim_attack)
		animator.play(enemy_data.anim_attack)
	else:
		print("[Attack] WARNING: Cannot play animation - animator=%s, enemy_data=%s" % [animator != null, enemy_data != null])
	
	# Enable attack area monitoring
	if attack_area:
		attack_area.monitoring = true
		print("[Attack] Attack area monitoring ENABLED")
	else:
		print("[Attack] WARNING: No attack_area!")
	
	# Face the player
	if player:
		var direction: Vector3 = (player.global_position - character.global_position).normalized()
		direction.y = 0
		if direction.length() > 0.1:
			character.rotation.y = atan2(direction.x, direction.z)
			print("[Attack] Facing player at rotation: %.2f" % character.rotation.y)


func on_exit() -> void:
	super.on_exit()
	print("[Attack] === EXITING ATTACK STATE ===")
	if attack_area:
		attack_area.monitoring = false


func update(delta: float) -> void:
	# Stop movement during attack
	character.velocity = Vector3.ZERO
	character.move_and_slide()
	
	var progress: float = get_progress()
	
	# Log progress
	if Engine.get_physics_frames() % 15 == 0:
		print("[Attack] Progress: %.2f / %.2f" % [progress, attack_duration])
	
	# Check for hits during active frames
	if duration_between(hitbox_start, hitbox_end) and not has_hit_player:
		_check_for_hits()


func _check_for_hits() -> void:
	if not attack_area:
		return
	
	var bodies := attack_area.get_overlapping_bodies()
	print("[Attack] Checking hits - found %d overlapping bodies" % bodies.size())
	
	for body in bodies:
		print("[Attack] Body: %s, groups: %s" % [body.name, body.get_groups()])
		if body.is_in_group("player"):
			_on_hit_player(body)
			break


func _on_hit_player(target: Node) -> void:
	has_hit_player = true
	
	var damage: int = enemy_data.attack_power if enemy_data else 10
	print("[Attack] HIT PLAYER! Dealing %d damage" % damage)
	
	# Signal the hit
	Events.attack_hit.emit(character, target, damage)
	
	# Tell player to receive damage
	if target.has_method("receive_attack"):
		target.receive_attack(damage)


func check_transition(_delta: float) -> Array:
	if duration_longer_than(attack_duration):
		print("[Attack] Attack complete - transitioning to EVADE")
		return [true, "evade"]
	
	return [false, ""]
