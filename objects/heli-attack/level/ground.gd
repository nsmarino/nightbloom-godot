extends Node3D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Events.phase_changed.connect(_on_phase_changed)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass

func _on_phase_changed(phase) -> void:
	pass
	#match phase:
		#Events.Phase.WALK_CYCLE:
			#_begin_walk_cycle()

func _begin_walk_cycle() -> void:
	pass
