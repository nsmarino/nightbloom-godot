extends CharacterBody3D

@export var smooth: bool = true
@export var turn_speed: float = 12.0  # only used if smooth = true
@export var controller_rotation_speed: float = 3.0  # radians per second for controller input
@export var controller_deadzone: float = 0.1  # additional deadzone for controller input

# Jump settings
@export var enable_double_jump: bool = true
@export var double_jump_velocity_multiplier: float = 0.83  # 5.0/6.0 ratio

# var projectile = preload("res://objects/heli-attack/projectile.tscn")
@export var weapon_scenes: Array[PackedScene] = []   # assign Blaster.tscn, etc. in Inspector

@onready var WeaponPivot: Node3D = $WeaponPivot
@onready var WeaponSocket: Node3D = $WeaponPivot/WeaponSocket

# Sprite layers
@onready var SpriteWeapon: Sprite3D = $"WeaponPivot/CharSprite-Weapon"
@onready var SpriteBase: Sprite3D = $"CharSprite-Base"
@onready var SpriteHead: Sprite3D = $"CharSprite-Head"


var _was_on_floor_last_frame := true
@onready var _jump_sound: AudioStreamPlayer3D = $SoundFX/JumpSound
@onready var _landing_sound: AudioStreamPlayer3D = $SoundFX/LandingSound

@onready var Resources: PlayerResources = $Resources

# World XY plane at z=0
const TARGET_PLANE := Plane(Vector3(0, 0, 1), 0.0)

const SPEED = 6.0
const JUMP_VELOCITY = 6.0

## Each frame, we find the height of the ground below the player and store it here.
## The camera uses this to keep a fixed height while the player jumps, for example.
var ground_height := 0.0

# Double jump state tracking
var jumps_remaining: int = 2  # Start with 2 jumps (first jump + double jump)
var max_jumps: int = 2

# Facing direction tracking
var facing_right: bool = false  # false = facing left (default), true = facing right

var _weapons: Array[BaseWeapon] = []
var _current_weapon: BaseWeapon
var _current_index: int = 0

signal update_player_reload(value: float)
signal update_equipped_weapon(display_name: String, ammo_count: int)

func _ready() -> void:
	_instance_weapons()
	_equip(0)

func _instance_weapons() -> void:
	_weapons.clear()
	for s in weapon_scenes:
		var w := s.instantiate() as BaseWeapon
		WeaponSocket.add_child(w)
		w.visible = false
		w.character = self
		_weapons.append(w)

func _equip(index: int) -> void:
	if _weapons.is_empty():
		_current_weapon = null
		return
	_current_index = (index % _weapons.size() + _weapons.size()) % _weapons.size()
	for i in _weapons.size():
		_weapons[i].visible = (i == _current_index)
	_current_weapon = _weapons[_current_index]
	update_equipped_weapon.emit(_current_weapon.data.display_name, _current_weapon.ammo_count)

func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Handle jump and double jump
	if Input.is_action_just_pressed("Jump") and jumps_remaining > 0:
		if is_on_floor():
			# First jump (on ground)
			velocity.y = JUMP_VELOCITY
			jumps_remaining -= 1
			_jump_sound.play()
		elif enable_double_jump:
			# Double jump (in air)
			velocity.y = JUMP_VELOCITY * double_jump_velocity_multiplier
			jumps_remaining -= 1
			_jump_sound.play()

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var input_dir := Input.get_axis("MoveLeft", "MoveRight")
	var direction := (transform.basis * Vector3(input_dir, 0, 0)).normalized()
	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)
	
	# Flip sprites based on movement direction
	# Only update flip when there's actual input to preserve facing when stopped
	if input_dir > 0:
		# Moving right - flip sprites
		facing_right = true
		SpriteBase.flip_h = true
		SpriteHead.flip_h = true
		# Flip WeaponPivot by scaling X to -1
		WeaponPivot.scale.x = -1.0
	elif input_dir < 0:
		# Moving left - use default orientation
		facing_right = false
		SpriteBase.flip_h = false
		SpriteHead.flip_h = false
		# Reset WeaponPivot scale
		WeaponPivot.scale.x = 1.0

	if is_on_floor() and not _was_on_floor_last_frame:
		_landing_sound.play()
		# Reset jumps when landing
		jumps_remaining = max_jumps

	_was_on_floor_last_frame = is_on_floor()
	move_and_slide()

