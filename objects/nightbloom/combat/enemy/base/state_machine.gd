extends Node
class_name EnemyStateMachine

@export var character: CharacterBody3D
@export var default_state: String = "idle"

var states: Dictionary  # { String : AIState }
var current_state: AIState


func _ready() -> void:
	# Wait a frame for all nodes to be ready
	await get_tree().process_frame
	
	collect_states()
	
	if states.has(default_state):
		current_state = states[default_state]
		current_state.mark_enter_state()
		current_state.on_enter()


func _physics_process(delta: float) -> void:
	if current_state == null:
		return
	
	var verdict: Array = current_state.check_transition(delta)
	if verdict[0]:
		switch_to(verdict[1])
	
	current_state.update(delta)


func switch_to(next_state_name: String) -> void:
	if not states.has(next_state_name):
		push_warning("EnemyStateMachine: State '%s' not found" % next_state_name)
		return
	
	if current_state:
		current_state.on_exit()
	
	current_state = states[next_state_name]
	current_state.mark_enter_state()
	current_state.on_enter()


func collect_states() -> void:
	for child in get_children():
		if child is AIState:
			states[child.state_name] = child


func get_current_state_name() -> String:
	if current_state:
		return current_state.state_name
	return ""
