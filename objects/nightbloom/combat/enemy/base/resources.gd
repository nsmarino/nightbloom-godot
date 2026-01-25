extends Node
class_name EnemyResources

@export var state_machine : Node
@export var health_bar: TextureProgressBar
@export var max_health : float = 100
@export var health : float = 100

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	health_bar.max_value = max_health
	health_bar.value = health

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func lose_health(amount : float):
	health -= amount
	if health < 1:
		state_machine.switch_to("death")
	health_bar.value = health


func gain_health(amount : float):
	if health + amount <= max_health:
		health += amount
	else:
		health = max_health
	health_bar.value = health