func _process(delta: float) -> void:
	
	# Calculate reload percentage (0 = just fired, 100 = ready to fire)
	var reload_percentage: float = 0.0
	if _current_weapon and _current_weapon.cooldown_timer.wait_time > 0:
		reload_percentage = ((1.0 - (_current_weapon.cooldown_timer.time_left / _current_weapon.cooldown_timer.wait_time)) * 100.0)
	update_player_reload.emit(reload_percentage)
	
	if (Input.is_action_pressed("Shoot") and _current_weapon != null):
		_current_weapon.try_fire()

	# Get controller look input (right stick horizontal)
	var look_input: float = Input.get_axis("LookLeft", "LookRight")
	
	# Apply deadzone filtering (already handled by Input.get_axis, but we can add extra smoothing)
	if abs(look_input) < controller_deadzone:
		look_input = 0.0
	
	# Convert controller input to rotation
	# Positive input = clockwise rotation (right), negative = counter-clockwise (left)
	var rotation_delta: float = look_input * controller_rotation_speed * delta
	
	# Apply rotation only around Z axis
	if smooth:
		# For smooth rotation, we can either:
		# Option 1: Direct rotation based on input
		WeaponPivot.rotation.z -= rotation_delta
		# Option 2: Target-based rotation (uncomment below if preferred)
		# var target_angle: float = WeaponPivot.rotation.z + rotation_delta
		# WeaponPivot.rotation.z = lerp_angle(WeaponPivot.rotation.z, target_angle, 1.0 - pow(0.001, delta * turn_speed))
	else:
		# Instant rotation
		WeaponPivot.rotation.z -= rotation_delta

func _unhandled_input(_event: InputEvent) -> void:
	# Handle weapon switching with controller
	if Input.is_action_just_pressed("NextWeapon"):
		_equip(_current_index + 1)
	elif Input.is_action_just_pressed("PreviousWeapon"):
		_equip(_current_index - 1)

func on_damage(damage: float) -> void:
	Resources.lose_health(damage)

func pickup_weapon(packed_scene: PackedScene) -> void:
	var w := packed_scene.instantiate() as BaseWeapon
	WeaponSocket.add_child(w)
	w.visible = false
	_weapons.append(w)
	w.character = self
	
	_equip(_weapons.size()-1)

func discard() -> void:
	# Can't discard if no weapons exist or no current weapon
	if _weapons.is_empty() or _current_weapon == null:
		return
	
	# Store the weapon to remove and its index
	var weapon_to_remove: BaseWeapon = _current_weapon
	var old_index: int = _current_index
	
	# Calculate the new index (previous weapon with wrap-around)
	# If we're at index 0, wrap to the end of the array (after removal)
	# Otherwise, go to the previous weapon
	var new_index: int = old_index - 1 if old_index > 0 else _weapons.size() - 2
	
	# If this is the last weapon, clear everything
	if _weapons.size() == 1:
		_current_weapon = null
		_current_index = 0
		weapon_to_remove.queue_free()
		_weapons.clear()
		return
	
	# Remove the weapon from the array
	_weapons.remove_at(old_index)
	
	# Free the weapon from the scene tree
	weapon_to_remove.queue_free()
	
	# Adjust new_index if it's out of bounds after removal
	if new_index >= _weapons.size():
		new_index = _weapons.size() - 1
	
	# Equip the weapon at the new index
	_equip(new_index)
