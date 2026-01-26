extends PlayerState

signal menu_action_selected(action: String)

var menu_open: bool = false


func on_enter() -> void:
	super.on_enter()
	menu_open = true
	
	# Pause combat
	Events.combat_paused.emit(true)
	
	# Stop movement
	pawn.velocity = Vector3.ZERO
	
	if animator:
		animator.play("Idle")


func on_exit() -> void:
	super.on_exit()
	menu_open = false
	
	# Resume combat
	Events.combat_paused.emit(false)


func update(_delta: float) -> void:
	# Keep player still
	pawn.velocity = Vector3.ZERO
	pawn.move_and_slide()


func check_transition(_delta: float) -> Array:
	# Cancel menu
	if Input.is_action_just_pressed("MenuCancel"):
		return [true, "locomotion"]
	
	return [false, ""]


# Called by HUD when player selects an action
func select_spell() -> bool:
	if group_resources.can_afford_ap(GroupResources.SPELL_COST):
		menu_action_selected.emit("spell")
		return true
	return false


func select_item() -> bool:
	if group_resources.can_afford_ap(GroupResources.ITEM_COST):
		menu_action_selected.emit("item")
		return true
	return false


func select_party_switch() -> bool:
	if group_resources.can_afford_ap(GroupResources.SWITCH_COST):
		menu_action_selected.emit("party_switch")
		return true
	return false
