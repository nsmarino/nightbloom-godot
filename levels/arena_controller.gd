extends Node3D
## Arena controller - wires up combat system components

@onready var combat_manager: Node = $CombatManager
@onready var pawn: CharacterBody3D = $Pawn
@onready var combat_hud: CanvasLayer = $HUD/CombatHud
@onready var enemy_group: Node = $EnemyGroup


func _ready() -> void:
	print("Arena controller initializing...")
	
	# Wait for all nodes to be ready
	await get_tree().process_frame
	
	# Wire up references
	_setup_connections()
	
	print("Arena controller ready - combat can begin")


func _setup_connections() -> void:
	# Give CombatManager references to resource nodes
	if combat_manager:
		combat_manager.player_resources = pawn.group_resources
		combat_manager.enemy_resources = enemy_group.group_resources
	
	# Give Pawn reference to enemy group
	if pawn:
		pawn.set_enemy_group(enemy_group)
	
	# Give HUD reference to player state machine
	if combat_hud and pawn:
		combat_hud.set_player_state_machine(pawn.state_machine)
	
	# Make sure enemy group has the pawn reference
	if enemy_group and pawn:
		enemy_group.Pawn = pawn
