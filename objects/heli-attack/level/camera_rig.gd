extends Node3D

@export var target: Node3D

@export var bounds_left: float = 2.0
@export var bounds_right: float = 17.0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
#	global_position.x = clamp(target.global_position.x, bounds_left, bounds_right)
