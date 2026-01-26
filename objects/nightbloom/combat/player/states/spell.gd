extends PlayerState

@export var cast_duration: float = 1.2
@export var spell_damage: int = 35

var target_enemy: Node = null


func on_enter() -> void:
	super.on_enter()
	
	# Spend AP
	group_resources.spend_ap(GroupResources.SPELL_COST)
	
	if animator:
		animator.play("Combo1")  # Placeholder for spell cast animation
	
	# Stop movement
	pawn.velocity = Vector3.ZERO


func update(_delta: float) -> void:
	pawn.velocity = Vector3.ZERO
	pawn.move_and_slide()
	
	# Apply damage at midpoint of cast
	if duration_between(0.5, 0.6) and target_enemy:
		_apply_spell_damage()


func _apply_spell_damage() -> void:
	if enemy_group:
		var enemy_resources: Node = enemy_group.get_node("GroupResources")
		if enemy_resources:
			enemy_resources.take_damage(spell_damage)
	
	# Award AP for successful spell
	group_resources.gain_ap(GroupResources.AP_GAIN_ON_HIT)
	
	if target_enemy and target_enemy.has_method("receive_attack"):
		target_enemy.receive_attack()
	
	target_enemy = null


func check_transition(_delta: float) -> Array:
	if duration_longer_than(cast_duration):
		return [true, "locomotion"]
	
	return [false, ""]


func set_target(enemy: Node) -> void:
	target_enemy = enemy
