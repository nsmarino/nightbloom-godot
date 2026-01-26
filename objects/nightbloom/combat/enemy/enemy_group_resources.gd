extends Node
class_name EnemyGroupResources

@export var max_hp: int = 100
@export var hp: int = 100


func _ready() -> void:
	# Emit initial values
	Events.enemy_hp_changed.emit(hp, max_hp)


func take_damage(amount: int) -> void:
	hp = max(0, hp - amount)
	Events.enemy_damaged.emit(amount)
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
