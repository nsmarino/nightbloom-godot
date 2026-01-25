extends Node

@export var Spawns: Node
@export var Pawn: CharacterBody3D
@export var Enemies: Array[PackedScene]
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	print("init enemy manager")

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass
