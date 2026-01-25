extends Node

enum Phase {
	START,
	PLAY,
	END,
}

signal helicopter_destroyed(loc: Vector3)
signal player_killed

signal phase_changed(phase: Phase)

func _ready()->void:
	print("Init autoload events")
