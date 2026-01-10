extends Marker3D

@export var PLAYER: CharacterBody3D

@export var heli_scenes: Array[PackedScene] = []
@export var itemDrop_scenes: Array[PackedScene] = []
@onready var spawnTimer: Timer = $Timer

var heli_count: int = 0

signal update_heli_count(count: int)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Events.helicopter_destroyed.connect(_on_heli_death)
	spawnTimer.timeout.connect(_spawn_heli)
	
	spawnTimer.start()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _spawn_heli() -> void:

	var heli := heli_scenes[0].instantiate() as HeliEnemy
	heli.player = PLAYER
	add_child(heli)

func _spawn_itemDrop(from) -> void:
	var world: Node = get_tree().current_scene

	var item := itemDrop_scenes[0].instantiate() as Node3D
	world.add_child(item)
	item.global_position = from


func _on_heli_death(loc) -> void:
	
#	update number of helicopters destroyed
	heli_count += 1
	update_heli_count.emit(heli_count)
	
#	drop item such as weapon, extra health, etc
	_spawn_itemDrop(loc)
	
#	wait a few seconds then add a new helicopter enemy to the scene
	spawnTimer.start()
