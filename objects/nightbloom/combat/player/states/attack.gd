extends PlayerState

@export var attack_duration: float = 0.8
@export var hitbox_start: float = 0.2
@export var hitbox_end: float = 0.5
@export var attack_damage: int = 20

var has_hit_enemy: bool = false


func on_enter() -> void:
	super.on_enter()
	has_hit_enemy = false
	if animator:
		animator.play("Combo1")
	
	# Enable hit detection
	if hit_area:
		hit_area.monitoring = true


func on_exit() -> void:
	super.on_exit()
	if hit_area:
		hit_area.monitoring = false


func update(_delta: float) -> void:
	# Stop movement during attack
	pawn.velocity = Vector3.ZERO
	pawn.move_and_slide()
	
	# Check for hits during active frames
	if duration_between(hitbox_start, hitbox_end) and not has_hit_enemy:
		_check_for_hits()


func _check_for_hits() -> void:
	if not hit_area:
		return
	
	var bodies := hit_area.get_overlapping_bodies()
	for body in bodies:
		if body.is_in_group("enemy"):
			_on_hit_enemy(body)
			break


func _on_hit_enemy(enemy: Node) -> void:
	has_hit_enemy = true
	
	# Damage the shared enemy health pool
	if enemy_group:
		var enemy_resources: Node = enemy_group.get_node("GroupResources")
		if enemy_resources:
			enemy_resources.take_damage(attack_damage)
	
	# Award AP
	group_resources.gain_ap(GroupResources.AP_GAIN_ON_HIT)
	
	# Signal the hit
	Events.attack_hit.emit(pawn, enemy, attack_damage)
	
	# Tell enemy to enter receive_attack state
	if enemy.has_method("receive_attack"):
		enemy.receive_attack()


func check_transition(_delta: float) -> Array:
	if duration_longer_than(attack_duration):
		return [true, "locomotion"]
	
	return [false, ""]
