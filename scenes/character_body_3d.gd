extends CharacterBody3D

## Exploration character controller with third-person camera
## Movement is relative to camera direction

@export var move_speed: float = 12.0
@export var vertical_speed: float = 8.0
@export var mouse_sensitivity: float = 0.003
@export var gamepad_look_sensitivity: float = 3.0

# Camera pivot node - add as child of this CharacterBody3D
@onready var camera_pivot: Node3D = $CameraPivot
@onready var camera: Camera3D = $CameraPivot/Camera3D

var camera_rotation := Vector2.ZERO  # x = yaw, y = pitch
var pitch_limit := deg_to_rad(89.0)


func _ready() -> void:
	# Capture mouse for camera control
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


func _input(event: InputEvent) -> void:
	# Mouse look
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		camera_rotation.x -= event.relative.x * mouse_sensitivity
		camera_rotation.y -= event.relative.y * mouse_sensitivity
		camera_rotation.y = clamp(camera_rotation.y, -pitch_limit, pitch_limit)
	
	# Toggle mouse capture with Escape
	if event.is_action_pressed("ui_cancel"):
		if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


func _physics_process(delta: float) -> void:
	# Gamepad camera look (right stick)
	var look_input := Vector2.ZERO
	look_input.x = Input.get_axis("LookLeft", "LookRight")
	look_input.y = Input.get_axis("LookUp", "LookDown")
	
	if look_input.length() > 0.1:
		camera_rotation.x -= look_input.x * gamepad_look_sensitivity * delta
		camera_rotation.y -= look_input.y * gamepad_look_sensitivity * delta
		camera_rotation.y = clamp(camera_rotation.y, -pitch_limit, pitch_limit)
	
	# Apply camera rotation to pivot
	camera_pivot.rotation.y = camera_rotation.x
	camera_pivot.rotation.x = camera_rotation.y
	
	# Movement input (left stick / WASD)
	var input_dir := Vector2.ZERO
	input_dir.x = Input.get_axis("MoveLeft", "MoveRight")
	input_dir.y = Input.get_axis("MoveForward", "MoveBackward")
	
	# Vertical movement (bumpers)
	var vertical_input := Input.get_axis("FlyDown", "FlyUp")
	
	# Get camera's forward and right vectors (ignore pitch for horizontal movement)
	var cam_basis := camera_pivot.global_transform.basis
	var forward := -cam_basis.z
	var right := cam_basis.x
	
	# Flatten for horizontal movement only
	forward.y = 0
	right.y = 0
	forward = forward.normalized()
	right = right.normalized()
	
	# Calculate movement direction
	var move_dir := Vector3.ZERO
	move_dir += forward * -input_dir.y  # Forward/backward
	move_dir += right * input_dir.x      # Left/right
	move_dir.y = vertical_input          # Up/down from bumpers
	
	# Apply movement
	if move_dir.length() > 0:
		move_dir = move_dir.normalized()
	
	velocity = move_dir * move_speed
	velocity.y = vertical_input * vertical_speed  # Separate vertical speed
	
	move_and_slide()
