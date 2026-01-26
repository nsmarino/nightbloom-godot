extends Node
class_name EnemyManager

@export var Spawns: Node
@export var Pawn: CharacterBody3D
@export var EnemyScene: PackedScene
@export var EnemyDataResource: EnemyData
@export var enemy_count: int = 3

@onready var group_resources: Node = $GroupResources

var active_enemies: Array[BaseEnemy] = []
var attacking_enemy: BaseEnemy = null


func _ready() -> void:
	print("[EnemyManager] Initialized")
	
	# Connect to combat events
	Events.turn_started.connect(_on_turn_started)
	Events.turn_ended.connect(_on_turn_ended)
	Events.combat_started.connect(_on_combat_started)
	
	# Spawn enemies after a short delay
	await get_tree().process_frame
	_spawn_enemies()


func _spawn_enemies() -> void:
	print("[EnemyManager] Starting enemy spawn...")
	
	if not Spawns:
		push_error("[EnemyManager] ERROR: Spawns node not set!")
		return
	if not EnemyScene:
		push_error("[EnemyManager] ERROR: EnemyScene not set!")
		return
	
	print("[EnemyManager] Spawns node: %s" % Spawns.name)
	print("[EnemyManager] EnemyScene: %s" % EnemyScene.resource_path)
	print("[EnemyManager] Pawn reference: %s" % [Pawn.name if Pawn else "NULL"])
	
	var spawn_markers: Array[Node] = []
	for child in Spawns.get_children():
		if child is Marker3D:
			spawn_markers.append(child)
	
	print("[EnemyManager] Found %d spawn markers" % spawn_markers.size())
	
	# Shuffle spawn markers
	spawn_markers.shuffle()
	
	# Spawn enemies at random markers
	var count: int = min(enemy_count, spawn_markers.size())
	for i in range(count):
		var marker: Marker3D = spawn_markers[i] as Marker3D
		var enemy: BaseEnemy = EnemyScene.instantiate() as BaseEnemy
		
		if enemy:
			print("[EnemyManager] Spawning enemy %d at %s" % [i, marker.global_position])
			
			# Configure enemy
			if EnemyDataResource:
				enemy.enemy_data = EnemyDataResource
				print("[EnemyManager] Using enemy data: %s" % EnemyDataResource.display_name)
			
			enemy.set_player(Pawn)
			enemy.set_enemy_manager(self)
			
			# Add to scene
			add_child(enemy)
			# Spawn at ground level (navmesh is at Y=0)
			enemy.global_position = Vector3(marker.global_position.x, 0.0, marker.global_position.z)
			
			active_enemies.append(enemy)
			print("[EnemyManager] Enemy spawned: %s" % enemy.name)
	
	print("[EnemyManager] Spawn complete. Total enemies: %d" % active_enemies.size())


func _on_combat_started() -> void:
	print("[EnemyManager] Combat started - setting all enemies to IDLE")
	for enemy in active_enemies:
		enemy.command_state("idle")


func _on_turn_started(is_player_turn: bool) -> void:
	print("[EnemyManager] Turn started - is_player_turn: %s" % is_player_turn)
	if is_player_turn:
		_start_player_turn()
	else:
		_start_enemy_turn()


func _on_turn_ended(is_player_turn: bool) -> void:
	print("[EnemyManager] Turn ended - is_player_turn: %s" % is_player_turn)
	if not is_player_turn:
		_end_enemy_turn()


func _start_player_turn() -> void:
	print("[EnemyManager] Player turn - enemies enter LOCOMOTION_SLOW")
	for enemy in active_enemies:
		enemy.command_state("locomotion_slow")


func _start_enemy_turn() -> void:
	print("[EnemyManager] === ENEMY TURN START ===")
	
	if active_enemies.is_empty():
		print("[EnemyManager] No active enemies!")
		return
	
	# Pick one enemy to attack, others idle
	attacking_enemy = active_enemies.pick_random()
	print("[EnemyManager] Selected attacker: %s" % attacking_enemy.name)
	
	for enemy in active_enemies:
		if enemy == attacking_enemy:
			print("[EnemyManager] %s -> PURSUE" % enemy.name)
			enemy.command_state("pursue")
		else:
			print("[EnemyManager] %s -> IDLE" % enemy.name)
			enemy.command_state("idle")


func _end_enemy_turn() -> void:
	print("[EnemyManager] === ENEMY TURN END ===")
	attacking_enemy = null


func on_enemy_died(enemy: BaseEnemy) -> void:
	active_enemies.erase(enemy)
	
	if attacking_enemy == enemy:
		attacking_enemy = null
	
	print("[EnemyManager] Enemy died. %d remaining" % active_enemies.size())


func get_active_enemy_count() -> int:
	return active_enemies.size()


func get_closest_enemy_to(position: Vector3) -> BaseEnemy:
	var closest: BaseEnemy = null
	var closest_dist: float = INF
	
	for enemy in active_enemies:
		var dist: float = enemy.global_position.distance_to(position)
		if dist < closest_dist:
			closest_dist = dist
			closest = enemy
	
	return closest


func command_all_enemies(state_name: String) -> void:
	print("[EnemyManager] Commanding all enemies to: %s" % state_name)
	for enemy in active_enemies:
		enemy.command_state(state_name)
