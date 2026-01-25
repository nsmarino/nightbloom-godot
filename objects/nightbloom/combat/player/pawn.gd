extends CharacterBody3D

@export var PartyMembers: Array[PartyMemberData]
@onready var state_machine: Node = $StateMachine

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	print("Init pawn in arena")


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
