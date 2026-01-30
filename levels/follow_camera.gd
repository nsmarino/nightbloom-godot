extends Camera3D
## Camera that stays as a child of the pawn but looks at a target marker

@export var target_path: NodePath
@export var offset: Vector3 = Vector3(0, 12, -8)
@export var lerp_speed: float = 5.0

var target: Node3D
var target_override: Node3D = null
var is_overriding: bool = false


func _ready() -> void:
	# Set local position from offset (we're a child of Pawn, so local position stays fixed relative to pawn)
	position = offset
	
	if target_path:
		target = get_node_or_null(target_path) as Node3D


func _physics_process(delta: float) -> void:
	var look_target: Node3D = target_override if is_overriding and target_override else target
	
	if look_target:
		if is_overriding:
			# Smooth lerp to target override
			var current_look_dir: Vector3 = -global_transform.basis.z
			var target_dir: Vector3 = (look_target.global_position - global_position).normalized()
			var new_dir: Vector3 = current_look_dir.lerp(target_dir, lerp_speed * delta)
			look_at(global_position + new_dir)
		else:
			# Direct look at normal target
			look_at(look_target.global_position)


func set_target_override(new_target: Node3D) -> void:
	target_override = new_target
	is_overriding = (new_target != null)


func clear_target_override() -> void:
	target_override = null
	is_overriding = false


func get_target_override() -> Node3D:
	return target_override
