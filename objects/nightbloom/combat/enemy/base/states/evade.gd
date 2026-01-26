extends AIState

@export var evade_duration: float = 2.0


func on_enter() -> void:
	super.on_enter()
	print("[Evade] === ENTERING EVADE STATE ===")
	print("[Evade] Will evade for %.2f seconds" % evade_duration)
	
	if animator and enemy_data:
		print("[Evade] Playing animation: %s" % enemy_data.anim_locomotion)
		animator.play(enemy_data.anim_locomotion)


func update(delta: float) -> void:
	if not player:
		print("[Evade] ERROR: No player reference!")
		return
	
	# Move away from player
	var speed: float = enemy_data.speed if enemy_data else 3.0
	
	if Engine.get_physics_frames() % 30 == 0:
		print("[Evade] Moving away from player, speed: %.2f" % speed)
	
	move_away_from(player.global_position, speed, delta)


func check_transition(_delta: float) -> Array:
	# Evade until turn ends (handled externally) or duration expires
	if duration_longer_than(evade_duration):
		print("[Evade] Evade duration complete - transitioning to IDLE")
		return [true, "idle"]
	
	return [false, ""]
