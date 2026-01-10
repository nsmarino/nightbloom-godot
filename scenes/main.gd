extends Node3D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Events.player_killed.connect(_on_player_killed)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _unhandled_input(event: InputEvent) -> void:
	pass
	
func _on_player_killed()->void:
	get_tree().quit()
	
