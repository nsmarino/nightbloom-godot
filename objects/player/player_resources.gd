extends Node
class_name PlayerResources

@export var max_health : float = 100
@export var health : float = 100

var jump : float = 100
var max_jump : float = 100

var special : float = 100
var max_special : float = 100

@export var money : int = 0

signal update_player_health(health: float)
signal update_player_money(money: int)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass

func lose_health(amount : float) -> void:
	health -= amount
	if health < 1:
		Events.player_killed.emit()
	update_player_health.emit(health)

func gain_health(amount : float) -> void:
	if health + amount <= max_health:
		health += amount
	else:
		health = max_health
	update_player_health.emit(health)

func gain_money(amount: int) -> void:
	money += amount
	update_player_money.emit(money)

func lose_money(amount : int) -> void:
	money -= amount
	if money < 0:
		money = 0
	update_player_money.emit(money)
