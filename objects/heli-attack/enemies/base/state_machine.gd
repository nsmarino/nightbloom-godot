extends Node
@export var character : CharacterBody3D
#@export var animation_player : AnimationPlayer
@export var resources : EnemyResources
@export var default_move: String = "idle"

var moves : Dictionary # { String : AIMove }
var current_move : AIMove

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	collect_states()
	current_move = moves[default_move]
	switch_to(default_move)

func _physics_process(delta):
	var verdict = current_move.check_transition(delta)
	if verdict[0]:
		switch_to(verdict[1])
	current_move.update(delta)

func switch_to(next_state_name : String):
	current_move.on_exit()
	current_move = moves[next_state_name]
	current_move.mark_enter_state()
	current_move.on_enter()
	#animation_player.play(current_move.animation)

func collect_states():
	for child in get_children():
		if child is AIMove:
			moves[child.move_name] = child
			#child.animator = animation_player
			child.character = character
			child.player = character.player
			child.spawn_point = character.spawn_point
			child.resources = resources
