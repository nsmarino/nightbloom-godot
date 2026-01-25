extends Node
class_name PlayerState

@export var state_name : String

var pawn : CharacterBody3D
var character : CharacterBody3D
var animator : AnimationPlayer
var spawn_point : Vector3
var group_resources : GroupResources

var enter_state_time : float

func check_transition(_delta: float) -> Array:
	return [true, "FAILING ON PURPOSE, you need to implement transition logic for " + state_name]


func update(_delta: float) -> void:
	pass
 

func on_enter() -> void:
	pass


func on_exit() -> void:
	pass

# our little timestamps framework to work with timings inside our logic
func mark_enter_state() -> void:
	enter_state_time = Time.get_unix_time_from_system()

func get_progress() -> float:
	var now: float = Time.get_unix_time_from_system()
	return now - enter_state_time

func duration_longer_than(time : float) -> bool:
	if get_progress() >= time:
		return true
	return false

func duration_less_than(time : float) -> bool:
	if get_progress() < time: 
		return true
	return false

func duration_between(start : float, finish : float) -> bool:
	var progress: float = get_progress()
	if progress >= start and progress <= finish:
		return true
	return false
