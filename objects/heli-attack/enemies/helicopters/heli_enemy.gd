extends BaseEnemy
class_name HeliEnemy

@export var weapon_scene: PackedScene  # assign Blaster.tscn, etc. in Inspector

@onready var WeaponSocket: Node3D = $WeaponSocket
@onready var Sprite: Sprite3D = $Visuals/HeliSprite
@onready var HUD: Sprite3D = $Visuals/HUD
@onready var ParticlesDeath: GPUParticles3D = $Visuals/ParticlesDeath
@onready var Collider = $Collider

func _ready() -> void:
	_instance_weapon()

func _instance_weapon() -> void:
	var weapon := weapon_scene.instantiate() as BaseWeapon
	WeaponSocket.add_child(weapon)
	
func _process(delta: float) -> void:
	var target = Vector3(player.global_position.x, player.global_position.y+1, player.global_position.z)
	if (WeaponSocket): WeaponSocket.look_at(target)
	
