extends Camera3D
## Simple follow camera that tracks a target from a fixed offset

@export var target_path: NodePath
@export var offset: Vector3 = Vector3(0, 12, -8)
@export var smooth_speed: float = 5.0

var target: Node3D


func _ready() -> void:
	if target_path:
		target = get_node_or_null(target_path) as Node3D


func _physics_process(delta: float) -> void:
	if not target:
		return
	
	# Calculate desired position
	var desired_position: Vector3 = target.global_position + offset
	
	# Smoothly move to desired position
	global_position = global_position.lerp(desired_position, smooth_speed * delta)
	
	# Always look at target
	look_at(target.global_position + Vector3(0, 1, 0))


func set_target(new_target: Node3D) -> void:
	target = new_target
