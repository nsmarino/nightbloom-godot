extends Node
@export var character : CharacterBody3D
#@export var animation_player : AnimationPlayer
@export var resources : EnemyResources
@export var default_state: String = "idle"

var states : Dictionary # { String : AIMove }
var current_state : AIState

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	collect_states()
	current_state = states[default_state]
	switch_to(default_state)

func _physics_process(delta: float) -> void:
	var verdict = current_state.check_transition(delta)
	if verdict[0]:
		switch_to(verdict[1])
	current_state.update(delta)

func switch_to(next_state_name : String):
	current_state.on_exit()
	current_state = states[next_state_name]
	current_state.mark_enter_state()
	current_state.on_enter()
	#animation_player.play(current_move.animation)

func collect_states() -> void:
	for child in get_children():
		if child is AIState:
			states[child.state_name] = child
			#child.animator = animation_player
			child.character = character
			child.player = character.player
			child.spawn_point = character.spawn_point
			child.resources = resources
