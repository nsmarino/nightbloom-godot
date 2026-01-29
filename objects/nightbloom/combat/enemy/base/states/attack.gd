extends AIState

## Hitbox timing (as fraction of animation or absolute time if no animation)
@export var hitbox_start: float = 0.2
@export var hitbox_end: float = 0.5
## Fallback duration if animation is missing (also used for time-check before attacking)
@export var fallback_duration: float = 0.8

var has_hit_player: bool = false
var animation_finished: bool = false
var attack_animation: String = ""


func on_enter() -> void:
	super.on_enter()
	has_hit_player = false
	animation_finished = false
	
	print("[Attack] === ENTERING ATTACK STATE ===")
	print("[Attack] Hitbox active: %.2f - %.2f, Fallback duration: %.2f" % [hitbox_start, hitbox_end, fallback_duration])
	
	if animator and enemy_data:
		attack_animation = enemy_data.anim_attack
		print("[Attack] Playing animation: %s" % attack_animation)
		
		# Connect to animation_finished signal
		if not animator.animation_finished.is_connected(_on_animation_finished):
			animator.animation_finished.connect(_on_animation_finished)
		animator.play(attack_animation)
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
	
	# Disconnect signal to avoid issues when re-entering
	if animator and animator.animation_finished.is_connected(_on_animation_finished):
		animator.animation_finished.disconnect(_on_animation_finished)


func update(_delta: float) -> void:
	# Stop movement during attack (but participate in avoidance)
	stop_with_avoidance()
	
	# Check for hits during active frames
	if duration_between(hitbox_start, hitbox_end) and not has_hit_player:
		_check_for_hits()


func _on_animation_finished(anim_name: StringName) -> void:
	if anim_name == attack_animation:
		animation_finished = true
		print("[Attack] Animation finished")


func _check_for_hits() -> void:
	if not attack_area:
		return
	
	var bodies := attack_area.get_overlapping_bodies()
	
	for body in bodies:
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
	# Primary: animation finished
	if animation_finished:
		print("[Attack] Attack complete (animation finished) - transitioning to EVADE")
		return [true, "evade"]
	
	# Fallback: timer (in case animation is missing or looping)
	if fallback_duration > 0 and duration_longer_than(fallback_duration):
		print("[Attack] WARNING: Using fallback duration - transitioning to EVADE")
		return [true, "evade"]
	
	return [false, ""]


## Returns the expected duration of this attack (for time checking)
func get_attack_duration() -> float:
	return fallback_duration
