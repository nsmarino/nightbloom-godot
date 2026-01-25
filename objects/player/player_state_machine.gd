extends Node
@export var player : CharacterBody3D
#@export var animation_player : AnimationPlayer
@export var resources : PlayerResources

var moves : Dictionary # { String : AIMove }
var current_move : PlayerMove

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
	current_move.on_exit()
	current_move = moves[next_state_name]
	current_move.mark_enter_state()
	current_move.on_enter()
	#animation_player.play(current_move.animation)

func collect_states() -> void:
	for child in get_children():
		if child is PlayerMove:
			moves[child.move_name] = child
			#child.animator = animation_player
			child.player = player
			child.spawn_point = player.spawn_point
			child.resources = resources
