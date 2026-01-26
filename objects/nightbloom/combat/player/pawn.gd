extends CharacterBody3D
class_name CombatPawn

@export var PartyMembers: Array[PartyMemberData]
@export var move_speed: float = 8.0

@onready var state_machine: Node = $StateMachine
@onready var group_resources: Node = $GroupResources
@onready var hit_area: Area3D = $HitArea

var active_member_index: int = 0
var character_instance: Node3D
var animator: AnimationPlayer
var enemy_group: Node


func _ready() -> void:
	print("Init pawn in arena")
	
	# Spawn the initial party member's character mesh
	if PartyMembers.size() > 0:
		_spawn_character_mesh(PartyMembers[active_member_index])
	
	# Set up state machine references
	if state_machine:
		state_machine.set_animator(animator)
		state_machine.set_hit_area(hit_area)


func _spawn_character_mesh(member_data: PartyMemberData) -> void:
	# Remove existing character if any
	if character_instance:
		character_instance.queue_free()
		character_instance = null
		animator = null
	
	if member_data.character_scene:
		character_instance = member_data.character_scene.instantiate()
		add_child(character_instance)
		
		# Find the AnimationPlayer in the instantiated scene
		animator = _find_animation_player(character_instance)
		
		if state_machine:
			state_machine.set_animator(animator)


func _find_animation_player(node: Node) -> AnimationPlayer:
	if node is AnimationPlayer:
		return node
	
	for child in node.get_children():
		var found := _find_animation_player(child)
		if found:
			return found
	
	return null


func switch_party_member(index: int) -> bool:
	if index < 0 or index >= PartyMembers.size():
		return false
	
	if index == active_member_index:
		return false
	
	# Spend AP for switch
	if not group_resources.spend_ap(GroupResources.SWITCH_COST):
		return false
	
	active_member_index = index
	_spawn_character_mesh(PartyMembers[active_member_index])
	
	return true


func switch_to_next_party_member() -> bool:
	var next_index: int = (active_member_index + 1) % PartyMembers.size()
	return switch_party_member(next_index)


func get_active_member() -> PartyMemberData:
	if active_member_index < PartyMembers.size():
		return PartyMembers[active_member_index]
	return null


func set_enemy_group(group: Node) -> void:
	enemy_group = group
	if state_machine:
		state_machine.set_enemy_group(group)


# Called by enemy attacks
func receive_attack(damage: int) -> void:
	if state_machine:
		state_machine.receive_attack(damage)
