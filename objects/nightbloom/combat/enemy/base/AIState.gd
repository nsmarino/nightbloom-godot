extends Node
class_name AIState

@export var move_name : String
@export var animation : String

var player : CharacterBody3D
var character : CharacterBody3D
var animator : AnimationPlayer
var spawn_point : Vector3
var resources : EnemyResources

var enter_state_time : float

func check_transition(_delta: float) -> Array:
	return [true, "FAILING ON PURPOSE, you need to implement transition logic for " + move_name]


func update(delta):
	pass
 

func on_enter():
	pass


func on_exit():
	pass

# our little timestamps framework to work with timings inside our logic
func mark_enter_state():
	enter_state_time = Time.get_unix_time_from_system()

func get_progress() -> float:
	var now = Time.get_unix_time_from_system()
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
	var progress = get_progress()
	if progress >= start and progress <= finish:
		return true
	return false
