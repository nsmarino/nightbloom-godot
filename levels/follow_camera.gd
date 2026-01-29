extends Camera3D
## Camera that stays as a child of the pawn but looks at a target marker

@export var target_path: NodePath
@export var offset: Vector3 = Vector3(0, 12, -8)

var target: Node3D


func _ready() -> void:
	# Set local position from offset (we're a child of Pawn, so local position stays fixed relative to pawn)
	position = offset
	
	if target_path:
		target = get_node_or_null(target_path) as Node3D


func _physics_process(_delta: float) -> void:
	if target:
		# Look at the target marker (also a child of Pawn)
		look_at(target.global_position)
