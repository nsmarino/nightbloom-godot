extends Node
class_name EnemyGroupResources

@export var max_hp: int = 100
@export var hp: int = 100

# Damage multiplier when all enemies are staggered
const ALL_STAGGERED_MULTIPLIER: float = 2.0

# Reference to enemy manager for stagger check
var enemy_manager: Node


func _ready() -> void:
	# Emit initial values
	Events.enemy_hp_changed.emit(hp, max_hp)
	
	# Get reference to parent enemy manager
	await get_tree().process_frame
	enemy_manager = get_parent()


func take_damage(amount: int) -> void:
	var actual_amount: int = amount
	
	# Apply bonus damage if all enemies are staggered
	if enemy_manager and enemy_manager.has_method("are_all_enemies_staggered"):
		if enemy_manager.are_all_enemies_staggered():
			actual_amount = int(float(amount) * ALL_STAGGERED_MULTIPLIER)
			print("[EnemyGroupResources] ALL STAGGERED! Damage %d -> %d" % [amount, actual_amount])
	
	hp = max(0, hp - actual_amount)
	Events.enemy_damaged.emit(actual_amount)
	Events.enemy_hp_changed.emit(hp, max_hp)


func heal(amount: int) -> void:
	hp = min(max_hp, hp + amount)
	Events.enemy_hp_changed.emit(hp, max_hp)


func is_defeated() -> bool:
	return hp <= 0


func reset_for_combat() -> void:
	hp = max_hp
	Events.enemy_hp_changed.emit(hp, max_hp)


func get_health_percentage() -> float:
	return float(hp) / float(max_hp)
