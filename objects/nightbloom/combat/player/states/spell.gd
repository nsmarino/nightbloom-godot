extends PlayerState

## Fallback values if no spell data is set
@export var fallback_duration: float = 1.2
@export var fallback_damage: int = 35
@export var fallback_stagger: int = 25

var target_enemy: Node = null
var spell_data: SpellData = null
var has_applied_damage: bool = false


func on_enter() -> void:
	super.on_enter()
	has_applied_damage = false
	
	# Note: AP and MP are spent in select_spell_target state before transitioning here
	
	# Play animation
	if animator:
		var anim_name: String = spell_data.animation if spell_data else "Spell"
		if animator.has_animation(anim_name):
			animator.play(anim_name)
		else:
			animator.play("Combo1")  # Fallback animation
	
	# Stop movement
	pawn.velocity = Vector3.ZERO
	
	print("[Spell] Casting %s on %s" % [
		spell_data.name if spell_data else "spell",
		target_enemy.name if target_enemy else "no target"
	])


func on_exit() -> void:
	super.on_exit()
	# Clear state
	target_enemy = null
	spell_data = null
	has_applied_damage = false


func update(_delta: float) -> void:
	pawn.velocity = Vector3.ZERO
	pawn.move_and_slide()
	
	# Apply damage at midpoint of cast
	var duration: float = _get_cast_duration()
	var hit_time: float = duration * 0.5
	if not has_applied_damage and duration_longer_than(hit_time) and target_enemy:
		_apply_spell_damage()


func _apply_spell_damage() -> void:
	has_applied_damage = true
	
	var damage: int = spell_data.attack_power if spell_data else fallback_damage
	
	# Apply HP damage to shared enemy health pool
	if enemy_group:
		var enemy_resources: Node = enemy_group.get_node("GroupResources")
		if enemy_resources:
			enemy_resources.take_damage(damage)
	
	# Award AP for successful spell
	group_resources.gain_ap(GroupResources.AP_GAIN_ON_HIT)
	
	# Apply spell hit to target enemy (stagger + PRESSURED check)
	if target_enemy:
		if spell_data and target_enemy.has_method("apply_spell_hit"):
			target_enemy.apply_spell_hit(spell_data)
		elif target_enemy.has_method("receive_attack"):
			target_enemy.receive_attack()
	
	print("[Spell] Hit %s for %d damage" % [target_enemy.name if target_enemy else "target", damage])


func _get_cast_duration() -> float:
	if spell_data:
		return spell_data.fallback_duration
	return fallback_duration


func check_transition(_delta: float) -> Array:
	if duration_longer_than(_get_cast_duration()):
		return [true, "locomotion"]
	
	return [false, ""]


func set_target(enemy: Node) -> void:
	target_enemy = enemy


func set_spell_data(data: SpellData) -> void:
	spell_data = data
