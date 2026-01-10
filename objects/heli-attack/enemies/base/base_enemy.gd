extends CharacterBody3D
class_name BaseEnemy

@export var player : CharacterBody3D
@export var speed : float = 3

@onready var Resources = $Resources

var spawn_point : Vector3

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	spawn_point = global_position

func on_damage(damage: float) -> void:
	Resources.lose_health(damage)
