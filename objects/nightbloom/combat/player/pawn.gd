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

# Stagger tracking for each party member (keyed by index)
var party_member_stagger: Dictionary = {}  # int -> StaggerComponent


func _ready() -> void:
	print("Init pawn in arena")
	
	# Create stagger components for each party member
	_setup_party_stagger()
	
	# Spawn the initial party member's character mesh
	if PartyMembers.size() > 0:
		_spawn_character_mesh(PartyMembers[active_member_index])
	
	# Set up state machine references
	if state_machine:
		state_machine.set_animator(animator)
		state_machine.set_hit_area(hit_area)


func _setup_party_stagger() -> void:
	for i in range(PartyMembers.size()):
		var stagger := StaggerComponent.new()
		stagger.name = "StaggerComponent_%d" % i
		add_child(stagger)
		party_member_stagger[i] = stagger
		
		# Connect signals for this party member's stagger
		var member_index: int = i
		stagger.stagger_changed.connect(func(current: float, max_val: float):
			_on_member_stagger_changed(member_index, current, max_val)
		)
		stagger.staggered_state_changed.connect(func(is_staggered: bool):
			_on_member_staggered_state_changed(member_index, is_staggered)
		)


func _on_member_stagger_changed(member_index: int, current: float, max_val: float) -> void:
	Events.player_stagger_changed.emit(member_index, current, max_val)


func _on_member_staggered_state_changed(member_index: int, is_staggered: bool) -> void:
	if is_staggered:
		Events.individual_staggered.emit(self, true)
		print("[CombatPawn] Party member %d is now STAGGERED!" % member_index)


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
	
	# Emit signal for HUD update
	Events.active_party_member_changed.emit(active_member_index)
	
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


# Stagger system methods
func get_active_stagger_component() -> StaggerComponent:
	return party_member_stagger.get(active_member_index, null)


func apply_stagger_damage_to_active(amount: float) -> void:
	var stagger := get_active_stagger_component()
	if stagger:
		stagger.apply_stagger_damage(amount)


func is_active_member_staggered() -> bool:
	var stagger := get_active_stagger_component()
	if stagger:
		return stagger.is_staggered
	return false


func is_member_staggered(index: int) -> bool:
	var stagger: StaggerComponent = party_member_stagger.get(index, null)
	if stagger:
		return stagger.is_staggered
	return false


func set_active_off_balance(off_balance: bool) -> void:
	var stagger := get_active_stagger_component()
	if stagger:
		stagger.set_off_balance(off_balance)
	Events.player_off_balance_changed.emit(off_balance)


func is_active_off_balance() -> bool:
	var stagger := get_active_stagger_component()
	if stagger:
		return stagger.is_off_balance
	return false


func get_stagger_for_member(index: int) -> StaggerComponent:
	return party_member_stagger.get(index, null)


func are_all_members_staggered() -> bool:
	for i in range(PartyMembers.size()):
		var stagger: StaggerComponent = party_member_stagger.get(i, null)
		if stagger and not stagger.is_staggered:
			return false
	return PartyMembers.size() > 0
