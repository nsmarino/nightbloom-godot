extends Node
class_name GroupResources

# AP cost constants
const SPELL_COST: int = 30
const ITEM_COST: int = 15
const SWITCH_COST: int = 15
const GUARD_COST: int = 15
const AP_GAIN_ON_HIT: int = 30

# Damage multiplier when all party members are staggered
const ALL_STAGGERED_MULTIPLIER: float = 2.0

@export var max_hp: int = 100
@export var hp: int = 100
@export var max_mp: int = 20
@export var mp: int = 20
@export var max_ap: int = 90
@export var ap: int = 0

# Guard state
var is_guarding: bool = false
var vulnerable_multiplier: float = 1.5
var guard_damage_reduction: float = 0.5

# Reference to pawn for stagger check
var pawn: Node


func _ready() -> void:
	# Emit initial values
	Events.player_hp_changed.emit(hp, max_hp)
	Events.player_mp_changed.emit(mp, max_mp)
	Events.player_ap_changed.emit(ap, max_ap)
	
	# Get reference to parent pawn
	await get_tree().process_frame
	pawn = get_parent()


func take_damage(amount: int) -> void:
	var actual_damage: int = amount
	
	if is_guarding:
		actual_damage = int(float(amount) * guard_damage_reduction)
	
	# Apply bonus damage if all party members are staggered
	if pawn and pawn.has_method("are_all_members_staggered"):
		if pawn.are_all_members_staggered():
			actual_damage = int(float(actual_damage) * ALL_STAGGERED_MULTIPLIER)
			print("[GroupResources] ALL PARTY STAGGERED! Damage %d -> %d" % [amount, actual_damage])
	
	hp = max(0, hp - actual_damage)
	Events.player_damaged.emit(actual_damage)
	Events.player_hp_changed.emit(hp, max_hp)


func take_damage_vulnerable(amount: int) -> void:
	var actual_damage: int = int(float(amount) * vulnerable_multiplier)
	hp = max(0, hp - actual_damage)
	Events.player_damaged.emit(actual_damage)
	Events.player_hp_changed.emit(hp, max_hp)


func heal(amount: int) -> void:
	hp = min(max_hp, hp + amount)
	Events.player_hp_changed.emit(hp, max_hp)


func gain_ap(amount: int) -> void:
	ap = min(max_ap, ap + amount)
	Events.player_ap_changed.emit(ap, max_ap)


func spend_ap(amount: int) -> bool:
	if ap >= amount:
		ap -= amount
		Events.player_ap_changed.emit(ap, max_ap)
		return true
	return false


func can_afford_ap(amount: int) -> bool:
	return ap >= amount


func spend_mp(amount: int) -> bool:
	if mp >= amount:
		mp -= amount
		Events.player_mp_changed.emit(mp, max_mp)
		return true
	return false


func can_afford_mp(amount: int) -> bool:
	return mp >= amount


func restore_mp(amount: int) -> void:
	mp = min(max_mp, mp + amount)
	Events.player_mp_changed.emit(mp, max_mp)


func set_guarding(guarding: bool) -> void:
	is_guarding = guarding


func is_defeated() -> bool:
	return hp <= 0


func reset_for_combat() -> void:
	hp = max_hp
	mp = max_mp
	ap = 0
	is_guarding = false
	Events.player_hp_changed.emit(hp, max_hp)
	Events.player_mp_changed.emit(mp, max_mp)
	Events.player_ap_changed.emit(ap, max_ap)
