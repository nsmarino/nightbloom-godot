extends PlayerState

@export var use_duration: float = 0.8
@export var heal_amount: int = 30

var item_used: bool = false


func on_enter() -> void:
	super.on_enter()
	item_used = false
	
	# Spend AP
	group_resources.spend_ap(GroupResources.ITEM_COST)
	
	if animator:
		animator.play("Idle")  # Placeholder for item use animation
	
	# Stop movement
	pawn.velocity = Vector3.ZERO


func update(_delta: float) -> void:
	pawn.velocity = Vector3.ZERO
	pawn.move_and_slide()
	
	# Apply item effect at midpoint
	if duration_between(0.3, 0.4) and not item_used:
		_apply_item_effect()


func _apply_item_effect() -> void:
	item_used = true
	# Default item behavior: heal
	group_resources.heal(heal_amount)


func check_transition(_delta: float) -> Array:
	if duration_longer_than(use_duration):
		return [true, "locomotion"]
	
	return [false, ""]
