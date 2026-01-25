extends Node
@export var pawn : CharacterBody3D
#@export var animation_player : AnimationPlayer
@export var group_resources : GroupResources
@export var default_move: String = "idle"

var states : Dictionary # { String : PlayerState }
var current_state : PlayerState

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass
	#collect_states()
	#current_move = moves["idle"]
	#switch_to("idle")

func _physics_process(_delta: float) -> void:
	pass
	#var verdict = current_move.check_transition(delta)
	#if verdict[0]:
		#switch_to(verdict[1])
	#current_move.update(delta)

func switch_to(next_state_name : String) -> void:
	current_state.on_exit()
	current_state = states[next_state_name]
	current_state.mark_enter_state()
	current_state.on_enter()
	#animation_player.play(current_move.animation)

func collect_states() -> void:
	for child in get_children():
		if child is PlayerState:
			states[child.state_name] = child
			#child.animator = animation_player
			child.pawn = pawn
			child.spawn_point = pawn.spawn_point
			child.group_resources = group_resources
