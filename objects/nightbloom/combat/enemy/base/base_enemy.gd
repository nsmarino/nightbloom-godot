extends CharacterBody3D
class_name BaseEnemy

@export var enemy_data: EnemyData

@onready var state_machine: Node = $StateMachine
@onready var nav_agent: NavigationAgent3D = $NavigationAgent3D
@onready var attack_area: Area3D = $AttackArea

var player: CharacterBody3D
var enemy_manager: Node
var spawn_point: Vector3
var character_instance: Node3D
var animator: AnimationPlayer


func _ready() -> void:
	spawn_point = global_position
	add_to_group("enemy")
	
	print("[BaseEnemy:%s] Initialized at %s" % [name, global_position])
	print("[BaseEnemy:%s] NavAgent: %s" % [name, nav_agent != null])
	print("[BaseEnemy:%s] StateMachine: %s" % [name, state_machine != null])
	print("[BaseEnemy:%s] EnemyData: %s" % [name, enemy_data.display_name if enemy_data else "NULL"])
	
	# Spawn character mesh from enemy data
	if enemy_data and enemy_data.character_scene:
		_spawn_character_mesh()
	else:
		print("[BaseEnemy:%s] WARNING: No character_scene in enemy_data!" % name)
	
	# Set up state machine references
	_setup_state_machine()
	
	# Wait a frame then check navigation
	await get_tree().process_frame
	_check_navigation_setup()


func _check_navigation_setup() -> void:
	print("[BaseEnemy:%s] === NAVIGATION CHECK ===" % name)
	
	if not nav_agent:
		print("[BaseEnemy:%s] ERROR: NavigationAgent3D is NULL!" % name)
		return
	
	# Check if we're on a navmesh
	var nav_map: RID = nav_agent.get_navigation_map()
	print("[BaseEnemy:%s] Navigation map RID: %s" % [name, nav_map])
	
	if nav_map.is_valid():
		print("[BaseEnemy:%s] Navigation map is VALID" % name)
		
		# Check map info
		var map_cell_size: float = NavigationServer3D.map_get_cell_size(nav_map)
		var map_cell_height: float = NavigationServer3D.map_get_cell_height(nav_map)
		print("[BaseEnemy:%s] Map cell_size: %.3f, cell_height: %.3f" % [name, map_cell_size, map_cell_height])
		
		# Get the closest point on the navmesh to our position
		var closest_point: Vector3 = NavigationServer3D.map_get_closest_point(nav_map, global_position)
		print("[BaseEnemy:%s] Our position: %s" % [name, global_position])
		print("[BaseEnemy:%s] Closest navmesh point: %s" % [name, closest_point])
		print("[BaseEnemy:%s] Distance to navmesh: %.3f" % [name, global_position.distance_to(closest_point)])
		
		# Check if (0,0,0) is returned - this indicates navmesh might be empty
		if closest_point == Vector3.ZERO:
			print("[BaseEnemy:%s] WARNING: Closest point is origin - navmesh may be empty or not baked!" % name)
			print("[BaseEnemy:%s] TIP: In Godot, select NavigationRegion3D and click 'Bake NavigationMesh', then SAVE the scene!" % name)
		
		# Check agent settings
		print("[BaseEnemy:%s] Agent path_height_offset: %.2f" % [name, nav_agent.path_height_offset])
		print("[BaseEnemy:%s] Agent navigation_layers: %d" % [name, nav_agent.navigation_layers])
	else:
		print("[BaseEnemy:%s] WARNING: Navigation map is INVALID!" % name)
	
	# Try to get a path to a nearby point
	var test_target: Vector3 = global_position + Vector3(2, 0, 2)
	nav_agent.target_position = test_target
	
	# Wait a physics frame for path to be calculated
	await get_tree().physics_frame
	
	print("[BaseEnemy:%s] Test path from %s to %s" % [name, global_position, test_target])
	print("[BaseEnemy:%s] is_target_reachable: %s" % [name, nav_agent.is_target_reachable()])
	print("[BaseEnemy:%s] is_navigation_finished: %s" % [name, nav_agent.is_navigation_finished()])
	print("[BaseEnemy:%s] distance_to_target: %.2f" % [name, nav_agent.distance_to_target()])
	
	if not nav_agent.is_navigation_finished():
		var next_pos: Vector3 = nav_agent.get_next_path_position()
		print("[BaseEnemy:%s] Next path position: %s" % [name, next_pos])
	else:
		print("[BaseEnemy:%s] Navigation says finished immediately - possible navmesh issue!" % name)
		print("[BaseEnemy:%s] TIP: Try re-baking navmesh with 'Cell Height' increased or check agent height" % name)


func _spawn_character_mesh() -> void:
	if enemy_data.character_scene:
		print("[BaseEnemy:%s] Spawning character mesh: %s" % [name, enemy_data.character_scene.resource_path])
		character_instance = enemy_data.character_scene.instantiate()
		add_child(character_instance)
		
		# Find the AnimationPlayer
		animator = _find_animation_player(character_instance)
		print("[BaseEnemy:%s] AnimationPlayer found: %s" % [name, animator != null])
		
		if animator:
			print("[BaseEnemy:%s] Available animations: %s" % [name, animator.get_animation_list()])
		
		if state_machine:
			_setup_state_machine()


func _find_animation_player(node: Node) -> AnimationPlayer:
	if node is AnimationPlayer:
		return node
	
	for child in node.get_children():
		var found := _find_animation_player(child)
		if found:
			return found
	
	return null


func _setup_state_machine() -> void:
	if not state_machine:
		return
	
	print("[BaseEnemy:%s] Setting up state machine references" % name)
	
	# Pass references to all states
	for child in state_machine.get_children():
		if child is AIState:
			child.character = self
			child.player = player
			child.spawn_point = spawn_point
			child.animator = animator
			child.nav_agent = nav_agent
			child.attack_area = attack_area
			child.enemy_data = enemy_data
			child.enemy_manager = enemy_manager
			print("[BaseEnemy:%s] Configured state: %s" % [name, child.state_name])


func set_player(p: CharacterBody3D) -> void:
	player = p
	print("[BaseEnemy:%s] Player set to: %s" % [name, p.name if p else "NULL"])
	_update_states_player()


func set_enemy_manager(manager: Node) -> void:
	enemy_manager = manager
	_update_states_enemy_manager()


func _update_states_player() -> void:
	if state_machine:
		for child in state_machine.get_children():
			if child is AIState:
				child.player = player


func _update_states_enemy_manager() -> void:
	if state_machine:
		for child in state_machine.get_children():
			if child is AIState:
				child.enemy_manager = enemy_manager


func receive_attack() -> void:
	print("[BaseEnemy:%s] Received attack!" % name)
	if state_machine and state_machine.has_method("switch_to"):
		state_machine.switch_to("receive_attack")


func command_state(state_name: String) -> void:
	print("[BaseEnemy:%s] Command to switch to state: %s" % [name, state_name])
	if state_machine and state_machine.has_method("switch_to"):
		state_machine.switch_to(state_name)


func get_current_state_name() -> String:
	if state_machine and state_machine.has_method("get_current_state_name"):
		return state_machine.get_current_state_name()
	return ""
