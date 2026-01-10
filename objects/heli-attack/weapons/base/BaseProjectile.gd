# res://projectiles/BaseProjectile.gd
extends Node3D
class_name BaseProjectile

@export var speed: float = 60.0
@export var damage: float = 10.0
@export var life_time: float = 2.0
@export var group_to_damage: StringName = ""

@onready var collider = $Area3D

@onready var _launch_sound: AudioStreamPlayer3D = $LaunchSound
@onready var _hit_sound: AudioStreamPlayer3D = $HitSound


var _dir: Vector3 = Vector3(1, 0, 0)

func _ready() -> void:
	# Simple TTL; swap for a Timer node if you prefer
	get_tree().create_timer(life_time).timeout.connect(queue_free)
	collider.connect("body_entered", on_enter_body)

func _physics_process(delta: float) -> void:
	travel(delta)
	
func launch(from: Transform3D, initial_dir: Vector3) -> void:
	global_transform = from
	_dir = initial_dir.normalized()
	_launch_sound.play()
	
func travel(delta: float) -> void:
	global_position += _dir * speed * delta
	
func on_enter_body(body_entered) -> void:
	if (body_entered.has_method("on_damage") and body_entered.is_in_group(group_to_damage)):
		_hit_sound.play()
		body_entered.on_damage(damage)
		queue_free()
	else:
		queue_free()
