# res://weapons/BaseWeapon.gd
extends Node3D
class_name BaseWeapon

@export var data: WeaponData
@onready var muzzle: Node3D = $"Muzzle"  # must exist in the weapon scene

@onready var cooldown_timer: Timer = Timer.new()
@onready var ammo_count : int = data.ammo_count

var character: CharacterBody3D

signal fire_weapon(ammo_remaining: int)
signal discard

func _ready() -> void:
	cooldown_timer.name = "CooldownTimer"
	cooldown_timer.one_shot = true
	add_child(cooldown_timer)
	cooldown_timer.start()

func can_fire() -> bool:
	return cooldown_timer.is_stopped() and data != null and data.projectile_scene != null

func try_fire() -> void:
	if not can_fire():
		return
	
	if ammo_count > 0:
		ammo_count -= 1
		_spawn_projectiles()
		cooldown_timer.start(data.fire_rate)
		character.update_ammo.emit(ammo_count)
	elif ammo_count == -1:
		# infinite ammo
		_spawn_projectiles()
		cooldown_timer.start(data.fire_rate)
	else:
		discard_weapon()

func _spawn_projectiles() -> void:
	var world: Node = get_tree().current_scene
	var forward_xy: Vector3 = -muzzle.global_transform.basis.z # -Z is forward
	for i in data.burst_count:
		var proj := data.projectile_scene.instantiate() as BaseProjectile
		world.add_child(proj)
		proj.speed = data.muzzle_velocity
		proj.damage = data.damage
		proj.launch(muzzle.global_transform, forward_xy)

func discard_weapon() -> void:
	character.discard()
