extends CharacterBody3D

@export var weapon_scene: PackedScene = null
@onready var PickupTrigger: Area3D = $PickupTrigger

@export var DROP_SPEED: float = 1.0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	PickupTrigger.body_entered.connect(on_entered)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	velocity.y = -10
	move_and_slide()

func on_entered(body_entered) -> void:
	if (body_entered.has_method("pickup_weapon") and body_entered.is_in_group("player")):
		body_entered.pickup_weapon(weapon_scene)
		queue_free()
